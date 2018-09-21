//
//  SettingsData.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/15.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 設定データの管理

import UIKit

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
            if let newValue = defaults.string(forKey: "accessToken") { //#### てきとう
                if let hostName = self.hostName {
                    for account in self.accountList {
                        if account.0 == hostName && account.1 == newValue {
                            return defaults.string(forKey: "accessToken")
                        }
                    }
                    
                    // 新規登録
                    var tmpAccountList = self.accountList
                    tmpAccountList.append((hostName, newValue))
                    self.accountList = tmpAccountList
                }
            }
            
            return defaults.string(forKey: "accessToken")
        }
        set(newValue) {
            defaults.set(newValue, forKey: "accessToken")
            
            if let newValue = newValue, let hostName = self.hostName {
                for account in self.accountList {
                    if account.0 == hostName && account.1 == newValue {
                        return // 登録済み
                    }
                }
                
                // 新規登録
                var tmpAccountList = self.accountList
                tmpAccountList.append((hostName, newValue))
                self.accountList = tmpAccountList
            }
        }
    }
    
    // 接続が確認されたアカウントの情報を保持
    static var accountList: [(String, String)] {
        get {
            var list: [(String, String)] = []
            let array = defaults.array(forKey: "accountList")
            
            for str in array as? [String] ?? [] {
                let items = str.split(separator: ",")
                if items.count < 2 { continue }
                list.append((String(items[0]), String(items[1])))
            }
            
            return list
        }
        set(newValue) {
            var array: [String] = []
            
            for data in newValue {
                array.append(data.0 + "," + data.1)
            }
            
            defaults.set(array, forKey: "accountList")
        }
    }
    
    // アカウントの名前を保持
    static func accountUsername(accessToken: String) -> String? {
        return defaults.string(forKey: "accountUsername_\(accessToken)")
    }
    static func setAccountUsername(accessToken: String, value: String) {
        defaults.set(value, forKey: "accountUsername_\(accessToken)")
    }
    
    // アカウントのアイコンのURL文字列を保持
    static func accountIconUrl(accessToken: String) -> String? {
        return defaults.string(forKey: "accountIconUrl_\(accessToken)")
    }
    static func setAccountIconUrl(accessToken: String, value: String) {
        defaults.set(value, forKey: "accountIconUrl_\(accessToken)")
    }
    
    // ログインがアプリ起動後初めてかどうか（ユーザ名を取得するかどうかを判定するために使う）
    static var loginedAccessTokenList: [String] = []
    
    // タップで詳細に移動
    static var tapDetailMode: Bool {
        get {
            if let string = defaults.string(forKey: "tapDetailMode") {
                return (string == "ON")
            }
            return false
        }
        set(newValue) {
            if newValue {
                defaults.set("ON", forKey: "tapDetailMode")
            } else {
                defaults.removeObject(forKey: "tapDetailMode")
            }
        }
    }
    
    // ミニビューかどうか
    private static var _isMiniView: Bool?
    static var isMiniView: Bool {
        get {
            if let cache = self._isMiniView {
                return cache
            }
            if let string = defaults.string(forKey: "isMiniView") {
                self._isMiniView = (string == "ON")
                return (string == "ON")
            }
            self._isMiniView = false
            return false
        }
        set(newValue) {
            self._isMiniView = newValue
            if newValue {
                defaults.set("ON", forKey: "isMiniView")
            } else {
                defaults.removeObject(forKey: "isMiniView")
            }
        }
    }
    
    // ダークモードかどうか
    static var isDarkMode: Bool {
        get {
            if let string = defaults.string(forKey: "isDarkMode") {
                return (string == "ON")
            }
            return false
        }
        set(newValue) {
            if newValue {
                defaults.set("ON", forKey: "isDarkMode")
            } else {
                defaults.removeObject(forKey: "isDarkMode")
            }
            
            ThemeColor.change()
        }
    }
    
    // 基準フォントサイズ
    private static var _fontSize: CGFloat?
    static var fontSize: CGFloat {
        get {
            if let cache = self._fontSize {
                return cache
            }
            let value = defaults.double(forKey: "fontSize")
            if value > 0 {
                return CGFloat(value)
            }
            return 16
        }
        set(newValue) {
            self._fontSize = newValue
            defaults.set(newValue, forKey: "fontSize")
        }
    }
    
    // デフォルトの保護モード
    enum ProtectMode: String {
        case publicMode = "public"
        case unlisted = "unlisted"
        case privateMode = "private"
        case direct = "direct"
    }
    static var protectMode: ProtectMode {
        get {
            if let value = ProtectMode(rawValue: defaults.string(forKey: "protectMode") ?? "") {
                return value
            }
            return ProtectMode.publicMode
        }
        set(newValue) {
            defaults.set(newValue.rawValue, forKey: "protectMode")
        }
    }
}
