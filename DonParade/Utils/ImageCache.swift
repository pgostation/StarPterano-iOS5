//
//  ImageCache.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/17.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// アイコンやカスタム絵文字データのキャッシュ（インメモリ、ストレージ）、なければネットワークから取得

import UIKit
import SwiftyGif
import APNGKit

final class ImageCache {
    private static var gifCache: [String: UIImage] = [:]
    private static var oldGifCache: [String: UIImage] = [:]
    private static var memCache: [String: UIImage] = [:]
    private static var oldMemCache: [String: UIImage] = [:]
    private static var waitingDict: [String: [(UIImage)->Void]] = [:]
    private static let fileManager = FileManager()
    private static let imageQueue = DispatchQueue(label: "ImageCache")
    private static let imageGlobalQueue = DispatchQueue.global()
    
    // 画像をキャッシュから取得する。なければネットに取りに行く
    static func image(urlStr: String?, isTemp: Bool, isSmall: Bool, shortcode: String? = nil, isPreview: Bool = false, callback: @escaping (UIImage)->Void) {
        guard let urlStr = urlStr else { return }
        
        // GIFキャッシュにある場合
        if let image = gifCache[urlStr] {
            if let imageCount = image.imageCount, imageCount > 0 {
                callback(image)
                return
            } else {
                gifCache.removeValue(forKey: urlStr)
            }
        }
        // 破棄候補のGIFキャッシュにある場合
        if let image = oldGifCache[urlStr] {
            if let imageCount = image.imageCount, imageCount > 0 {
                gifCache[urlStr] = image
                oldGifCache.removeValue(forKey: urlStr)
                callback(image)
                return
            } else {
                oldGifCache.removeValue(forKey: urlStr)
            }
        }
        
        // メモリキャッシュにある場合
        if let image = memCache[urlStr] {
            if image.size.width > 50 * UIScreen.main.scale || isSmall {
                callback(image)
                return
            }
        }
        // 破棄候補のメモリキャッシュにある場合
        if let image = oldMemCache[urlStr] {
            if image.size.width > 50 * UIScreen.main.scale || isSmall {
                memCache[urlStr] = image
                oldMemCache.removeValue(forKey: urlStr)
                callback(image)
                return
            }
        }
        
        // ストレージキャッシュにある場合
        let cacheDir: String
        if isTemp {
            cacheDir = NSHomeDirectory() + "/Library/Caches/preview"
            try? fileManager.createDirectory(atPath: cacheDir, withIntermediateDirectories: true, attributes: nil)
        } else {
            cacheDir = NSHomeDirectory() + "/Library/Caches"
        }
        let filePath = cacheDir + "/" + urlStr.replacingOccurrences(of: "/", with: "|")
        if fileManager.fileExists(atPath: filePath) {
            imageGlobalQueue.async {
                let url = URL(fileURLWithPath: filePath)
                if let data = try? Data(contentsOf: url) {
                    if url.absoluteString.hasSuffix(".gif") {
                        let image = EmojiImage(gifData: data, levelOfIntegrity: 0.5)
                        image.shortcode = shortcode
                        DispatchQueue.main.async {
                            gifCache.updateValue(image, forKey: urlStr)
                            callback(image)
                        }
                        
                        if gifCache.count >= 20 { // メモリの使いすぎを防ぐ
                            oldGifCache = gifCache
                            gifCache = [:]
                        }
                    } else if let image = EmojiImage(data: data) {
                        let smallImage = isSmall ? ImageUtils.small(image: image, size: 50) : image
                        smallImage.shortcode = shortcode
                        DispatchQueue.main.async {
                            memCache.updateValue(smallImage, forKey: urlStr)
                            callback(image)
                            
                            if memCache.count >= 70 { // メモリの使いすぎを防ぐ
                                oldMemCache = memCache
                                memCache = [:]
                            }
                        }
                    }
                }
            }
            return
        }
        
        if isPreview && !SettingsData.isLoadPreviewImage {
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
                if url.absoluteString.hasSuffix(".gif") {
                    let image = EmojiImage(gifData: data, levelOfIntegrity: 0.5)
                    image.shortcode = shortcode
                    DispatchQueue.main.async {
                        if !isTemp {
                            gifCache.updateValue(image, forKey: urlStr)
                        }
                        callback(image)
                        
                        for waitingCallback in waitingDict[urlStr] ?? [] {
                            waitingCallback(image)
                        }
                        
                        waitingDict.removeValue(forKey: urlStr)
                        
                        if gifCache.count >= 20 { // メモリの使いすぎを防ぐ
                            oldGifCache = gifCache
                            gifCache = [:]
                        }
                    }
                    
                    // ストレージにキャッシュする
                    let fileUrl = URL(fileURLWithPath: filePath)
                    try? data.write(to: fileUrl)
                } else if let image = EmojiImage(data: data) {
                    let smallImage = isSmall ? ImageUtils.small(image: image, size: 50) : image
                    smallImage.shortcode = shortcode
                    DispatchQueue.main.async {
                        if !isTemp {
                            memCache.updateValue(smallImage, forKey: urlStr)
                        }
                        callback(image)
                        
                        for waitingCallback in waitingDict[urlStr] ?? [] {
                            waitingCallback(image)
                        }
                        
                        waitingDict.removeValue(forKey: urlStr)
                        
                        if memCache.count >= 70 { // メモリの使いすぎを防ぐ
                            oldMemCache = memCache
                            memCache = [:]
                        }
                    }
                    
                    // ストレージにキャッシュする
                    let fileUrl = URL(fileURLWithPath: filePath)
                    try? data.write(to: fileUrl)
                    
                    // ストレージの古いファイルを削除する
                    let cacheDirUrl = URL(fileURLWithPath: cacheDir)
                    let urls = try? fileManager.contentsOfDirectory(at: cacheDirUrl, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
                    let nowDate = Date()
                    for url in urls ?? [] {
                        if let attr = try? fileManager.attributesOfItem(atPath: url.path) {
                            if let fileDate = attr[FileAttributeKey.creationDate] as? Date {
                                let time: Double = isTemp ? 3600 * 8 : 86400 * 30
                                if nowDate.timeIntervalSince(fileDate) > time {
                                    try? fileManager.removeItem(at: url)
                                }
                            }
                        }
                    }
                }
            } else {
                waitingDict.removeValue(forKey: urlStr)
            }
        }
    }
    
    static func clear() {
        oldMemCache = [:]
    }
}

final class APNGImageCache {
    private static var memCache: [String: APNGImage] = [:]
    private static var oldMemCache: [String: APNGImage] = [:]
    private static var waitingDict: [String: [(APNGImage)->Void]] = [:]
    private static let fileManager = FileManager()
    private static let imageQueue = DispatchQueue(label: "APNGImageCache")
    private static let imageGlobalQueue = DispatchQueue.global()
    
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
            imageGlobalQueue.async {
                let url = URL(fileURLWithPath: filePath)
                if let data = try? Data(contentsOf: url) {
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
