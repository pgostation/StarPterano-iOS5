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
    
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if SettingsData.isDarkMode {
            return UIStatusBarStyle.lightContent
        } else {
            return UIStatusBarStyle.default
        }
    }
    
    override func loadView() {
        MainViewController.instance = self
        
        self.setNeedsStatusBarAppearanceUpdate()
        
        ThemeColor.change()
        
        // 共通部分のビュー
        let view = MainView()
        self.view = view
        
        view.tlButton.addTarget(self, action: #selector(tlAction(_:)), for: .touchUpInside)
        view.ltlButton.addTarget(self, action: #selector(ltlAction(_:)), for: .touchUpInside)
        
        view.tootButton.addTarget(self, action: #selector(tootAction(_:)), for: .touchUpInside)
        
        view.accountButton.addTarget(self, action: #selector(accountAction(_:)), for: .touchUpInside)
        
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
            view.ltlButton.setTitle("LTL", for: .normal)
            view.tlButton.setTitle("<TL>", for: .normal)
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
            view.ltlButton.setTitle("<LTL>", for: .normal)
            view.tlButton.setTitle("TL", for: .normal)
        }
    }
    
    func swipeView(toRight: Bool) {
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
                if isLTL {
                    view.ltlButton.setTitle("<LTL>", for: .normal)
                    view.tlButton.setTitle("TL", for: .normal)
                } else {
                    view.ltlButton.setTitle("LTL", for: .normal)
                    view.tlButton.setTitle("<TL>", for: .normal)
                }
                view.accountButton.setTitle(String(hostName.prefix(8)), for: .normal)
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
    func hideButtons() {
        guard let view = self.view as? MainView else { return }
        
        UIView.animate(withDuration: 0.1) {
            view.tlButton.alpha = 0
            view.ltlButton.alpha = 0
            view.tootButton.alpha = 0
            view.listButton.alpha = 0
            view.notificationsButton.alpha = 0
            view.accountButton.alpha = 0
        }
        
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
            view.listButton.alpha = 1
            view.notificationsButton.alpha = 1
            view.accountButton.alpha = 1
        }
        
        self.buttonTimer = nil
    }
    
    // アカウントボタンをタップ（設定画面に移動）
    @objc func accountAction(_ sender: UIButton?) {
        let settingsViewController = SettingsViewController()
        self.present(settingsViewController, animated: true, completion: nil)
    }
    
    // トゥート画面を開く
    @objc func tootAction(_ sender: UIButton?) {
        let tootViewController = TootViewController()
        tootViewController.modalPresentationStyle = .overCurrentContext
        tootViewController.view.backgroundColor = UIColor.clear
        self.present(tootViewController, animated: false, completion: nil)
    }
}

private final class MainView: UIView {
    // 左下
    let tlButton = UIButton()
    let ltlButton = UIButton()
    
    // 中央下
    let tootButton = UIButton()
    
    // 右下
    let listButton = UIButton()
    let notificationsButton = UIButton()
    
    // 右上
    let accountButton = UIButton()
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        
        self.addSubview(tlButton)
        self.addSubview(ltlButton)
        self.addSubview(tootButton)
        self.addSubview(listButton)
        self.addSubview(notificationsButton)
        self.addSubview(accountButton)
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.backgroundColor = ThemeColor.viewBgColor
        
        tlButton.setTitle(I18n.get("BUTTON_TL"), for: .normal)
        tlButton.backgroundColor = ThemeColor.mainButtonsBgColor
        tlButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        
        ltlButton.setTitle(I18n.get("BUTTON_LTL"), for: .normal)
        ltlButton.backgroundColor = ThemeColor.mainButtonsBgColor
        ltlButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        
        tootButton.setTitle(I18n.get("BUTTON_TOOT"), for: .normal)
        tootButton.backgroundColor = ThemeColor.mainButtonsBgColor
        tootButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        tootButton.clipsToBounds = true
        tootButton.layer.cornerRadius = 20
        
        listButton.setTitle(I18n.get("BUTTON_LIST"), for: .normal)
        listButton.backgroundColor = ThemeColor.mainButtonsBgColor
        listButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        
        notificationsButton.setTitle(I18n.get("BUTTON_NOTIFY"), for: .normal)
        notificationsButton.backgroundColor = ThemeColor.mainButtonsBgColor
        notificationsButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        
        accountButton.setTitle(I18n.get("BUTTON_ACCOUNT"), for: .normal)
        accountButton.backgroundColor = ThemeColor.mainButtonsBgColor
        accountButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        accountButton.clipsToBounds = true
        accountButton.layer.cornerRadius = 10
    }
    
    override func layoutSubviews() {
        let screenBounds = UIScreen.main.bounds
        let bottomOffset: CGFloat = UIUtils.isIphoneX ? 50 : 0
        let buttonWidth: CGFloat = 60
        let buttonHeight: CGFloat = 40
        
        tlButton.frame = CGRect(x: 0,
                                y: screenBounds.height - 100 - bottomOffset,
                                width: buttonWidth,
                                height: buttonHeight)
        
        ltlButton.frame = CGRect(x: 0,
                                 y: screenBounds.height - 50 - bottomOffset,
                                 width: buttonWidth,
                                 height: buttonHeight)
        
        tootButton.frame = CGRect(x: screenBounds.width / 2 - 70 / 2,
                                  y: screenBounds.height - 70 - bottomOffset,
                                  width: 70,
                                  height: 70)
        
        listButton.frame = CGRect(x: screenBounds.width - buttonWidth,
                                  y: screenBounds.height - 100 - bottomOffset,
                                  width: buttonWidth,
                                  height: buttonHeight)
        
        notificationsButton.frame = CGRect(x: screenBounds.width - buttonWidth,
                                           y: screenBounds.height - 50 - bottomOffset,
                                           width: buttonWidth,
                                           height: buttonHeight)
        
        accountButton.frame = CGRect(x: screenBounds.width - 60,
                                     y: 30 + bottomOffset / 2,
                                     width: 50,
                                     height: 50)
    }
}
