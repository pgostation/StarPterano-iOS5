//
//  ListData.swift
//  DonParade
//
//  Created by takayoshi on 2018/10/04.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// リストデータをキャッシュしておく

import Foundation

final class ListData {
    private static var cache: [String: [AnalyzeJson.ListData]] = [:]
    
    static func getCache(accessToken: String) -> [AnalyzeJson.ListData]? {
        return cache[accessToken]
    }
    
    static func setCache(accessToken: String, value: [AnalyzeJson.ListData]) {
        cache[accessToken] = value
    }
}
