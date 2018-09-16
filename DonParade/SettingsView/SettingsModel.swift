//
//  SettingsModel.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/16.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit

final class SettingsModel: NSObject, UITableViewDataSource, UITableViewDelegate {
    // カテゴリー
    private enum Category: String {
        case selectAccount = "SETTINGS_SELECT_ACCOUNT"
        case account = "SETTINGS_ACCOUNT"
        case mypage = "SETTINGS_MYPAGE"
        case view = "SETTINGS_VIEW"
        case other = "SETTINGS_OTHER"
    }
    private let categoryList: [Category] = [.selectAccount,
                                            .account,
                                            .mypage,
                                            .view,
                                            .other]
    
    // 1.アカウントの切り替え
    //   SettingsDataに登録してあるアカウントを表示する
    
    // 2.アカウントの追加と削除
    private enum Account: String {
        case add = "SETTINGS_ADD_ACCOUNT"
        case remove = "SETTINGS_REMOVE_ACCOUNT"
    }
    private let accountList: [Account] = [.add,
                                          .remove]
    
    // 3.マイページ
    private enum MyPage: String {
        case mypage = "SETTINGS_MYPAGE"
        case mute = "SETTINGS_MUTELIST"
        case block = "SETTINGS_BLOCKLIST"
    }
    private let myPageList: [MyPage] = [.mypage,
                                        .mute,
                                        .block]
    
    // 4.表示設定
    private enum View: String {
        case theme = "SETTINGS_THEME"
        case remove = "SETTINGS_REMOVE_ACCOUNT"
    }
    private let viewList: [View] = [.theme,
                                        .remove]
    
    // 5.その他
    private enum Other: String {
        case privacyPolicy = "SETTINGS_PRIVACY_POLICY"
        case license = "SETTINGS_LICENSE"
        case version = "SETTINGS_VERSION"
    }
    private let otherList: [Other] = [.privacyPolicy,
                                      .license,
                                      .version]
    
    // セクションの数
    func numberOfSections(in tableView: UITableView) -> Int {
        return categoryList.count
    }
    
    // セクションの名前
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return categoryList[section].rawValue
    }
    
    // セクション内のセルの数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return accountList.count
        case 2:
            return myPageList.count
        case 3:
            return viewList.count
        case 4:
            return otherList.count
        default:
            return 0
        }
    }
    
    // セルを返す
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "SettingsModel"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ?? UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: reuseIdentifier)
        
        var title = ""
        switch indexPath.section {
        case 0:
            title = "#### test"
        case 1:
            title = accountList[indexPath.row].rawValue
        case 2:
            title = myPageList[indexPath.row].rawValue
        case 3:
            title = viewList[indexPath.row].rawValue
        case 4:
            title = otherList[indexPath.row].rawValue
        default:
            break
        }
        
        cell.textLabel?.text = title
        
        return cell
    }
}
