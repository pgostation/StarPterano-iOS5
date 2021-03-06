//
//  ProfileAction.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/24.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit

final class ProfileAction {
    static weak var timelineView: TimeLineView? = nil
    
    private init() {}
    
    static func unfollow(id: String) {
        guard let hostName = SettingsData.hostName else { return }
        
        let url = URL(string: "https://\(hostName)/api/v1/accounts/\(id)/unfollow")!
        
        try? MastodonRequest.post(url: url, body: [:]) { (data, response, error) in
            if let data = data, data.count > 0 {
                refresh()
            } else {
            }
        }
    }
    
    static func follow(id: String) {
        guard let hostName = SettingsData.hostName else { return }
        
        let url = URL(string: "https://\(hostName)/api/v1/accounts/\(id)/follow")!
        
        try? MastodonRequest.post(url: url, body: [:]) { (data, response, error) in
            if let data = data, data.count > 0 {
                refresh()
            }
        }
    }
    
    static func unmute(id: String) {
        guard let hostName = SettingsData.hostName else { return }
        
        let url = URL(string: "https://\(hostName)/api/v1/accounts/\(id)/unmute")!
        
        try? MastodonRequest.post(url: url, body: [:]) { (data, response, error) in
            if let data = data, data.count > 0 {
                refresh()
            }
        }
    }
    
    static func mute(id: String) {
        guard let hostName = SettingsData.hostName else { return }
        
        let url = URL(string: "https://\(hostName)/api/v1/accounts/\(id)/mute")!
        
        try? MastodonRequest.post(url: url, body: [:]) { (data, response, error) in
            if let data = data, data.count > 0 {
                refresh()
            }
        }
    }
    
    // 通知もミュートする
    static func muteAlsoNotify(id: String) {
        guard let hostName = SettingsData.hostName else { return }
        
        let url = URL(string: "https://\(hostName)/api/v1/accounts/\(id)/mute")!
        
        try? MastodonRequest.post(url: url, body: [:]) { (data, response, error) in
            if let data = data, data.count > 0 {
                refresh()
            }
        }
    }
    
    static func unblock(id: String) {
        guard let hostName = SettingsData.hostName else { return }
        
        let url = URL(string: "https://\(hostName)/api/v1/accounts/\(id)/unblock")!
        
        try? MastodonRequest.post(url: url, body: [:]) { (data, response, error) in
            if let data = data, data.count > 0 {
                refresh()
            }
        }
    }
    
    static func block(id: String) {
        guard let hostName = SettingsData.hostName else { return }
        
        let url = URL(string: "https://\(hostName)/api/v1/accounts/\(id)/block")!
        
        try? MastodonRequest.post(url: url, body: [:]) { (data, response, error) in
            if let data = data, data.count > 0 {
                refresh()
            }
        }
    }
    
    static func hideBoost(id: String) {
        guard let hostName = SettingsData.hostName else { return }
        
        let url = URL(string: "https://\(hostName)/api/v1/accounts/\(id)/follow")!
        
        try? MastodonRequest.post(url: url, body: ["reblogs": 0]) { (data, response, error) in
            if let data = data, data.count > 0 {
                refresh()
            }
        }
    }
    
    static func showBoost(id: String) {
        guard let hostName = SettingsData.hostName else { return }
        
        let url = URL(string: "https://\(hostName)/api/v1/accounts/\(id)/follow")!
        
        try? MastodonRequest.post(url: url, body: ["reblogs": 1]) { (data, response, error) in
            if let data = data, data.count > 0 {
                refresh()
            }
        }
    }
    
    // プロフィールのセルを再読み込み
    private static func refresh() {
        DispatchQueue.main.async {
            if let view = self.timelineView {
                if view.type == .user {
                    view.reloadRows(at: [IndexPath.init(row: 0, section: 0)], with: UITableView.RowAnimation.none)
                }
            }
        }
    }
}
