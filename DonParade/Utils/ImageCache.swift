//
//  ImageCache.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/17.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// アイコンやカスタム絵文字データのキャッシュ（インメモリ、ストレージ）、なければネットワークから取得

import UIKit

final class ImageCache {
    private static var memCache: [String: UIImage] = [:]
    private static var waitingDict: [String: [(UIImage)->Void]] = [:]
    private static let fileManager = FileManager()
    private static let imageQueue = DispatchQueue(label: "ImageCache")
    
    // 画像をキャッシュから取得する。なければネットに取りに行く
    static func image(urlStr: String?, callback: @escaping (UIImage)->Void) {
        guard let urlStr = urlStr else { return }
        
        // メモリキャッシュにある場合
        if let image = memCache[urlStr] {
            callback(image)
            return
        }
        
        // ストレージキャッシュにある場合
        let cacheDir = NSHomeDirectory() + "/Library/Caches/"
        let filePath = cacheDir + urlStr.replacingOccurrences(of: "/", with: "|")
        if fileManager.fileExists(atPath: filePath) {
            imageQueue.async {
                let url = URL(fileURLWithPath: filePath)
                if let data = try? Data(contentsOf: url) {
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            memCache.updateValue(image, forKey: urlStr)
                            callback(image)
                        }
                    }
                }
            }
            return
        }
        
        // リクエスト済みの場合、コールバックリストに追加する
        if waitingDict.keys.contains(urlStr) {
            waitingDict[urlStr]?.append(callback)
            return
        }
        
        waitingDict[urlStr] = []
        
        // ネットワークに取りに行く
        imageQueue.async {
            guard let url = URL(string: urlStr) else { return }
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        memCache.updateValue(image, forKey: urlStr)
                        callback(image)
                        
                        for waitingCallback in waitingDict[urlStr] ?? [] {
                            waitingCallback(image)
                        }
                        
                        waitingDict.removeValue(forKey: urlStr)
                    }
                    
                    // ストレージにキャッシュする
                    let fileUrl = URL(fileURLWithPath: filePath)
                    try? data.write(to: fileUrl)
                }
            }
        }
    }
}
