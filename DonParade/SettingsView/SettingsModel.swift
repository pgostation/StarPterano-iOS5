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
        case accountSettings = "SETTINGS_ACCOUNT_SETTINGS"
        case account = "SETTINGS_ACCOUNT"
        case mypage = "SETTINGS_MASTODON"
        case control = "SETTINGS_CONTROL"
        case cache = "SETTINGS_CACHE"
        case other = "SETTINGS_OTHER"
    }
    private let categoryList: [Category] = [.selectAccount,
                                            .accountSettings,
                                            .account,
                                            .mypage,
                                            .control,
                                            .cache,
                                            .other]
    
    // 1.アカウントの切り替え
    //   SettingsDataに登録してあるアカウントを表示する
    
    // 2.アカウントごとの設定
    private enum AccountSettings: String {
        case tootProtectDefault = "SETTINGS_TOOT_PROTECT_DEFAULT"
        case accountButtonView = "SETTINGS_ACCOUNT_BUTTON_VIEW"
    }
    private let accountSettingsList: [AccountSettings] = [.tootProtectDefault,
                                                          .accountButtonView]
    
    // 3.アカウントの追加と削除
    private enum Account: String {
        case add = "SETTINGS_ADD_ACCOUNT"
        case remove = "SETTINGS_REMOVE_ACCOUNT"
    }
    private let accountList: [Account] = [.add,
                                          .remove]
    
    // 4.マストドン設定
    private enum MyPage: String {
        case mypage = "SETTINGS_MYPAGE"
        case favorite = "SETTINGS_FAVORITELIST"
        case mute = "SETTINGS_MUTELIST"
        case block = "SETTINGS_BLOCKLIST"
    }
    private let myPageList: [MyPage] = [.mypage,
                                        .favorite,
                                        .mute,
                                        .block]
    
    // 5.操作表示設定
    private enum Control: String {
        case theme = "SETTINGS_THEME" // テーマ切り替え、さらに各色もカスタムできる
        // 背景色 / ユーザ名表示色 / ID表示色(同一インスタンス, 別インスタンス) / テキスト表示色 / 時刻表示色
        case fontSize = "SETTINGS_FONTSIZE"
        //case wallPaper = "SETTINGS_WALLPAPER"// 壁紙設定
    }
    private let controlList: [Control] = [.theme,
                                          .fontSize]
    
    // 6.キャッシュ
    private enum Cache: String {
        case clearCache = "SETTINGS_CLEAR_CACHE"
        case showIcons = "SETTINGS_SHOW_ICONS"
    }
    private let cacheList: [Cache] = [.clearCache,
                                      .showIcons]
    
    // 7.その他
    private enum Other: String {
        case search = "SETTINGS_SEARCH" // 表示しているタイムラインから検索
        case privacyPolicy = "SETTINGS_PRIVACY_POLICY"
        case license = "SETTINGS_LICENSE"
        case version = "SETTINGS_VERSION"
    }
    private let otherList: [Other] = [.search,
                                      .privacyPolicy,
                                      .license,
                                      .version]
    
    // セクションの数
    func numberOfSections(in tableView: UITableView) -> Int {
        return categoryList.count
    }
    
    // セクションの名前
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return I18n.get(categoryList[section].rawValue)
    }
    
    // セクション内のセルの数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return SettingsData.accountList.count
        case 1:
            return accountSettingsList.count
        case 2:
            return accountList.count
        case 3:
            return myPageList.count
        case 4:
            return controlList.count
        case 5:
            return cacheList.count
        case 6:
            return otherList.count
        default:
            return 0
        }
    }
    
    // セルを返す
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "SettingsModel"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ?? UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: reuseIdentifier)
        
        cell.accessoryType = .none
        
        var title = ""
        switch indexPath.section {
        case 0:
            let data = SettingsData.accountList[indexPath.row]
            title = data.0.replacingOccurrences(of: "https://", with: "") + " " + (SettingsData.accountUsername(accessToken: data.1) ?? "")
            
            if SettingsData.hostName == data.0 && SettingsData.accessToken == data.1 {
                cell.accessoryType = .checkmark
            }
        case 1:
            title = I18n.get(accountSettingsList[indexPath.row].rawValue)
        case 2:
            title = I18n.get(accountList[indexPath.row].rawValue)
        case 3:
            title = I18n.get(myPageList[indexPath.row].rawValue)
        case 4:
            title = I18n.get(controlList[indexPath.row].rawValue)
        case 5:
            title = I18n.get(cacheList[indexPath.row].rawValue)
        case 6:
            title = I18n.get(otherList[indexPath.row].rawValue)
        default:
            break
        }
        
        cell.textLabel?.text = title
        
        return cell
    }
    
    // セルを選択
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            let data = SettingsData.accountList[indexPath.row]
            SettingsData.hostName = data.0
            SettingsData.accessToken = data.1
            tableView.reloadData()
        case 1:
            switch accountSettingsList[indexPath.row] {
            case .accountButtonView:
                break
            case .tootProtectDefault:
                break
            }
        case 2:
            switch accountList[indexPath.row] {
            case .add:
                SettingsViewController.instance?.dismiss(animated: false, completion: nil)
                MainViewController.instance?.dismiss(animated: false, completion: nil)
                
                // ログイン画面を表示
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let vc = UIUtils.getFrontViewController() as? LoginViewController {
                        (vc.view as? LoginView)?.reset()
                    } else {
                        let loginViewController = LoginViewController()
                        UIUtils.getFrontViewController()?.present(loginViewController, animated: false, completion: nil)
                    }
                }
            case .remove:
                break
            }
        case 3:
            break
        case 4:
            break
        case 5:
            break
        case 6:
            break
        default:
            break
        }
    }
}
