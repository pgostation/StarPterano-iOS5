//
//  SettingsData.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/15.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 設定データの管理

import Foundation

final class SettingsData {
    private static let defaults = UserDefaults(suiteName: "Settings")!
    
    // 現在選択中のホストネーム
    static var hostName: String? {
        get {
            return defaults.string(forKey: "hostName")
        }
        set(newValue) {
            defaults.set(newValue, forKey: "hostName")
        }
    }
    
    // 現在選択中のアクセストークン
    static var accessToken: String? {
        get {
            return defaults.string(forKey: "accessToken")
        }
        set(newValue) {
            defaults.set(newValue, forKey: "accessToken")
        }
    }
    
    // 接続が確認されたアカウントの情報を保持
}
