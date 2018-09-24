//
//  EmojiData.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/17.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 各インスタンスの絵文字データを保持

import Foundation

final class EmojiData {
    private static var cacheData: [String: [EmojiStruct]] = [:]
    private static var waitingList: [String] = []
    
    static func getEmojiCache(host: String) -> [EmojiStruct] {
        // メモリキャッシュにある場合それを返す
        if let list = cacheData[host] {
            return list
        }
        
        if !waitingList.contains(host) {
            waitingList.append(host)
            // ネットに取りに行く
            guard let url = URL(string: "https://\(host)/api/v1/custom_emojis") else { return [] }
            try? MastodonRequest.get(url: url) { (data, response, error) in
                if let data = data {
                    do {
                        let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Array<AnyObject>
                        
                        if let responseJson = responseJson {
                            var list: [EmojiStruct] = []
                            
                            for json in responseJson {
                                let short_code = json["shortcode"] as? String
                                let static_url = json["static_url"] as? String
                                let url = json["url"] as? String
                                let visible_in_picker = json["visible_in_picker"] as? Int
                                
                                let data = EmojiStruct(short_code: short_code,
                                                       static_url: static_url,
                                                       url: url,
                                                       visible_in_picker: visible_in_picker)
                                list.append(data)
                            }
                            
                            cacheData.updateValue(list, forKey: host)
                        }
                    } catch {
                    }
                } else if let error = error {
                    print(error)
                }
            }
        }
        
        return []
    }
    
    struct EmojiStruct {
        let short_code: String?
        let static_url: String?
        let url: String?
        let visible_in_picker: Int?
    }
}
