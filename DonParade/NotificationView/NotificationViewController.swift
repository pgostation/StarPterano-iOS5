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
    
    func addOld() {
        var lastId: String? = nil
        if let view = self.view as? NotificationView {
            lastId = view.tableView.model.getLastId()
        }
        
        var idStr = ""
        if let lastId = lastId {
            idStr = "&max_id=\(lastId)"
        }
        
        guard let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/notifications?limit=15\(idStr)") else { return }
        try? MastodonRequest.get(url: url, completionHandler: { [weak self] (data, response, error) in
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
                        }
                    }
                } catch {
                }
            } else if let error = error {
                print(error)
            }
        })
    }
    
    @objc func segmentChanged() {
        guard let view = self.view as? NotificationView else { return }
        
        view.tableView.reloadData()
    }
    
    @objc func closeAction() {
        UIView.animate(withDuration: 0.3, animations: {
            self.view.frame = CGRect(x: UIScreen.main.bounds.width,
                                     y: 0,
                                     width: UIScreen.main.bounds.width,
                                     height: UIScreen.main.bounds.height)
        }, completion: { _ in
            self.removeFromParentViewController()
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
        
        let screenBounds = UIScreen.main.bounds
        let segAllWidth = min(360, screenBounds.width * 0.98)
        let segWidth = segAllWidth / 5
        for i in 0..<segmentControl.numberOfSegments {
            segmentControl.setWidth(segWidth, forSegmentAt: i)
        }
        
        segmentControl.frame = CGRect(x: screenBounds.width / 2 - segAllWidth / 2,
                                      y: UIUtils.statusBarHeight(),
                                      width: segAllWidth,
                                      height: 40)
        
        
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
        
        tableView.frame = CGRect(x: 0,
                                 y: UIUtils.statusBarHeight() + 42,
                                 width: screenBounds.width,
                                 height: screenBounds.height - (UIUtils.statusBarHeight() + 42))
        
        closeButton.frame = CGRect(x: screenBounds.width / 2 - 50 / 2,
                                   y: screenBounds.height - 70,
                                   width: 50,
                                   height: 50)
    }
}

private final class NotificationTableView: UITableView {
    let model = NotificationTableModel()
    
    init() {
        super.init(frame: UIScreen.main.bounds, style: UITableViewStyle.plain)
        
        self.delegate = model
        self.dataSource = model
        
        self.separatorStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
