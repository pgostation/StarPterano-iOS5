//
//  MovieCache.swift
//  DonParade
//
//  Created by takayoshi on 2018/10/06.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import AVFoundation

final class MovieCache {
    private static var waitingDict: [String: [(AVPlayer?, Any?, Any?)->Void]] = [:] // AVPlayer or AVPlayerLooper
    private static let fileManager = FileManager()
    private static let imageQueue = DispatchQueue(label: "MovieCache")
    
    static func movie(urlStr: String?, callback: @escaping (AVPlayer?, Any?, Any?)->Void) {
        guard let urlStr = urlStr else { return }
        
        // ストレージキャッシュにある場合
        let cacheDir = NSHomeDirectory() + "/Library/Caches"
        let filePath = cacheDir + "/" + urlStr.replacingOccurrences(of: "/", with: "|")
        if fileManager.fileExists(atPath: filePath) {
            imageQueue.async {
                let url = URL(fileURLWithPath: filePath)
                var player: AVPlayer? = nil
                var queuePlayer: Any? = nil
                var playerLooper: Any? = nil
                if #available(iOS 10.0, *) {
                    let playerItem = AVPlayerItem(url: url)
                    queuePlayer = AVQueuePlayer(items: [playerItem])
                    playerLooper = AVPlayerLooper(player: queuePlayer as! AVQueuePlayer, templateItem: playerItem)
                } else {
                    player = AVPlayer(url: url)
                }
                DispatchQueue.main.async {
                    callback(player, queuePlayer, playerLooper)
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
                var player: AVPlayer? = nil
                var queuePlayer: Any? = nil
                var playerLooper: Any? = nil
                if #available(iOS 10.0, *) {
                    let playerItem = AVPlayerItem(url: url)
                    queuePlayer = AVQueuePlayer(items: [playerItem])
                    playerLooper = AVPlayerLooper(player: queuePlayer as! AVQueuePlayer, templateItem: playerItem)
                } else {
                    player = AVPlayer(url: url)
                }
                DispatchQueue.main.async {
                    callback(player, queuePlayer, playerLooper)
                    
                    for waitingCallback in waitingDict[urlStr] ?? [] {
                        waitingCallback(player, queuePlayer, playerLooper)
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
