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
    var TimelineList: [String: TimeLineViewController] = [:]
    
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
        
        view.tootButton.addTarget(self, action: #selector(tootAction(_:)), for: .touchUpInside)
        
        view.searchButton.addTarget(self, action: #selector(searchAction(_:)), for: .touchUpInside)
        view.notificationsButton.addTarget(self, action: #selector(notificationsAction(_:)), for: .touchUpInside)
        
        view.accountButton.addTarget(self, action: #selector(accountAction(_:)), for: .touchUpInside)
        
        // 長押し
        let ltlPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(gtlAction(_:)))
        view.ltlButton.addGestureRecognizer(ltlPressGesture)
        
        // 起動時はTLを表示する
        tlAction(nil)
    }
    
    private var timelineViewController: TimeLineViewController?
    static var isLTLDict: [String: Bool] = [:]
    
    // タイムラインへの切り替え
    @objc func tlAction(_ sender: UIButton?) {
        // 前のビューを外す
        removeOldView()
        
        if let hostName = SettingsData.hostName, let accessToken = SettingsData.accessToken {
            let key = "\(hostName)_\(accessToken)_Home"
            if let vc = self.TimelineList[key] {
                self.timelineViewController = vc
            } else {
                self.timelineViewController = TimeLineViewController(type: .home)
                self.TimelineList.updateValue(self.timelineViewController!, forKey: key)
            }
            
            MainViewController.isLTLDict[hostName + "," + accessToken] = false
        }
        
        // 一番下にタイムラインビューを入れる
        self.addChildViewController(self.timelineViewController!)
        self.view.insertSubview(self.timelineViewController!.view, at: 0)
        
        if let view = self.view as? MainView {
            view.ltlButton.setTitle(I18n.get("BUTTON_LTL"), for: .normal)
            view.tlButton.layer.borderWidth = 2
            view.ltlButton.layer.borderWidth = 1 / UIScreen.main.scale
        }
    }
    
    // LTLへの切り替え
    @objc func ltlAction(_ sender: UIButton?) {
        // 前のビューを外す
        removeOldView()
        
        if let hostName = SettingsData.hostName, let accessToken = SettingsData.accessToken {
            let key = "\(hostName)_\(accessToken)_LTL"
            if let vc = self.TimelineList[key] {
                self.timelineViewController = vc
            } else {
                self.timelineViewController = TimeLineViewController(type: .local)
                self.TimelineList.updateValue(self.timelineViewController!, forKey: key)
            }
            
            MainViewController.isLTLDict[hostName + "," + accessToken] = true
        }
        
        // 一番下にタイムラインビューを入れる
        self.addChildViewController(self.timelineViewController!)
        self.view.insertSubview(self.timelineViewController!.view, at: 0)
        
        if let view = self.view as? MainView {
            view.ltlButton.setTitle(I18n.get("BUTTON_LTL"), for: .normal)
            view.ltlButton.layer.borderWidth = 2
            view.tlButton.layer.borderWidth = 1 / UIScreen.main.scale
        }
    }
    
    // 長押しで連合タイムラインへ移動
    @objc func gtlAction(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state != .began { return }
        
        // 前のビューを外す
        removeOldView()
        
        if let hostName = SettingsData.hostName, let accessToken = SettingsData.accessToken {
            let key = "\(hostName)_\(accessToken)_GTL"
            if let vc = self.TimelineList[key] {
                self.timelineViewController = vc
            } else {
                self.timelineViewController = TimeLineViewController(type: .global)
                self.TimelineList.updateValue(self.timelineViewController!, forKey: key)
            }
        }
        
        // 一番下にタイムラインビューを入れる
        self.addChildViewController(self.timelineViewController!)
        self.view.insertSubview(self.timelineViewController!.view, at: 0)
        
        if let view = self.view as? MainView {
            view.ltlButton.setTitle(I18n.get("BUTTON_GTL"), for: .normal)
            view.ltlButton.layer.borderWidth = 2
            view.tlButton.layer.borderWidth = 1 / UIScreen.main.scale
        }
    }
    
    // 検索画面に移動
    @objc func searchAction(_ sender: UIButton?) {
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
    
    func swipeView(toRight: Bool) {
        if TootViewController.isShown { return } // トゥート画面表示中は移動しない
        
        let oldTimelineViewController = self.timelineViewController
        
        if let hostName = SettingsData.hostName, let accessToken = SettingsData.accessToken {
            let isLTL = MainViewController.isLTLDict[hostName + "," + accessToken] ?? false
            let key = "\(hostName)_\(accessToken)_" + (isLTL ? "LTL" : "Home")
            if let vc = self.TimelineList[key] {
                self.timelineViewController = vc
            } else {
                self.timelineViewController = TimeLineViewController(type: isLTL ? .local : .home)
                self.TimelineList.updateValue(self.timelineViewController!, forKey: key)
            }
            
            if let view = self.view as? MainView {
                view.ltlButton.setTitle(I18n.get("BUTTON_LTL"), for: .normal)
                
                if isLTL {
                    view.ltlButton.layer.borderWidth = 2
                    view.tlButton.layer.borderWidth = 1 / UIScreen.main.scale
                } else {
                    view.tlButton.layer.borderWidth = 2
                    view.ltlButton.layer.borderWidth = 1 / UIScreen.main.scale
                }
                
                if let iconStr = SettingsData.accountIconUrl(accessToken: accessToken) {
                    ImageCache.image(urlStr: iconStr, isTemp: false, isSmall: true) { image in
                        if accessToken != SettingsData.accessToken { return }
                        view.accountButton.setImage(image, for: .normal)
                    }
                }
            }
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
            view.tootButton.alpha = 1
            view.searchButton.alpha = 1
            view.notificationsButton.alpha = 1
            view.accountButton.alpha = 1
        }
        
        if let tableView = TimeLineViewController.closeButtons.last?.superview as? UITableView {
            TimeLineViewController.closeButtons.last?.frame.origin.y = UIScreen.main.bounds.height - 70 + tableView.contentOffset.y
            TimeLineViewController.closeButtons.last?.isHidden = false
        }
        
        self.buttonTimer = nil
    }
    
    func hideButtonsForce() {
        guard let view = self.view as? MainView else { return }
        
        UIView.animate(withDuration: 0.5, animations: {
            view.tlButton.alpha = 0
            view.ltlButton.alpha = 0
            view.tootButton.alpha = 0
            view.searchButton.alpha = 0
            view.notificationsButton.alpha = 0
            view.accountButton.alpha = 0
        }, completion: { _ in
            view.tlButton.isHidden = true
            view.ltlButton.isHidden = true
            view.tootButton.isHidden = true
            view.searchButton.isHidden = true
            view.notificationsButton.isHidden = true
            view.accountButton.isHidden = true
        })
    }
    
    func showButtonsForce() {
        guard let view = self.view as? MainView else { return }
        
        UIView.animate(withDuration: 0.5) {
            view.tlButton.alpha = 1
            view.ltlButton.alpha = 1
            view.tootButton.alpha = 1
            view.searchButton.alpha = 1
            view.notificationsButton.alpha = 1
            view.accountButton.alpha = 1
        }
        
        view.tlButton.isHidden = false
        view.ltlButton.isHidden = false
        view.tootButton.isHidden = false
        view.searchButton.isHidden = false
        view.notificationsButton.isHidden = false
        view.accountButton.isHidden = false
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
        self.addChildViewController(tootViewController)
        self.view.addSubview(tootViewController.view)
    }
    
    // 一時的お知らせを更新
    func showNotify(text: String) {
        DispatchQueue.main.async {
            guard let view = self.view as? MainView else { return }
            
            view.notifyLabel.text = text
            view.setNeedsLayout()
            
            UIView.animate(withDuration: 0.3, animations: {
                view.notifyLabel.alpha = 1
            })
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                UIView.animate(withDuration: 0.3, animations: {
                    view.notifyLabel.alpha = 0
                })
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

final class MainView: UIView {
    // 左下
    let tlButton = UIButton()
    let ltlButton = UIButton()
    
    // 中央下
    let tootButton = UIButton()
    
    // 右下
    let searchButton = UIButton()
    let notificationsButton = UIButton()
    
    // 右上
    let accountButton = UIButton()
    
    // 上側の一時メッセージ表示
    let notifyLabel = UILabel()
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        
        self.addSubview(tlButton)
        self.addSubview(ltlButton)
        self.addSubview(tootButton)
        //self.addSubview(searchButton)
        self.addSubview(notificationsButton)
        self.addSubview(accountButton)
        self.addSubview(notifyLabel)
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.backgroundColor = ThemeColor.viewBgColor
        
        tlButton.setTitle(I18n.get("BUTTON_TL"), for: .normal)
        tlButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        tlButton.titleLabel?.adjustsFontSizeToFitWidth = true
        tlButton.setTitleShadowColor(ThemeColor.viewBgColor, for: .normal)
        tlButton.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)
        tlButton.backgroundColor = ThemeColor.mainButtonsBgColor
        tlButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        tlButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        tlButton.layer.borderWidth = 1 / UIScreen.main.scale
        tlButton.clipsToBounds = true
        tlButton.layer.cornerRadius = 10
        if #available(iOS 11.0, *) {
            tlButton.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        }
        
        ltlButton.setTitle(I18n.get("BUTTON_LTL"), for: .normal)
        ltlButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        ltlButton.titleLabel?.adjustsFontSizeToFitWidth = true
        ltlButton.setTitleShadowColor(ThemeColor.viewBgColor, for: .normal)
        ltlButton.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)
        ltlButton.backgroundColor = ThemeColor.mainButtonsBgColor
        ltlButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        ltlButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        ltlButton.layer.borderWidth = 1 / UIScreen.main.scale
        ltlButton.clipsToBounds = true
        ltlButton.layer.cornerRadius = 10
        if #available(iOS 11.0, *) {
            ltlButton.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        }
        
        tootButton.setTitle(I18n.get("BUTTON_TOOT"), for: .normal)
        tootButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        ltlButton.titleLabel?.adjustsFontSizeToFitWidth = true
        tootButton.setTitleShadowColor(ThemeColor.viewBgColor, for: .normal)
        tootButton.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)
        tootButton.backgroundColor = ThemeColor.mainButtonsBgColor
        tootButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        tootButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        tootButton.layer.borderWidth = 1 / UIScreen.main.scale
        tootButton.clipsToBounds = true
        tootButton.layer.cornerRadius = 35
        
        searchButton.setTitle(I18n.get("BUTTON_SEARCH"), for: .normal)
        searchButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        searchButton.titleLabel?.adjustsFontSizeToFitWidth = true
        searchButton.setTitleShadowColor(ThemeColor.viewBgColor, for: .normal)
        searchButton.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)
        searchButton.backgroundColor = ThemeColor.mainButtonsBgColor
        searchButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        searchButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        searchButton.layer.borderWidth = 1 / UIScreen.main.scale
        searchButton.clipsToBounds = true
        searchButton.layer.cornerRadius = 10
        if #available(iOS 11.0, *) {
            searchButton.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
        }
        
        notificationsButton.setTitle(I18n.get("BUTTON_NOTIFY"), for: .normal)
        notificationsButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        notificationsButton.titleLabel?.adjustsFontSizeToFitWidth = true
        notificationsButton.setTitleShadowColor(ThemeColor.viewBgColor, for: .normal)
        notificationsButton.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)
        notificationsButton.backgroundColor = ThemeColor.mainButtonsBgColor
        notificationsButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        notificationsButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        notificationsButton.layer.borderWidth = 1 / UIScreen.main.scale
        notificationsButton.clipsToBounds = true
        notificationsButton.layer.cornerRadius = 10
        if #available(iOS 11.0, *) {
            notificationsButton.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
        }
        
        accountButton.setTitle("", for: .normal)
        accountButton.backgroundColor = ThemeColor.mainButtonsBgColor
        accountButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        accountButton.clipsToBounds = true
        accountButton.layer.cornerRadius = 10
        
        notifyLabel.backgroundColor = ThemeColor.idColor.withAlphaComponent(0.8)
        notifyLabel.textColor = ThemeColor.viewBgColor
        notifyLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
        notifyLabel.textAlignment = .center
        notifyLabel.numberOfLines = 0
        notifyLabel.lineBreakMode = .byCharWrapping
        notifyLabel.layer.cornerRadius = 4
        notifyLabel.clipsToBounds = true
        notifyLabel.alpha = 0
    }
    
    override func layoutSubviews() {
        let screenBounds = UIScreen.main.bounds
        let bottomOffset: CGFloat = UIUtils.isIphoneX ? 50 : 0
        let buttonWidth: CGFloat = 60
        let buttonHeight: CGFloat = 40
        
        tlButton.frame = CGRect(x: -1,
                                y: screenBounds.height - 100 - bottomOffset,
                                width: buttonWidth,
                                height: buttonHeight)
        
        ltlButton.frame = CGRect(x: -1,
                                 y: screenBounds.height - 50 - bottomOffset,
                                 width: buttonWidth,
                                 height: buttonHeight)
        
        tootButton.frame = CGRect(x: screenBounds.width / 2 - 70 / 2,
                                  y: screenBounds.height - 70 - bottomOffset,
                                  width: 70,
                                  height: 70)
        
        searchButton.frame = CGRect(x: screenBounds.width - buttonWidth + 1,
                                    y: screenBounds.height - 100 - bottomOffset,
                                    width: buttonWidth,
                                    height: buttonHeight)
        
        notificationsButton.frame = CGRect(x: screenBounds.width - buttonWidth + 1,
                                           y: screenBounds.height - 50 - bottomOffset,
                                           width: buttonWidth,
                                           height: buttonHeight)
        
        accountButton.frame = CGRect(x: screenBounds.width - 50,
                                     y: 30 + bottomOffset / 2,
                                     width: 40,
                                     height: 40)
        
        notifyLabel.frame.size.width = screenBounds.width - 50
        notifyLabel.sizeToFit()
        notifyLabel.frame.size.width += 10
        notifyLabel.frame = CGRect(x: screenBounds.width / 2 - notifyLabel.frame.width / 2,
                                   y: 30 + bottomOffset / 2,
                                   width: notifyLabel.frame.width,
                                   height: notifyLabel.frame.height + 2)
    }
}
