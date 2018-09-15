//
//  SettingsData.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/15.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import Foundation

final class SettingsData {
    private static let defaults = UserDefaults(suiteName: "Settings")!
    
    static var oauthCode: String? {
        get {
            return defaults.string(forKey: "oauthCode")
        }
        set(newValue) {
            defaults.set(newValue, forKey: "oauthCode")
        }
    }
}
