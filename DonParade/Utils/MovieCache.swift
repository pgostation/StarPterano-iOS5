//
//  MovieCache.swift
//  DonParade
//
//  Created by takayoshi on 2018/10/06.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import AVFoundation

final class MovieCache {
    private static var waitingDict: [String: [(AVPlayer)->Void]] = [:]
    private static let fileManager = FileManager()
    private static let imageQueue = DispatchQueue(label: "MovieCache")
    
    static func movie(urlStr: String?, callback: @escaping (AVPlayer)->Void) {
        guard let urlStr = urlStr else { return }
        
        // ストレージキャッシュにある場合
        let cacheDir = NSHomeDirectory() + "/Library/Caches"
        let filePath = cacheDir + "/" + urlStr.replacingOccurrences(of: "/", with: "|")
        if fileManager.fileExists(atPath: filePath) {
            imageQueue.async {
                let url = URL(fileURLWithPath: filePath)
                let player = AVPlayer(url: url)
                DispatchQueue.main.async {
                    callback(player)
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
                let player = AVPlayer(url: url)
                DispatchQueue.main.async {
                    callback(player)
                    
                    for waitingCallback in waitingDict[urlStr] ?? [] {
                        waitingCallback(player)
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
