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
        case color = "SETTINGS_COLOR"
        case mypage = "SETTINGS_MASTODON"
        case application = "SETTINGS_APPLICATION"
        case other = "SETTINGS_OTHER"
    }
    private let categoryList: [Category] = [.selectAccount,
                                            .account,
                                            .color,
                                            .mypage,
                                            .application,
                                            .other]
    
    // 1.アカウントの切り替え
    //   SettingsDataに登録してあるアカウントを表示する
    
    // 2.アカウントの追加
    private enum Account: String {
        case add = "SETTINGS_ADD_ACCOUNT"
    }
    private let accountList: [Account] = [.add]
    
    // 3.アカウント別設定
    private enum AccountSettings: String {
        case color = "SETTINGS_COLOR"
    }
    private let accountSettingsList: [AccountSettings] = [.color]
    
    // 4.マストドン設定
    private enum MyPage: String {
        case mastodonSite = "SETTINGS_MASTODON_SITE"
        case mypage = "SETTINGS_MYPAGE"
        case profile = "SETTINGS_PROFILE"
        case dm = "SETTINGS_DMLIST"
        case favorite = "SETTINGS_FAVORITELIST"
        case mute = "SETTINGS_MUTELIST"
        case block = "SETTINGS_BLOCKLIST"
        case followRequest = "SETTINGS_FOLLOWREQUESTLIST"
    }
    private let myPageList: [MyPage] = [.mastodonSite,
                                        .mypage,
                                        .profile,
                                        .dm,
                                        .favorite,
                                        .followRequest] // 最後のアイテムの表示はロックアカウントのみ
                                        //.mute,
                                        //.block]
    
    // 5.アプリの設定
    private enum Application: String {
        case tootProtectDefault = "SETTINGS_TOOT_PROTECT_DEFAULT"
        case darkMode = "SETTINGS_DARKMODE"
        case coloring = "SETTINGS_CELLCOLORING"
        case fontSize = "SETTINGS_FONTSIZE"
        case streaming = "SETTINGS_STREAMING"
        case mergeLocal = "SETTINGS_MERGELOCAL"
        case iconSize = "SETTINGS_ICONSIZE"
        case loadPreviewImage = "SETTINGS_LOADPREVIEW"
        case nameTappable = "SETTINGS_NAMETAPPABLE" // アカウント名をタップできるか
        case useAnimation = "SETTINGS_USEANIMATION"
        case useAbsoluteTime = "SETTINGS_ABSOLUTETIME"
        case showFTLButton = "SETTINGS_SHOWFTLBUTTON"
        case showListButton = "SETTINGS_SHOWLISTBUTTON"
        case hiragana = "SETTINGS_HIRAGANA"
        case showFavDialog = "SETTINGS_SHOWFAVDIALOG"
        case hashtagDialog = "SETTINGS_HASHTAG_DIALOG"
        case sounds = "SETTINGS_SOUNDS"
    }
    private let applicationList: [Application] = [.tootProtectDefault,
                                                  .darkMode,
                                                  .coloring,
                                                  .fontSize,
                                                  .iconSize,
                                                  .loadPreviewImage,
                                                  .nameTappable,
                                                  .streaming,
                                                  .mergeLocal,
                                                  .useAnimation,
                                                  .useAbsoluteTime,
                                                  .showListButton,
                                                  .showFTLButton,
                                                  .hiragana,
                                                  .showFavDialog,
                                                  .hashtagDialog,
                                                  .sounds]
    
    // 6.その他
    private enum Other: String {
        case license = "SETTINGS_LICENSE"
        case version = "SETTINGS_VERSION"
        case clearCache = "SETTINGS_CLEAR_CACHE"
        case pushNotify = "SETTINGS_PUSH_NOTIFICATIONS"
    }
    private let otherList: [Other] = [.license,
                                      .version,
                                      .clearCache,
                                      .pushNotify]
    
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
            return accountSettingsList.count
        case 3:
            if SettingsData.accountLocked(accessToken: SettingsData.accessToken ?? "") {
                return myPageList.count
            } else {
                return myPageList.count - 1
            }
        case 4:
            return applicationList.count
        case 5:
            return otherList.count
        default:
            return 0
        }
    }
    
    // セルを返す
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "SettingsModel"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ?? UITableViewCell(style: UITableViewCell.CellStyle.value1, reuseIdentifier: reuseIdentifier)
        
        cell.accessoryType = .none
        cell.backgroundColor = ThemeColor.viewBgColor
        cell.textLabel?.textColor = ThemeColor.idColor
        cell.detailTextLabel?.textColor = ThemeColor.idColor
        cell.imageView?.image = nil
        
        var title = ""
        var subtitle: String? = nil
        switch indexPath.section {
        case 0:
            let data = SettingsData.accountList[indexPath.row]
            title = (SettingsData.accountUsername(accessToken: data.1) ?? "") + " @ " + data.0.replacingOccurrences(of: "https://", with: "")
            
            if SettingsData.hostName == data.0 && SettingsData.accessToken == data.1 {
                cell.accessoryType = .checkmark
            }
            
            // アイコンを設定
            if let iconStr = SettingsData.accountIconUrl(accessToken: data.1) {
                cell.textLabel?.text = title
                ImageCache.image(urlStr: iconStr, isTemp: false, isSmall: true) { image in
                    if cell.textLabel?.text != title { return }
                    cell.imageView?.image = image
                    cell.imageView?.clipsToBounds = true
                    cell.imageView?.layer.cornerRadius = 8
                    cell.setNeedsLayout()
                }
            }
        case 1:
            title = I18n.get(accountList[indexPath.row].rawValue)
            cell.accessoryType = .disclosureIndicator
        case 2:
            title = I18n.get(accountSettingsList[indexPath.row].rawValue)
            cell.accessoryType = .disclosureIndicator
            title = I18n.get(accountSettingsList[indexPath.row].rawValue)
            switch accountSettingsList[indexPath.row] {
            case .color:
                if SettingsData.color == "blue" {
                    subtitle = I18n.get("COLOR_BLUE")
                } else if SettingsData.color == "orange" {
                    subtitle = I18n.get("COLOR_ORANGE")
                } else if SettingsData.color == "monochrome" {
                    subtitle = I18n.get("COLOR_MONOCHROME")
                } else {
                    subtitle = I18n.get("COLOR_GREEN")
                }
            }
        case 3:
            title = I18n.get(myPageList[indexPath.row].rawValue)
            cell.accessoryType = .disclosureIndicator
        case 4:
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
                cell.callback = { [weak tableView] isOn in
                    guard let tableView = tableView else { return }
                    SettingsData.isDarkMode = isOn
                    
                    // アニメーションで変更
                    tableView.reloadRows(at: tableView.indexPathsForVisibleRows ?? [], with: UITableView.RowAnimation.fade)
                    UIView.animate(withDuration: 0.2) {
                        tableView.backgroundColor = ThemeColor.cellBgColor
                    }
                    
                    MainViewController.instance?.refreshColor()
                }
                return cell
            case .coloring:
                let cell = SettingsSwitchCell(style: .default, isOn: SettingsData.useColoring)
                cell.textLabel?.text = title
                cell.callback = { isOn in
                    SettingsData.useColoring = isOn
                    MainViewController.instance?.refreshColor()
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if SettingsData.fontSize != CGFloat(value) { return }
                        MainViewController.instance?.refreshColor()
                    }
                }
                return cell
            case .streaming:
                let cell = SettingsSwitchCell(style: .default, isOn: SettingsData.isStreamingMode)
                cell.textLabel?.text = title
                cell.callback = { isOn in
                    SettingsData.isStreamingMode = isOn
                }
                return cell
            case .mergeLocal:
                let cell = SettingsSwitchCell(style: .default, isOn: SettingsData.mergeLocalTL)
                cell.textLabel?.text = title
                cell.callback = { isOn in
                    SettingsData.mergeLocalTL = isOn
                }
                return cell
            case .loadPreviewImage:
                let cell = SettingsSwitchCell(style: .default, isOn: SettingsData.isLoadPreviewImage)
                cell.textLabel?.text = title
                cell.callback = { isOn in
                    SettingsData.isLoadPreviewImage = isOn
                    MainViewController.instance?.refreshColor()
                }
                return cell
            case .nameTappable:
                let cell = SettingsSwitchCell(style: .default, isOn: SettingsData.isNameTappable)
                cell.textLabel?.text = title
                cell.callback = { isOn in
                    SettingsData.isNameTappable = isOn
                    MainViewController.instance?.refreshColor()
                }
                return cell
            case .iconSize:
                let cell = SettingsStepperCell(style: .default,
                                               value: Double(SettingsData.iconSize),
                                               minValue: 24,
                                               maxValue: 50,
                                               step: 2)
                cell.textLabel?.text = title + " : " + "\(Int(SettingsData.iconSize))pt"
                cell.callback = { [weak cell] value in
                    SettingsData.iconSize = CGFloat(value)
                    cell?.textLabel?.text = title + " : " + "\(Int(SettingsData.iconSize))pt"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if SettingsData.iconSize != CGFloat(value) { return }
                        MainViewController.instance?.refreshColor()
                    }
                }
                return cell
            case .useAnimation:
                let cell = SettingsSwitchCell(style: .default, isOn: SettingsData.useAnimation)
                cell.textLabel?.text = title
                cell.callback = { isOn in
                    SettingsData.useAnimation = isOn
                    MainViewController.instance?.refreshColor()
                }
                return cell
            case .useAbsoluteTime:
                let cell = SettingsSwitchCell(style: .default, isOn: SettingsData.useAbsoluteTime)
                cell.textLabel?.text = title
                cell.callback = { isOn in
                    SettingsData.useAbsoluteTime = isOn
                    MainViewController.instance?.refreshColor()
                }
                return cell
            case .showFTLButton:
                let cell = SettingsSwitchCell(style: .default, isOn: SettingsData.showFTLButton)
                cell.textLabel?.text = title
                cell.callback = { isOn in
                    SettingsData.showFTLButton = isOn
                    MainViewController.instance?.refreshColor()
                }
                return cell
            case .showListButton:
                let cell = SettingsSwitchCell(style: .default, isOn: SettingsData.showListButton)
                cell.textLabel?.text = title
                cell.callback = { isOn in
                    SettingsData.showListButton = isOn
                    MainViewController.instance?.refreshColor()
                }
                return cell
            case .hiragana:
                let cell = SettingsSwitchCell(style: .default, isOn: SettingsData.hiraganaMode)
                cell.textLabel?.text = title
                cell.callback = { isOn in
                    SettingsData.hiraganaMode = isOn
                }
                return cell
            case .showFavDialog:
                let cell = SettingsSwitchCell(style: .default, isOn: SettingsData.showFavDialog)
                cell.textLabel?.text = title
                cell.callback = { isOn in
                    SettingsData.showFavDialog = isOn
                }
                return cell
            case .hashtagDialog:
                let cell = SettingsSwitchCell(style: .default, isOn: SettingsData.hashtagDialog)
                cell.textLabel?.text = title
                cell.callback = { isOn in
                    SettingsData.hashtagDialog = isOn
                }
                return cell
            case .sounds:
                let cell = SettingsSwitchCell(style: .default, isOn: SettingsData.sounds)
                cell.textLabel?.text = title
                cell.callback = { isOn in
                    SettingsData.sounds = isOn
                }
                return cell
            }
        case 5:
            title = I18n.get(otherList[indexPath.row].rawValue)
            switch otherList[indexPath.row] {
            case .license:
                cell.accessoryType = .disclosureIndicator
            case .version:
                let data = Bundle.main.infoDictionary
                let version = data?["CFBundleShortVersionString"] as? String
                subtitle = version
            case .clearCache:
                cell.accessoryType = .disclosureIndicator
                
                let cacheDir = NSHomeDirectory() + "/Library/Caches"
                let cacheDirUrl = URL(fileURLWithPath: cacheDir)
                if let urls = try? FileManager.default.contentsOfDirectory(at: cacheDirUrl, includingPropertiesForKeys: nil, options: .skipsPackageDescendants) {
                    subtitle = "\(urls.count)"
                }
            case .pushNotify:
                cell.accessoryType = .disclosureIndicator
            }
        default:
            break
        }
        
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = subtitle
        
        return cell
    }
    
    // セルを選択
    private static var isLocked = false
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if SettingsModel.isLocked { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SettingsModel.isLocked = false
        }
        SettingsModel.isLocked = true
        
        switch indexPath.section {
        case 0:
            let data = SettingsData.accountList[indexPath.row]
            SettingsData.hostName = data.0
            SettingsData.accessToken = data.1
            tableView.reloadData()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                SettingsViewController.instance?.dismiss(animated: false, completion: nil)
                MainViewController.instance?.tlAction(nil)
                MainViewController.instance?.setAccountIcon()
                ThemeColor.change()
                MainViewController.instance?.refreshColor()
            }
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
                        loginViewController.modalPresentationStyle = .fullScreen
                        UIUtils.getFrontViewController()?.present(loginViewController, animated: false, completion: nil)
                    }
                }
            }
        case 2:
            switch accountSettingsList[indexPath.row] {
            case .color:
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
                
                // グリーン
                alertController.addAction(UIAlertAction(
                    title: I18n.get("COLOR_GREEN"),
                    style: UIAlertAction.Style.default) { _ in
                        SettingsData.color = nil
                        MainViewController.instance?.refreshColor()
                        tableView.reloadData()
                })
                
                // ブルー
                alertController.addAction(UIAlertAction(
                    title: I18n.get("COLOR_BLUE"),
                    style: UIAlertAction.Style.default) { _ in
                        SettingsData.color = "blue"
                        MainViewController.instance?.refreshColor()
                        tableView.reloadData()
                })
                
                // オレンジ
                alertController.addAction(UIAlertAction(
                    title: I18n.get("COLOR_ORANGE"),
                    style: UIAlertAction.Style.default) { _ in
                        SettingsData.color = "orange"
                        MainViewController.instance?.refreshColor()
                        tableView.reloadData()
                })
                
                // モノクローム
                alertController.addAction(UIAlertAction(
                    title: I18n.get("COLOR_MONOCHROME"),
                    style: UIAlertAction.Style.default) { _ in
                        SettingsData.color = "monochrome"
                        MainViewController.instance?.refreshColor()
                        tableView.reloadData()
                })
                
                // キャンセル
                alertController.addAction(UIAlertAction(
                    title: I18n.get("BUTTON_CANCEL"),
                    style: UIAlertAction.Style.cancel) { _ in
                })
                
                UIUtils.getFrontViewController()?.present(alertController, animated: true, completion: nil)
            }
        case 3:
            switch myPageList[indexPath.row] {
            case .mastodonSite:
                guard let url = URL(string: "https://\(SettingsData.hostName ?? "")") else { return }
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            case .mypage:
                ShowMyAnyList.showMyPage(rootVc: SettingsViewController.instance!)
            case .profile:
                ShowMyAnyList.editProfile(rootVc: SettingsViewController.instance!)
            case .dm:
                ShowMyAnyList.showDMList(rootVc: SettingsViewController.instance!)
            case .favorite:
                ShowMyAnyList.showFavoriteList(rootVc: SettingsViewController.instance!)
            case .block:
                ShowMyAnyList.showBlockList(rootVc: SettingsViewController.instance!)
            case .mute:
                ShowMyAnyList.showMuteList(rootVc: SettingsViewController.instance!)
            case .followRequest:
                ShowMyAnyList.showFollowRequestList(rootVc: SettingsViewController.instance!)
            }
        case 4:
            switch applicationList[indexPath.row] {
            case .tootProtectDefault:
                SettingsSelectProtectMode.showActionSheet() { mode in
                    SettingsData.protectMode = mode
                    tableView.reloadData()
                }
            default:
                break
            }
        case 5:
            switch otherList[indexPath.row] {
            case .license:
                guard let path = Bundle.main.path(forResource: "License", ofType: "text") else { return }
                guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return }
                guard let licenseStr = String(data: data, encoding: String.Encoding.utf8) else { return }
                Dialog.show(message: licenseStr)
            case .version:
                break
            case .clearCache:
                let cacheDir = NSHomeDirectory() + "/Library/Caches"
                let cacheDirUrl = URL(fileURLWithPath: cacheDir)
                let urls = try? FileManager.default.contentsOfDirectory(at: cacheDirUrl, includingPropertiesForKeys: nil, options: .skipsPackageDescendants)
                var fileCount = 0
                var totalSize = 0
                for url in urls ?? [] {
                    let attr = try? FileManager.default.attributesOfItem(atPath: url.path)
                    if let size = attr?[.size] {
                        totalSize += Int(truncating: (size as? NSNumber)!)
                        fileCount += 1
                    }
                }
                let str = String(format: I18n.get("ALERT_%D_COUNT_%D_SIZE"), fileCount, Double(totalSize) / 1000000)
                Dialog.show(message: str,
                            okName: I18n.get("BUTTON_CLEAR_CACHE"),
                            cancelName: I18n.get("BUTTON_CANCEL"),
                            callback: { result in
                                if !result { return }
                                
                                for url in urls ?? [] {
                                    try? FileManager.default.removeItem(at: url)
                                }
                                tableView.reloadData()
                })
            case .pushNotify:
                Dialog.show(message: I18n.get("DIALOG_PUSH_NOTIFY"))
                
                // デバイストークンを取得してDMで送る
                getAndSendDeviceToken()
            }
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // セルが削除対応かどうかを決める
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.section == 0 {
            return UITableViewCell.EditingStyle.delete
        }
        
        return UITableViewCell.EditingStyle.none
    }
    
    // スワイプでの削除
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
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
                        
                        tableView.reloadData()
                    }
                }
            }
        }
    }
    
    // デバイストークンを取得し、DMで送る
    private func getAndSendDeviceToken() {
        PushNotificationSettings.auth()
    }
}
