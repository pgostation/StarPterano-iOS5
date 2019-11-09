//
//  FilterData.swift
//  DonParade
//
//  Created by takayoshi on 2019/10/12.
//  Copyright © 2019 pgostation. All rights reserved.
//

// 各インスタンスのフィルターデータを保持

import Foundation

class FilterData {
    private static var cacheData: [String: [FilterStruct]] = [:] // host名: フィルターのリスト
    private static var waitingList: [String] = []
    
    static func getCache(host: String) -> [FilterStruct] {
        // メモリキャッシュにある場合それを返す
        if let list = cacheData[host] {
            return list
        }
        
        if !waitingList.contains(host) {
            waitingList.append(host)
            // ネットに取りに行く
            guard let url = URL(string: "https://\(host)/api/v1/filters") else { return [] }
            
            try? MastodonRequest.get(url: url) { (data, response, error) in
                if let data = data {
                    do {
                        let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Array<AnyObject>
                        
                        if let responseJson = responseJson {
                            var list: [FilterStruct] = []
                            
                            for json in responseJson {
                                let phrase = json["phrase"] as? String
                                let context = json["context"] as? [String]
                                let expires_at = json["expires_at"] as? String
                                let irreversible = json["irreversible"] as? Int
                                let whole_word = json["whole_word"] as? Int
                                
                                let data = FilterStruct(phrase: phrase,
                                                        context: context,
                                                        expires_at: expires_at,
                                                        irreversible: irreversible,
                                                        whole_word: whole_word)
                                list.append(data)
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
        
        return []
    }
}

struct FilterStruct {
    let phrase: String?
    let context: [String]?
    let expires_at: String?
    let irreversible: Int?
    let whole_word: Int?
}
