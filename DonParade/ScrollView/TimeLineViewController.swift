//
//  TimeLineViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/15.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 各種タイムラインやお気に入りなどを表示するViewController

import UIKit

final class TimeLineViewController: MyViewController {
    enum TimeLineType {
        case home // ホーム
        case local // ローカルタイムライン
        case federation // 連合タイムライン
        case user // 指定ユーザータイムライン
        case favorites // お気に入り
        case localTag
        case federationTag
        case mentions // 単一トゥート(と会話)
        case direct // ダイレクトメッセージ
        case list // リスト
    }
    
    static var closeButtons: [UIButton] = []
    let type: TimeLineType
    private let option: String? // user指定時はユーザID、タグ指定時はタグ
    private let mentions: ([AnalyzeJson.ContentData], [String: AnalyzeJson.AccountData])? // typeに.mentions指定時のみ有効
    
    init(type: TimeLineType, option: String? = nil, mentions: ([AnalyzeJson.ContentData], [String: AnalyzeJson.AccountData])? = nil) {
        self.type = type
        self.option = option
        self.mentions = mentions
        
        super.init(nibName: nil, bundle: nil)
        
        // アプリ起動後初回アクセスの場合はユーザーネームなどの情報を取得する
        if let accessToken = SettingsData.accessToken {
            if !SettingsData.loginedAccessTokenList.contains(accessToken) {
                SettingsData.loginedAccessTokenList.append(accessToken)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    guard let hostName = SettingsData.hostName else { return }
                    guard let accessToken = SettingsData.accessToken else { return }
                    
                    guard let url = URL(string: "https://\(hostName)/api/v1/accounts/verify_credentials") else { return }
                    
                    try? MastodonRequest.get(url: url, completionHandler: { (data, response, error) in
                        if let data = data {
                            do {
                                if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                                    let accountData = AnalyzeJson.analyzeAccountJson(account: responseJson)
                                    
                                    if let username = accountData.username, SettingsData.accountUsername(accessToken: accessToken) != username {
                                        SettingsData.setAccountUsername(accessToken: accessToken, value: username)
                                    }
                                    if let icon = accountData.avatar_static, SettingsData.accountIconUrl(accessToken: accessToken) != icon {
                                        SettingsData.setAccountIconUrl(accessToken: accessToken, value: icon)
                                        
                                        ImageCache.image(urlStr: icon, isTemp: false, isSmall: true) { image in
                                            if accessToken != SettingsData.accessToken { return }
                                            
                                            if let view = MainViewController.instance?.view as? MainView {
                                                view.accountButton.setImage(image, for: .normal)
                                            }
                                        }
                                    }
                                    if let id = accountData.id {
                                        SettingsData.setAccountNumberID(accessToken: accessToken, value: id)
                                    }
                                    if let locked = accountData.locked {
                                        SettingsData.setAccountLocked(accessToken: accessToken, value: locked == 1)
                                    }
                                }
                            } catch {
                            }
                        }
                    })
                }
            }
            
