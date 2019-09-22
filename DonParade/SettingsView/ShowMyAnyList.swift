//
//  ShowMyAnyList.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/27.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit

final class ShowMyAnyList {
    // 自分のアカウントのプロフィールページを表示
    static func showMyPage(rootVc: UIViewController) {
        DispatchQueue.main.async {
            let id = SettingsData.accountNumberID(accessToken: SettingsData.accessToken ?? "") ?? ""
            let vc = TimeLineViewController(type: .user, option: id)
            
            // 情報を取得してから表示
            guard let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/accounts/\(id)") else { return }
            try? MastodonRequest.get(url: url) { (data, response, error) in
                if let data = data {
                    do {
                        if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                            let accountData = AnalyzeJson.analyzeAccountJson(account: responseJson)
                            (vc.view as? TimeLineView)?.accountList.updateValue(accountData, forKey: id)
                        }
                    } catch { }
                }
                DispatchQueue.main.async {
                    show(rootVc: rootVc, vc: vc)
                }
            }
        }
    }
    
    // プロフィール編集
    static func editProfile(rootVc: UIViewController) {
        // 情報を取得してから表示
        guard let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/accounts/\(SettingsData.accountNumberID(accessToken: SettingsData.accessToken ?? "") ?? "")") else { return }
        try? MastodonRequest.get(url: url) { (data, response, error) in
            if let data = data {
                do {
                    if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                        let accountData = AnalyzeJson.analyzeAccountJson(account: responseJson)
                        DispatchQueue.main.async {
                            let vc = ProfileEditViewController(accountData: accountData)
                            show(rootVc: rootVc, vc: vc)
                        }
                    }
                } catch { }
            }
        }
    }
    
    // お気に入り
    static func showFavoriteList(rootVc: UIViewController) {
        DispatchQueue.main.async {
            let vc = TimeLineViewController(type: .favorites)
            show(rootVc: rootVc, vc: vc)
        }
    }
    
    // 予約投稿の一覧
    static func showScheduledList(rootVc: UIViewController) {
        DispatchQueue.main.async {
            let vc = TimeLineViewController(type: .scheduled)
            show(rootVc: rootVc, vc: vc)
        }
    }
    
    // ブロック
    static func showBlockList(rootVc: UIViewController) {
        // ####
    }
    
    // ミュート
    static func showMuteList(rootVc: UIViewController) {
        // ####
    }
    
    // フォローリクエスト
    static func showFollowRequestList(rootVc: UIViewController) {
        DispatchQueue.main.async {
            let vc = FollowRequestViewController()
            show(rootVc: rootVc, vc: vc)
        }
    }
    
    // 設定画面のさらに上に表示する
    private static func show(rootVc: UIViewController, vc: UIViewController) {
        rootVc.addChild(vc)
        rootVc.view.addSubview(vc.view)
        vc.view.frame = CGRect(x: UIScreen.main.bounds.width,
                               y: 0,
                               width: UIScreen.main.bounds.width,
                               height: UIScreen.main.bounds.height)
        UIView.animate(withDuration: 0.3) {
            vc.view.frame.origin.x = 0
        }
    }
}
