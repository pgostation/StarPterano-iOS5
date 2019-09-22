//
//  NotificationViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/23.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 通知画面のビュー

import UIKit

final class NotificationViewController: MyViewController {
    static weak var instance: NotificationViewController?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        NotificationViewController.instance = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = NotificationView()
        self.view = view
        
        // 各ボタンのターゲット登録
        view.closeButton.addTarget(self, action: #selector(self.closeAction), for: .touchUpInside)
        
        view.segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        
        // 右スワイプで閉じる
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(closeAction))
        swipeGesture.direction = .right
        self.view?.addGestureRecognizer(swipeGesture)
        
        // 最新のデータを取得
        addOld()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let view = self.view as? NotificationView else { return }
        
        // 通知の既読設定
        if let created_at = view.tableView.model.getNewestCreatedAt() {
            let date = DecodeToot.decodeTime(text: created_at)
            let lastDate = SettingsData.newestNotifyDate(accessToken: SettingsData.accessToken)
            if lastDate == nil || date > lastDate! {
                SettingsData.newestNotifyDate(accessToken: SettingsData.accessToken, date: date)
            }
        }
    }
    
    func addOld() {
        var lastId: String? = nil
        if let view = self.view as? NotificationView {
            lastId = view.tableView.model.getLastId()
        }
        
        let waitIndicator = WaitIndicator()
        if lastId == nil {
            self.view.addSubview(waitIndicator)
        }
        
        var idStr = ""
        if let lastId = lastId {
            idStr = "&max_id=\(lastId)"
        }
        
        guard let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/notifications?limit=15\(idStr)") else { return }
        try? MastodonRequest.get(url: url, completionHandler: { [weak self] (data, response, error) in
            DispatchQueue.main.async {
                waitIndicator.removeFromSuperview()
            }
            
            if let data = data {
                do {
                    let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Array<AnyObject>
                    
                    if let responseJson = responseJson {
                        if responseJson.count == 0 {
                            if let view = self?.view as? NotificationView {
                                view.tableView.model.useAutopagerize = false
                            }
                            return
                        }
                        
                        var list: [AnalyzeJson.NotificationData] = []
                        
                        for json in responseJson {
                            let id = json["id"] as? String
                            let type = json["type"] as? String
                            let created_at = json["created_at"] as? String
                            
                            var account: AnalyzeJson.AccountData? = nil
                            if let accountJson = json["account"] as? [String: Any] {
                                account = AnalyzeJson.analyzeAccountJson(account: accountJson)
                                
                                if let acct = account?.acct, acct != "" {
                                    SettingsData.addRecentMention(key: acct)
                                }
                            }
                            
                            var status: AnalyzeJson.ContentData? = nil
                            if let statusJson = json["status"] as? [String: Any] {
                                var acct = ""
                                status = AnalyzeJson.analyzeJson(view: nil,
                                                                 model: nil,
                                                                 json: statusJson,
                                                                 acct: &acct)
                            }
                            
                            let data = AnalyzeJson.NotificationData(id: id,
                                                                    type: type,
                                                                    created_at: created_at,
                                                                    account: account,
                                                                    status: status)
                            list.append(data)
                        }
                        
                        DispatchQueue.main.async {
                            guard let view = self?.view as? NotificationView else { return }
                            // 表示を更新
                            view.tableView.model.change(addList: list)
                            view.tableView.reloadData()
                            
                            // 新着マークを表示
                            if let created_at = view.tableView.model.getNewestCreatedAt() {
                                let date = DecodeToot.decodeTime(text: created_at)
                                let lastDate = SettingsData.newestNotifyDate(accessToken: SettingsData.accessToken)
                                if lastDate == nil || date > lastDate! {
                                    if view.window == nil {
                                        MainViewController.instance?.markNotificationButton(accessToken: SettingsData.accessToken ?? "", to: true)
                                    }
                                }
                            }
                        }
                    }
                } catch {
                }
            } else if let error = error {
                print(error)
            }
        })
    }
    
    private var lastSelectedSegmentIndex = 0
    @objc func segmentChanged() {
        guard let view = self.view as? NotificationView else { return }
        
        self.lastSelectedSegmentIndex = view.segmentControl.selectedSegmentIndex
        
        view.tableView.reloadData()
    }
    
    @objc func closeAction() {
        UIView.animate(withDuration: 0.3, animations: {
            self.view.frame = CGRect(x: UIScreen.main.bounds.width,
                                     y: 0,
                                     width: UIScreen.main.bounds.width,
                                     height: UIScreen.main.bounds.height)
        }, completion: { _ in
            self.removeFromParent()
            self.view.removeFromSuperview()
        })
    }
}

final class NotificationView: UIView {
    fileprivate let tableView = NotificationTableView()
    let closeButton = UIButton()
    let segmentControl = UISegmentedControl()
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        
        self.addSubview(segmentControl)
        self.addSubview(tableView)
        self.addSubview(closeButton)
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.backgroundColor = ThemeColor.viewBgColor
        
        self.tableView.backgroundColor = ThemeColor.viewBgColor
        
        // セグメントコントロール
        segmentControl.insertSegment(withTitle: I18n.get("NOTIFY_SEG_ALL"), at: 0, animated: false)
        segmentControl.insertSegment(withTitle: I18n.get("NOTIFY_SEG_MENTION"), at: 1, animated: false)
        segmentControl.insertSegment(withTitle: I18n.get("NOTIFY_SEG_FOLLOW"), at: 2, animated: false)
        segmentControl.insertSegment(withTitle: I18n.get("NOTIFY_SEG_FAV"), at: 3, animated: false)
        segmentControl.insertSegment(withTitle: I18n.get("NOTIFY_SEG_BOOST"), at: 4, animated: false)
        segmentControl.selectedSegmentIndex = 0
        segmentControl.tintColor = ThemeColor.mainButtonsTitleColor
        segmentControl.backgroundColor = ThemeColor.cellBgColor
        
        // 閉じるボタン
        closeButton.setTitle("×", for: .normal)
        closeButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        closeButton.backgroundColor = ThemeColor.mainButtonsBgColor
        closeButton.layer.cornerRadius = 10
        closeButton.clipsToBounds = true
        closeButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        closeButton.layer.borderWidth = 1
    }
    
    override func layoutSubviews() {
        let screenBounds = UIScreen.main.bounds
        
        let segAllWidth = min(360, screenBounds.width)
        let segWidth = segAllWidth / CGFloat(segmentControl.numberOfSegments)
        for i in 0..<segmentControl.numberOfSegments {
            segmentControl.setWidth(segWidth - 0.5, forSegmentAt: i)
        }
        
        segmentControl.frame = CGRect(x: screenBounds.width / 2 - segAllWidth / 2,
                                      y: UIUtils.statusBarHeight(),
                                      width: segAllWidth,
                                      height: 40)
        
        tableView.frame = CGRect(x: 0,
                                 y: UIUtils.statusBarHeight() + 42,
                                 width: screenBounds.width,
                                 height: screenBounds.height - (UIUtils.statusBarHeight() + 42))
        
        closeButton.frame = CGRect(x: screenBounds.width / 2 - 50 / 2,
                                   y: screenBounds.height - (UIUtils.isIphoneX ? 110 : 70),
                                   width: 50,
                                   height: 50)
    }
}

private final class NotificationTableView: UITableView {
    let model = NotificationTableModel()
    
    init() {
        super.init(frame: UIScreen.main.bounds, style: UITableView.Style.plain)
        
        self.delegate = model
        self.dataSource = model
        
        self.separatorStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
