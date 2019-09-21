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
    private static var cacheData: [String: [EmojiStruct]] = [:] // host名: データ
    private static var categoryData: [String: [String]] = [:] // host名: カテゴリ名のリスト
    private static var waitingList: [String] = []
    
    static func getEmojiCache(host: String, showHiddenEmoji: Bool) -> ([EmojiStruct], [String]?) {
        var list = getEmojiCacheAll(host: host)
        
        if showHiddenEmoji {
            return list
        }
        
        // 隠し絵文字を省く
        for (index, data) in list.0.enumerated().reversed() {
            if data.visible_in_picker != 1 {
                list.0.remove(at: index)
            }
        }
        
        return list
    }
    
    private static func getEmojiCacheAll(host: String) -> ([EmojiStruct], [String]?) {
        // メモリキャッシュにある場合それを返す
        if let list = cacheData[host] {
            let category = categoryData[host]
            return (list, category?.sorted())
        }
        
        if !waitingList.contains(host) {
            waitingList.append(host)
            // ネットに取りに行く
            guard let url = URL(string: "https://\(host)/api/v1/custom_emojis") else { return ([], nil) }
            try? MastodonRequest.get(url: url) { (data, response, error) in
                if let data = data {
                    do {
                        let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Array<AnyObject>
                        
                        if let responseJson = responseJson {
                            var list: [EmojiStruct] = []
                            
                            for json in responseJson {
                                let category = json["category"] as? String
                                let short_code = json["shortcode"] as? String
                                let static_url = json["static_url"] as? String
                                let url = json["url"] as? String
                                let visible_in_picker = json["visible_in_picker"] as? Int
                                
                                let data = EmojiStruct(category: category,
                                                       short_code: short_code,
                                                       static_url: static_url,
                                                       url: url,
                                                       visible_in_picker: visible_in_picker)
                                list.append(data)
                                
                                // カテゴリリストになければ追加
                                if let category = category {
                                    if self.categoryData[host] == nil {
                                        self.categoryData[host] = []
                                    }
                                    if categoryData[host]?.contains(category) == false {
                                        self.categoryData[host]?.append(category)
                                    }
                                }
                            }
                            
                            cacheData.updateValue(list, forKey: host)
                            
                            for (index, key) in self.waitingList.enumerated() {
                                if host == key {
                                    self.waitingList.remove(at: index)
                                }
                            }
                        }
                    } catch {
                    }
                } else if let error = error {
                    print(error)
                }
            }
        }
        
        return ([], nil)
    }
    
    struct EmojiStruct {
        let category: String?
        let short_code: String?
        let static_url: String?
        let url: String?
        let visible_in_picker: Int?
    }
}
