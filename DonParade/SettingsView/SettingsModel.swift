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
        case mypage = "SETTINGS_MASTODON"
        case application = "SETTINGS_APPLICATION"
        case cache = "SETTINGS_CACHE"
        case other = "SETTINGS_OTHER"
    }
    private let categoryList: [Category] = [.selectAccount,
                                            .account,
                                            .mypage,
                                            .application,
                                            .cache,
                                            .other]
    
    // 1.アカウントの切り替え
    //   SettingsDataに登録してあるアカウントを表示する
    
    // 2.アカウントの追加
    private enum Account: String {
        case add = "SETTINGS_ADD_ACCOUNT"
    }
    private let accountList: [Account] = [.add]
    
    // 3.マストドン設定
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
    
    // 4.アプリの設定
    private enum Application: String {
        case tootProtectDefault = "SETTINGS_TOOT_PROTECT_DEFAULT"
        case darkMode = "SETTINGS_DARKMODE" // ダークモード切り替え
        case fontSize = "SETTINGS_FONTSIZE"
    }
    private let applicationList: [Application] = [.tootProtectDefault,
                                                  .darkMode,
                                                  .fontSize]
    
    // 5.キャッシュ
    private enum Cache: String {
        case clearCache = "SETTINGS_CLEAR_CACHE"
        //case showIcons = "SETTINGS_SHOW_ICONS"
    }
    private let cacheList: [Cache] = [.clearCache]
    
    // 6.その他
    private enum Other: String {
        //case search = "SETTINGS_SEARCH" // 表示しているタイムラインから検索
        //case license = "SETTINGS_LICENSE"
        case version = "SETTINGS_VERSION"
    }
    private let otherList: [Other] = [.version]
    
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
            return accountList.count
        case 2:
            return myPageList.count
        case 3:
            return applicationList.count
        case 4:
            return cacheList.count
        case 5:
            return otherList.count
        default:
            return 0
        }
    }
    
    // セルを返す
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "SettingsModel"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ?? UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: reuseIdentifier)
        
        cell.accessoryType = .none
        
        var title = ""
        var subtitle: String? = nil
        switch indexPath.section {
        case 0:
            let data = SettingsData.accountList[indexPath.row]
            title = data.0.replacingOccurrences(of: "https://", with: "") + " " + (SettingsData.accountUsername(accessToken: data.1) ?? "")
            
            if SettingsData.hostName == data.0 && SettingsData.accessToken == data.1 {
                cell.accessoryType = .checkmark
            }
        case 1:
            title = I18n.get(accountList[indexPath.row].rawValue)
            cell.accessoryType = .disclosureIndicator
        case 2:
            title = I18n.get(myPageList[indexPath.row].rawValue)
            cell.accessoryType = .disclosureIndicator
        case 3:
            title = I18n.get(applicationList[indexPath.row].rawValue)
            switch applicationList[indexPath.row] {
            case .tootProtectDefault:
                cell.accessoryType = .disclosureIndicator
                
                switch SettingsData.protectMode {
                case .publicMode:
                    subtitle = I18n.get("PROTECTMODE_PUBLIC")
                case .unlisted:
                    subtitle = I18n.get("PROTECTMODE_UNLISTED")
                case .privateMode:
                    subtitle = I18n.get("PROTECTMODE_PRIVATE")
                case .direct:
                    subtitle = I18n.get("PROTECTMODE_DIRECT")
                }
            case .darkMode:
                let cell = SettingsSwitchCell(style: .default, isOn: SettingsData.isDarkMode)
                cell.textLabel?.text = title
                cell.callback = { isOn in
                    SettingsData.isDarkMode = isOn
                }
                return cell
            case .fontSize:
                let cell = SettingsStepperCell(style: .default,
                                               value: Double(SettingsData.fontSize),
                                               minValue: 12,
                                               maxValue: 24,
                                               step: 1)
                cell.textLabel?.text = title + " : " + "\(Int(SettingsData.fontSize))pt"
                cell.callback = { [weak cell] value in
                    SettingsData.fontSize = CGFloat(value)
                    cell?.textLabel?.text = title + " : " + "\(Int(SettingsData.fontSize))pt"
                }
                return cell
            }
        case 4:
            title = I18n.get(cacheList[indexPath.row].rawValue)
            cell.accessoryType = .disclosureIndicator
        case 5:
            title = I18n.get(otherList[indexPath.row].rawValue)
            switch otherList[indexPath.row] {
            case .version:
                let data = Bundle.main.infoDictionary
                let version = data?["CFBundleShortVersionString"] as? String
                subtitle = version
            }
        default:
            break
        }
        
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = subtitle
        
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
            }
        case 2:
            break
        case 3:
            switch applicationList[indexPath.row] {
            case .tootProtectDefault:
                SettingsSelectProtectMode.showActionSheet() { mode in
                    SettingsData.protectMode = mode
                    tableView.reloadData()
                }
            case .darkMode:
                break
            case .fontSize:
                break
            }
        case 4:
            break
        case 5:
            break
        default:
            break
        }
    }
    
    // セルが削除対応かどうかを決める
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if indexPath.section == 0 {
            return UITableViewCellEditingStyle.delete
        }
        
        return UITableViewCellEditingStyle.none
    }
    
    // スワイプでの削除
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if indexPath.section == 0 && indexPath.row < SettingsData.accountList.count {
                Dialog.show(message: I18n.get("DIALOG_REMOVE_ACCOUNT"),
                            okName: I18n.get("BUTTON_REMOVE"),
                            cancelName: I18n.get("BUTTON_CANCEL"))
                { result in
                    if result {
                        let oldData = SettingsData.accountList[indexPath.row]
                        
                        // 削除
                        SettingsData.accountList.remove(at: indexPath.row)
                        
                        // 選択中のアカウントを削除した場合、最初のアカウントに移動するか、ログアウト状態にする
                        if oldData.0 == SettingsData.hostName && oldData.0 == SettingsData.accessToken {
                            SettingsData.hostName = SettingsData.accountList.first?.0
                            SettingsData.accessToken = SettingsData.accountList.first?.1
                        }
                    }
                }
            }
        }
    }
}
