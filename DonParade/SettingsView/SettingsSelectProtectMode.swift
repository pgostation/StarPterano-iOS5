//
//  SettingsSelectProtectMode.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/21.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// トゥート画面又は設定画面から保護モードを切り替える画面を表示する
//   トゥート画面の場合一時的、設定画面からはデフォルト値を変更することになる

import UIKit

final class SettingsSelectProtectMode {
    static func showActionSheet(callback: @escaping ((SettingsData.ProtectMode)->Void)) {
        let alertController = UIAlertController(title: nil, message: I18n.get("TITLE_PROTECTMODE"), preferredStyle: UIAlertControllerStyle.actionSheet)
        
        // 公開
        alertController.addAction(UIAlertAction(
            title: I18n.get("PROTECTMODE_PUBLIC"),
            style: UIAlertActionStyle.default,
            handler: { _ in
                callback(SettingsData.ProtectMode.publicMode)
        }))
        
        // 未収載
        alertController.addAction(UIAlertAction(
            title: I18n.get("PROTECTMODE_UNLISTED"),
            style: UIAlertActionStyle.default,
            handler: { _ in
                callback(SettingsData.ProtectMode.unlisted)
        }))
        
        // フォロワー限定
        alertController.addAction(UIAlertAction(
            title: I18n.get("PROTECTMODE_PRIVATE"),
            style: UIAlertActionStyle.default,
            handler: { _ in
                callback(SettingsData.ProtectMode.privateMode)
        }))
        
        // ダイレクト
        alertController.addAction(UIAlertAction(
            title: I18n.get("PROTECTMODE_DIRECT"),
            style: UIAlertActionStyle.default,
            handler: { _ in
                callback(SettingsData.ProtectMode.direct)
        }))
        
        // キャンセル
        alertController.addAction(UIAlertAction(
            title: I18n.get("BUTTON_CANCEL"),
            style: UIAlertActionStyle.cancel,
            handler: { _ in
        }))
        
        UIUtils.getFrontViewController()?.present(alertController, animated: true, completion: nil)
    }
}