            if let iconStr = SettingsData.accountIconUrl(accessToken: accessToken) {
                ImageCache.image(urlStr: iconStr, isTemp: false, isSmall: true) { image in
                    if accessToken != SettingsData.accessToken { return }
                    
                    if let view = MainViewController.instance?.view as? MainView {
                        view.accountButton.setImage(image, for: .normal)
                    }
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        if self.type == .user || self.type == .mentions || self.type == .localTag || self.type == .federationTag || self.type == .direct || self.type == .favorites {
            let view = TimeLineView(type: self.type, option: self.option, mentions: mentions)
            self.view = view
            
            // 閉じるボタンを追加
            let closeButton = UIButton()
            closeButton.setTitle("×", for: .normal)
            closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 32)
            closeButton.titleLabel?.adjustsFontSizeToFitWidth = true
            closeButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
            closeButton.backgroundColor = ThemeColor.mainButtonsBgColor
            closeButton.clipsToBounds = true
            closeButton.layer.cornerRadius = 10
            closeButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
            closeButton.layer.borderWidth = 1
            closeButton.frame = CGRect(x: UIScreen.main.bounds.width / 2 - 60 / 2,
                                       y: UIScreen.main.bounds.height - (UIUtils.isIphoneX ? 120 : 80),
                                       width: 60,
                                       height: 60)
            closeButton.addTarget(self, action: #selector(self.closeAction), for: .touchUpInside)
            self.view?.addSubview(closeButton)
            TimeLineViewController.closeButtons.append(closeButton)
            
            // 右スワイプで閉じる
            let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(closeAction))
            swipeGesture.direction = .right
            self.view?.addGestureRecognizer(swipeGesture)
        } else {
            let view = TimeLineView(type: self.type, option: self.option, mentions: mentions)
            self.view = view
            
            if SettingsData.accountList.count >= 2 {
                // 右スワイプで前へ
                let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(rightAction))
                rightSwipeGesture.direction = .right
                self.view?.addGestureRecognizer(rightSwipeGesture)
                // 左スワイプで次へ
                let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(leftAction))
                leftSwipeGesture.direction = .left
                self.view?.addGestureRecognizer(leftSwipeGesture)
            }
        }
        
        // ピンチインでミニビューへ
        let pinchInGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchAction(_:)))
        self.view?.addGestureRecognizer(pinchInGesture)
    }
    
    // 表示時にストリーミングを開始する
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        (self.view as? TimeLineView)?.startStreaming()
        
        let text: String?
        if self.type == .home {
            text = (SettingsData.hostName ?? "") + "\n@" + (SettingsData.accountUsername(accessToken: SettingsData.accessToken ?? "") ?? "")
        }
        else if self.type == .local {
            text = (SettingsData.hostName ?? "") + "\n" + I18n.get("BUTTON_LTL")
        }
        else if self.type == .federation {
            text = (SettingsData.hostName ?? "") + "\n" + I18n.get("BUTTON_FTL")
        }
        else if self.type == .list {
            text = (SettingsData.hostName ?? "") + "\n" + I18n.get("BUTTON_LIST")
        }
        else {
            text = nil
        }
        
        if let text = text {
            MainViewController.instance?.showNotify(text: text, position: .center)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // GIFアニメーションと日付部分の更新を止める
        guard let tableView = self.view as? TimeLineView else { return }
        for cell in tableView.visibleCells {
            guard let cell = cell as? TimeLineViewCell else { continue }
            
            if cell.iconView?.image?.imageCount != nil {
                tableView.gifManager.deleteImageView(cell.iconView!)
            }
            
            cell.timer?.invalidate()
            cell.timer = nil
        }
        tableView.gifManager.clear()
    }
    
    // ユーザータイムライン/詳細トゥートを閉じる
    @objc func closeAction() {
        UIView.animate(withDuration: 0.3, animations: {
            self.view.frame = CGRect(x: UIScreen.main.bounds.width,
                                     y: 0,
                                     width: UIScreen.main.bounds.width,
                                     height: UIScreen.main.bounds.height)
        }, completion: { _ in
            self.removeFromParentViewController()
            self.view.removeFromSuperview()
            
            // 閉じるボタンは不要なので削除
            TimeLineViewController.closeButtons.removeLast()
        })
    }
    
    // スワイプで次へ
    @objc func leftAction() {
        let newIndex = (getIndexOfAccountList() + 1) % SettingsData.accountList.count
        
        let moveToAccount = SettingsData.accountList[newIndex]
        
        moveTo(moveToAccount: moveToAccount, toRight: false)
    }
    
    // スワイプで前へ
    @objc func rightAction() {
        let newIndex = (getIndexOfAccountList() + SettingsData.accountList.count - 1) % SettingsData.accountList.count
        
        let moveToAccount = SettingsData.accountList[newIndex]
        
        moveTo(moveToAccount: moveToAccount, toRight: true)
    }
    
    private func moveTo(moveToAccount: (String, String), toRight: Bool) {
        SettingsData.hostName = moveToAccount.0
        SettingsData.accessToken = moveToAccount.1
        
        MainViewController.instance?.swipeView(toRight: toRight)
    }
    
    // 現在のタイムライン画面に対応するアカウントの番号を返す
    private func getIndexOfAccountList() -> Int {
        let list = SettingsData.accountList
        
        for (index, data) in list.enumerated() {
            if SettingsData.hostName == data.0 && SettingsData.accessToken == data.1 {
                return index
            }
        }
        
        return 0
    }
    
    // ピンチインでミニビューへ
    private var pinchFlag = false
    @objc func pinchAction(_ gesture: UIPinchGestureRecognizer) {
        guard let view = self.view as? TimeLineView else { return }
        
        if gesture.state == .began {
            pinchFlag = false
        }
        if pinchFlag { return }
        
        if gesture.scale < 0.9 {
            pinchFlag = true
            view.enterMiniView()
        } else if gesture.scale > 1.1 {
            pinchFlag = true
            view.exitMiniView()
        }
    }
}
