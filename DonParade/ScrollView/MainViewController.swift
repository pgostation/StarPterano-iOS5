//
//  MainViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/15.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// TLやLTLなどへの切り替え機能を持った、メイン画面となるビューコントローラー

import UIKit

final class MainViewController: MyViewController {
    static weak var instance: MainViewController?
    var timelineList: [String: TimeLineViewController] = [:]
    
    override func loadView() {
        MainViewController.instance = self
        
        self.setNeedsStatusBarAppearanceUpdate()
        
        ThemeColor.change()
        
        // 共通部分のビュー
        let view = MainView()
        self.view = view
        
        // ボタンのaddTarget
        view.tlButton.addTarget(self, action: #selector(tlAction(_:)), for: .touchUpInside)
        view.ltlButton.addTarget(self, action: #selector(ltlAction(_:)), for: .touchUpInside)
        view.ftlButton.addTarget(self, action: #selector(ftlAction(_:)), for: .touchUpInside)
        view.listButton.addTarget(self, action: #selector(listAction(_:)), for: .touchUpInside)
        
        view.tootButton.addTarget(self, action: #selector(tootAction(_:)), for: .touchUpInside)
        
        view.searchButton.addTarget(self, action: #selector(searchAction(_:)), for: .touchUpInside)
        view.notificationsButton.addTarget(self, action: #selector(notificationsAction(_:)), for: .touchUpInside)
        
        view.accountButton.addTarget(self, action: #selector(accountAction(_:)), for: .touchUpInside)
        
        // 長押し
        let ltlPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(ftlAction(_:)))
        view.ltlButton.addGestureRecognizer(ltlPressGesture)
        
        let homePressGesture = UILongPressGestureRecognizer(target: self, action: #selector(listAction(_:)))
        view.tlButton.addGestureRecognizer(homePressGesture)
        
        let accountPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(accountPressAction(_:)))
        view.accountButton.addGestureRecognizer(accountPressGesture)
        
        // TLを表示する
        if let hostName = SettingsData.hostName, let accessToken = SettingsData.accessToken {
            switch SettingsData.tlMode(key: hostName + "," + accessToken) {
            case .home:
                tlAction(nil)
            case .local:
                ltlAction(nil)
            case .federation:
                ftlAction(nil)
            case .list:
                showListTL()
            }
        } else {
            tlAction(nil)
        }
    }
    
    func refreshColor() {
        guard let view = self.view as? MainView else { return }
        
        view.refreshColor()
        view.setNeedsLayout()
        
        self.setButtonNameAndBorder()
        
        if let tlView = self.timelineViewController?.view as? TimeLineView {
            tlView.reloadData()
            tlView.backgroundColor = ThemeColor.viewBgColor
        }
        
        for (_, vc) in timelineList {
            let timelineView = (vc.view as? TimeLineView)
            timelineView?.reloadData()
            timelineView?.backgroundColor = ThemeColor.viewBgColor
        }
    }
    
    private var timelineViewController: TimeLineViewController?
    
    // タイムラインへの切り替え
    @objc func tlAction(_ sender: UIButton?) {
        if let oldViewController = self.timelineViewController, sender != nil {
            if oldViewController.type == .home {
                // 一番上までスクロール
                (oldViewController.view as? UITableView)?.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableViewScrollPosition.top, animated: true)
                return
            }
        }
        
        // 前のビューを外す
        removeOldView()
        
        if let hostName = SettingsData.hostName, let accessToken = SettingsData.accessToken {
            let key = "\(hostName)_\(accessToken)_Home"
            if let vc = self.timelineList[key] {
                self.timelineViewController = vc
            } else {
                self.timelineViewController = TimeLineViewController(type: .home)
                self.timelineList.updateValue(self.timelineViewController!, forKey: key)
            }
            
            SettingsData.setTlMode(key: hostName + "," + accessToken, mode: .home)
        }
        
        // 一番下にタイムラインビューを入れる
        self.addChildViewController(self.timelineViewController!)
        self.view.insertSubview(self.timelineViewController!.view, at: 0)
        self.timelineViewController!.view.frame = UIUtils.fullScreen()
        
        self.setButtonNameAndBorder()
    }
    
    // LTLへの切り替え
    @objc func ltlAction(_ sender: UIButton?) {
        if let oldViewController = self.timelineViewController {
            if oldViewController.type == .local {
                // 一番上までスクロール
                (oldViewController.view as? UITableView)?.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableViewScrollPosition.top, animated: true)
                return
            }
        }
        
        // 前のビューを外す
        removeOldView()
        
        if let hostName = SettingsData.hostName, let accessToken = SettingsData.accessToken {
            let key = "\(hostName)_\(accessToken)_LTL"
            if let vc = self.timelineList[key] {
                self.timelineViewController = vc
            } else {
                self.timelineViewController = TimeLineViewController(type: .local)
                self.timelineList.updateValue(self.timelineViewController!, forKey: key)
            }
            
            SettingsData.setTlMode(key: hostName + "," + accessToken, mode: .local)
        }
        
        // 一番下にタイムラインビューを入れる
        self.addChildViewController(self.timelineViewController!)
        self.view.insertSubview(self.timelineViewController!.view, at: 0)
        self.timelineViewController!.view.frame = UIUtils.fullScreen()
        
        self.setButtonNameAndBorder()
    }
    
    // 連合ボタンをタップまたはローカルボタン長押しで連合タイムラインへ移動
    @objc func ftlAction(_ sender: Any?) {
        if let gesture = sender as? UILongPressGestureRecognizer {
            if gesture.state != .began { return }
            if SettingsData.showFTLButton { return }
        }
        
        if let oldViewController = self.timelineViewController {
            if oldViewController.type == .federation {
                // 一番上までスクロール
                (oldViewController.view as? UITableView)?.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableViewScrollPosition.top, animated: true)
                return
            }
        }
        
        // 前のビューを外す
        removeOldView()
        
        if let hostName = SettingsData.hostName, let accessToken = SettingsData.accessToken {
            let key = "\(hostName)_\(accessToken)_FTL"
            if let vc = self.timelineList[key] {
                self.timelineViewController = vc
            } else {
                self.timelineViewController = TimeLineViewController(type: .federation)
                self.timelineList.updateValue(self.timelineViewController!, forKey: key)
            }
            
            SettingsData.setTlMode(key: hostName + "," + accessToken, mode: .federation)
        }
        
        // 一番下にタイムラインビューを入れる
        self.addChildViewController(self.timelineViewController!)
        self.view.insertSubview(self.timelineViewController!.view, at: 0)
        self.timelineViewController!.view.frame = UIUtils.fullScreen()
        
        self.setButtonNameAndBorder()
    }
    
    // リストボタン
    @objc func listAction(_ sender: Any?) {
        if let gesture = sender as? UILongPressGestureRecognizer {
            if gesture.state != .began { return }
            if SettingsData.showListButton { return }
        }
        
        let vc = ListSelectViewController()
        self.present(vc, animated: false, completion: nil)
    }
    
    func showListTL() {
        // 選択しているリストがない場合、リスト選択画面に行く
        if SettingsData.selectedListId(accessToken: SettingsData.accessToken ?? "") == nil {
            listAction(nil)
            return
        }
        
        // 前のビューを外す
        removeOldView()
        
        if let hostName = SettingsData.hostName, let accessToken = SettingsData.accessToken {
            self.timelineViewController = TimeLineViewController(type: .list)
            SettingsData.setTlMode(key: hostName + "," + accessToken, mode: .list)
        }
        
        // 一番下にタイムラインビューを入れる
        self.addChildViewController(self.timelineViewController!)
        self.view.insertSubview(self.timelineViewController!.view, at: 0)
        self.timelineViewController!.view.frame = UIUtils.fullScreen()
        
        self.setButtonNameAndBorder()
    }
    
    private func setButtonNameAndBorder() {
        guard let view = self.view as? MainView else { return }
        
        DispatchQueue.main.async {
            if let tlView = self.timelineViewController?.view as? TimeLineView {
                view.tlButton.layer.borderWidth = 1 / UIScreen.main.scale
                view.ltlButton.layer.borderWidth = 1 / UIScreen.main.scale
                view.ftlButton.layer.borderWidth = 1 / UIScreen.main.scale
                view.listButton.layer.borderWidth = 1 / UIScreen.main.scale
                
                if !SettingsData.showFTLButton {
                    view.ftlButton.isHidden = true
                    view.setNeedsLayout()
                }
                if !SettingsData.showListButton {
                    view.listButton.isHidden = true
                    view.setNeedsLayout()
                }
                
                switch tlView.type {
                case .home:
                    view.tlButton.layer.borderWidth = 2
                case .local:
                    view.ltlButton.layer.borderWidth = 2
                case .federation:
                    if !SettingsData.showFTLButton {
                        view.ftlButton.isHidden = false
                        view.setNeedsLayout()
                    }
                    view.ftlButton.layer.borderWidth = 2
                case .list:
                    if !SettingsData.showListButton {
                        view.listButton.isHidden = false
                        view.setNeedsLayout()
                    }
                    view.listButton.layer.borderWidth = 2
                default:
                    break
                }
            }
        }
    }
    
    // 検索画面に移動
    @objc func searchAction(_ sender: UIButton?) {
        sender?.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            sender?.isUserInteractionEnabled = true
        }
        
        let vc = SearchViewController()
        self.addChildViewController(vc)
        self.view.addSubview(vc.view)
        
        vc.view.frame = CGRect(x: UIScreen.main.bounds.width,
                               y: 0,
                               width: UIScreen.main.bounds.width,
                               height: UIScreen.main.bounds.height)
        UIView.animate(withDuration: 0.3) {
            vc.view.frame.origin.x = 0
        }
    }
    
    // 通知画面に移動
    @objc func notificationsAction(_ sender: UIButton?) {
        sender?.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            sender?.isUserInteractionEnabled = true
        }
        
        let vc = NotificationViewController()
        self.addChildViewController(vc)
        self.view.addSubview(vc.view)
        
        vc.view.frame = CGRect(x: UIScreen.main.bounds.width,
                               y: 0,
                               width: UIScreen.main.bounds.width,
                               height: UIScreen.main.bounds.height)
        UIView.animate(withDuration: 0.3) {
            vc.view.frame.origin.x = 0
        }
        
        markNotificationButton(accessToken: SettingsData.accessToken ?? "", to: false)
    }
    
    // アカウントボタンの長押し
    @objc func accountPressAction(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state != .began { return }
        
        let title = (SettingsData.hostName ?? "") + " - " + (SettingsData.accountUsername(accessToken: SettingsData.accessToken ?? "") ?? "")
        let alertController = UIAlertController(title: title,
                                                message: nil,
                                                preferredStyle: UIAlertControllerStyle.actionSheet)
        
        // DMを表示
        alertController.addAction(UIAlertAction(
            title: I18n.get("SETTINGS_DMLIST"),
            style: UIAlertActionStyle.default,
            handler: { _ in
                ShowMyAnyList.showDMList(rootVc: self)
        }))
        
        // お気に入りを表示
        alertController.addAction(UIAlertAction(
            title: I18n.get("SETTINGS_FAVORITELIST"),
            style: UIAlertActionStyle.default,
            handler: { _ in
                ShowMyAnyList.showFavoriteList(rootVc: self)
        }))
        
        // 自分のページを表示
        alertController.addAction(UIAlertAction(
            title: I18n.get("SETTINGS_MYPAGE"),
            style: UIAlertActionStyle.default,
            handler: { _ in
                ShowMyAnyList.showMyPage(rootVc: self)
        }))
        
        if SettingsData.accountLocked(accessToken: SettingsData.accessToken ?? "") {
            // フォローリクエストを表示
            alertController.addAction(UIAlertAction(
                title: I18n.get("SETTINGS_FOLLOWREQUESTLIST"),
                style: UIAlertActionStyle.default,
                handler: { _ in
                    ShowMyAnyList.showFollowRequestList(rootVc: self)
            }))
        }
        
        // キャンセル
        alertController.addAction(UIAlertAction(
            title: I18n.get("BUTTON_CANCEL"),
            style: UIAlertActionStyle.cancel,
            handler: { _ in
        }))
        
        UIUtils.getFrontViewController()?.present(alertController, animated: true, completion: nil)
    }
    
    func swipeView(toRight: Bool) {
        if TootViewController.isShown { return } // トゥート画面表示中は移動しない
        
        let oldTimelineViewController = self.timelineViewController
        
        if let hostName = SettingsData.hostName, let accessToken = SettingsData.accessToken {
            let isLTL = SettingsData.tlMode(key: hostName + "," + accessToken)
            var key = "\(hostName)_\(accessToken)_" + (isLTL.rawValue)
            if isLTL == .list {
                key += SettingsData.selectedListId(accessToken: accessToken) ?? ""
            }
            if let vc = self.timelineList[key] {
                self.timelineViewController = vc
                (vc.view as? TimeLineView)?.reloadData()
            } else {
                switch isLTL {
                case .home:
                    self.timelineViewController = TimeLineViewController(type: .home)
                case .local:
                    self.timelineViewController = TimeLineViewController(type: .local)
                case .federation:
                    self.timelineViewController = TimeLineViewController(type: .federation)
                case .list:
                    self.timelineViewController = TimeLineViewController(type: .list)
                }
                self.timelineList.updateValue(self.timelineViewController!, forKey: key)
            }
            
            setButtonNameAndBorder()
            setAccountIcon()
        }
        
        // タイムラインビューを入れる
        self.addChildViewController(self.timelineViewController!)
        self.view.insertSubview(self.timelineViewController!.view, at: 1)
        
        let screenBounds = UIScreen.main.bounds
        if toRight {
            self.timelineViewController?.view.frame = CGRect(x: -screenBounds.width,
                                                             y: 0,
                                                             width: screenBounds.width,
                                                             height: screenBounds.height)
        } else {
            self.timelineViewController?.view.frame = CGRect(x: screenBounds.width,
                                                             y: 0,
                                                             width: screenBounds.width,
                                                             height: screenBounds.height)
        }
        
        // アニメーション
        UIView.animate(withDuration: 0.3, animations: {
            self.timelineViewController?.view.frame = CGRect(x: 0,
                                                             y: 0,
                                                             width: screenBounds.width,
                                                             height: screenBounds.height)
            
            if toRight {
                oldTimelineViewController?.view.frame = CGRect(x: screenBounds.width,
                                                               y: 0,
                                                               width: screenBounds.width,
                                                               height: screenBounds.height)
            } else {
                oldTimelineViewController?.view.frame = CGRect(x: -screenBounds.width,
                                                               y: 0,
                                                               width: screenBounds.width,
                                                               height: screenBounds.height)
            }
        }, completion: { _ in
            oldTimelineViewController?.removeFromParentViewController()
            oldTimelineViewController?.view.removeFromSuperview()
        })
        
        refreshNotificationButton()
    }
    
    // アカウントボタンをアイコンを設定
    func setAccountIcon() {
        if let accessToken = SettingsData.accessToken {
            if let iconStr = SettingsData.accountIconUrl(accessToken: accessToken) {
                ImageCache.image(urlStr: iconStr, isTemp: false, isSmall: true) { image in
                    if accessToken != SettingsData.accessToken { return }
                    if let view = self.view as? MainView {
                        view.accountButton.setImage(image, for: .normal)
                    }
                }
            }
        }
    }
    
    // 前のビューを外す
    private func removeOldView() {
        if let oldViewController = self.timelineViewController {
            oldViewController.removeFromParentViewController()
            oldViewController.view.removeFromSuperview()
        }
    }
    
    // 一時的にボタンを隠す
    private var buttonTimer: Timer?
    func hideButtons(force: Bool = false) {
        guard let view = self.view as? MainView else { return }
        
        UIView.animate(withDuration: 0.1) {
            view.tlButton.alpha = 0
            view.ltlButton.alpha = 0
            view.ftlButton.alpha = 0
            view.listButton.alpha = 0
            view.tootButton.alpha = 0
            view.searchButton.alpha = 0
            view.notificationsButton.alpha = 0
            view.accountButton.alpha = 0
        }
        
        TimeLineViewController.closeButtons.last?.isHidden = true
        
        self.buttonTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(checkTouch), userInfo: nil, repeats: true)
    }
    
    @objc func checkTouch() {
        guard let view = self.view as? MainView else { return }
        
        if let touchCount = (UIApplication.shared.keyWindow as? MyWindow)?.allTouches.count, touchCount > 0 {
            return
        }
        
        UIView.animate(withDuration: 0.1) {
            view.tlButton.alpha = 1
            view.ltlButton.alpha = 1
            view.ftlButton.alpha = 1
            view.listButton.alpha = 1
            view.tootButton.alpha = 1
            view.searchButton.alpha = 1
            view.notificationsButton.alpha = 1
            view.accountButton.alpha = 0.9
        }
        
        if let tableView = TimeLineViewController.closeButtons.last?.superview as? UITableView {
            TimeLineViewController.closeButtons.last?.frame.origin.y = UIScreen.main.bounds.height - (UIUtils.isIphoneX ? 110 : 70) + tableView.contentOffset.y
            TimeLineViewController.closeButtons.last?.isHidden = false
        }
        
        self.buttonTimer = nil
    }
    
    func hideButtonsForce() {
        guard let view = self.view as? MainView else { return }
        
        UIView.animate(withDuration: 0.5, animations: {
            view.tlButton.alpha = 0
            view.ltlButton.alpha = 0
            view.ftlButton.alpha = 0
            view.listButton.alpha = 0
            view.tootButton.alpha = 0
            view.searchButton.alpha = 0
            view.notificationsButton.alpha = 0
            view.accountButton.alpha = 0
        })
    }
    
    func showButtonsForce() {
        guard let view = self.view as? MainView else { return }
        
        UIView.animate(withDuration: 0.5) {
            view.tlButton.alpha = 1
            view.ltlButton.alpha = 1
            view.ftlButton.alpha = 1
            view.listButton.alpha = 1
            view.tootButton.alpha = 1
            view.searchButton.alpha = 1
            view.notificationsButton.alpha = 1
            view.accountButton.alpha = 0.9
        }
    }
    
    // アカウントボタンをタップ（設定画面に移動）
    @objc func accountAction(_ sender: UIButton?) {
        let settingsViewController = SettingsViewController()
        self.present(settingsViewController, animated: true, completion: nil)
    }
    
    // トゥート画面を開く
    @objc func tootAction(_ sender: UIButton?) {
        let tootViewController = TootViewController()
        tootViewController.view.backgroundColor = UIColor.clear
        if let rootVc = UIUtils.getFrontViewController() {
            rootVc.addChildViewController(tootViewController)
            rootVc.view.addSubview(tootViewController.view)
        }
    }
    
    // 一時的お知らせを更新
    enum NofityPosition {
        case top
        case center
    }
    func showNotify(text: String, position: NofityPosition = .top) {
        DispatchQueue.main.async {
            guard let view = self.view as? MainView else { return }
            
            view.notifyLabel.text = text
            
            UIView.animate(withDuration: 0.3, animations: {
                view.notifyLabel.alpha = 1
            })
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                UIView.animate(withDuration: 0.3, animations: {
                    view.notifyLabel.alpha = 0
                })
            }
            
            let screenBounds = UIScreen.main.bounds
            let notifyLabel = view.notifyLabel
            notifyLabel.frame.size.width = screenBounds.width - 50
            notifyLabel.sizeToFit()
            notifyLabel.frame.size.width += 10
            
            switch position {
            case .top:
                notifyLabel.frame = CGRect(x: screenBounds.width / 2 - notifyLabel.frame.width / 2,
                                           y: UIUtils.statusBarHeight() + 10,
                                           width: notifyLabel.frame.width,
                                           height: notifyLabel.frame.height + 2)
            case .center:
                notifyLabel.frame = CGRect(x: screenBounds.width / 2 - notifyLabel.frame.width / 2,
                                           y: screenBounds.height / 2 - notifyLabel.frame.height / 2 - 50,
                                           width: notifyLabel.frame.width,
                                           height: notifyLabel.frame.height + 2)
            }
        }
    }
    
    // 通知ボタンにマークをつける
    private var markNotificationDict: [String: Bool] = [:]
    func markNotificationButton(accessToken: String, to: Bool) {
        markNotificationDict.updateValue(to, forKey: accessToken)
        
        if SettingsData.accessToken == accessToken {
            DispatchQueue.main.async {
                guard let view = self.view as? MainView else { return }
                
                if to {
                    view.notificationsButton.setTitle(I18n.get("BUTTON_NOTIFY_MARK"), for: .normal)
                } else {
                    view.notificationsButton.setTitle(I18n.get("BUTTON_NOTIFY"), for: .normal)
                }
            }
        }
    }
    
    func refreshNotificationButton() {
        guard let view = self.view as? MainView else { return }
        
        if markNotificationDict[SettingsData.accessToken ?? ""] == true {
            view.notificationsButton.setTitle(I18n.get("BUTTON_NOTIFY_MARK"), for: .normal)
        } else {
            view.notificationsButton.setTitle(I18n.get("BUTTON_NOTIFY"), for: .normal)
        }
    }
}
