//
//  APNGImageCache.swift
//  
//
//  Created by takayoshi on 2019/02/11.
//

import UIKit
import APNGKit
import BerryPlant

final class APNGImageCache {
    private static var memCache: [String: APNGImage] = [:]
    private static var oldMemCache: [String: APNGImage] = [:]
    private static var waitingDict: [String: [(APNGImage)->Void]] = [:]
    private static let fileManager = FileManager()
    private static let imageQueue = DispatchQueue(label: "APNGImageCache")
    private static let imageGlobalQueue = DispatchQueue.global()
    private static var notAnimeList: [String] = []
    
    static func image(urlStr: String?, callback: @escaping (APNGImage)->Void) {
        guard let urlStr = urlStr else { return }
        
        // メモリキャッシュにある場合
        if let image = memCache[urlStr] {
            callback(image)
            return
        }
        // 破棄候補のメモリキャッシュにある場合
        if let image = oldMemCache[urlStr] {
            memCache[urlStr] = image
            oldMemCache.removeValue(forKey: urlStr)
            callback(image)
            return
        }
        
        // ストレージキャッシュにある場合
        let cacheDir = NSHomeDirectory() + "/Library/Caches"
        let filePath = cacheDir + "/" + urlStr.replacingOccurrences(of: "/", with: "|")
        if fileManager.fileExists(atPath: filePath) {
            if notAnimeList.contains(filePath) {
                return
            }
            
            imageGlobalQueue.async {
                let url = URL(fileURLWithPath: filePath)
                if let data = try? Data(contentsOf: url) {
                    if urlStr.hasSuffix(".png") {
                        let format = BerryImageFormat.getImageFormat(data)
                        if format != .apng {
                            DispatchQueue.main.async {
                                notAnimeList.append(filePath)
                            }
                            return
                        }
                    }
                    
                    if let image = APNGImage(data: data) {
                        DispatchQueue.main.async {
                            memCache.updateValue(image, forKey: urlStr)
                            callback(image)
                            
                            if memCache.count >= 30 { // メモリの使いすぎを防ぐ
                                oldMemCache = memCache
                                memCache = [:]
                                APNGCache.defaultCache.clearMemoryCache()
                            }
                        }
                    }
                    
                    // 最終アクセス時刻を更新
                    try? fileManager.setAttributes([FileAttributeKey.modificationDate : Date()], ofItemAtPath: url.path)
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
                if urlStr.hasSuffix(".png") {
                    let format = BerryImageFormat.getImageFormat(data)
                    if format != .apng {
                        return
                    }
                }
                
                if let image = APNGImage(data: data) {
                    DispatchQueue.main.async {
                        memCache.updateValue(image, forKey: urlStr)
                        callback(image)
                        
                        for waitingCallback in waitingDict[urlStr] ?? [] {
                            waitingCallback(image)
                        }
                        
                        waitingDict.removeValue(forKey: urlStr)
                        
                        if memCache.count >= 30 { // メモリの使いすぎを防ぐ
                            oldMemCache = memCache
                            memCache = [:]
                            APNGCache.defaultCache.clearMemoryCache()
                        }
                    }
                    
                    // ストレージにキャッシュする
                    let fileUrl = URL(fileURLWithPath: filePath)
                    try? data.write(to: fileUrl)
                }
            }
        }
    }
    
    static func clear() {
        oldMemCache = [:]
    }
}

// APNGじゃないファイルを判定
final class NormalPNGFileList {
    private static let userDefault = UserDefaults(suiteName: "NormalPNGFileList")
    
    static func add(urlStr: String?) {
        guard let urlStr = urlStr else { return }
        if userDefault?.bool(forKey: urlStr) == true {
            return
        }
        
        if let dict = userDefault?.dictionaryRepresentation() {
            if dict.count > 1000 {
                for key in dict.keys {
                    userDefault?.removeObject(forKey: key)
                }
            }
        }
        
        userDefault?.set(true, forKey: urlStr)
    }
    
    static func isNormal(urlStr: String?) -> Bool {
        guard let urlStr = urlStr else { return true }
        return userDefault?.bool(forKey: urlStr) == true
    }
}
