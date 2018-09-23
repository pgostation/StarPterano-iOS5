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
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = NotificationView()
        self.view = view
        
        view.closeButton.addTarget(self, action: #selector(self.closeAction), for: .touchUpInside)
        
        guard let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/notifications?limit=20") else { return }
        try? MastodonRequest.get(url: url, completionHandler: { [weak self] (data, response, error) in
            if let data = data {
                do {
                    let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Array<AnyObject>
                    
                    if let responseJson = responseJson {
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
                        
                        // 表示を更新
                        (self?.view as? NotificationView)?.tableView.model.change(addList: list)
                    }
                } catch {
                }
            } else if let error = error {
                print(error)
            }
        })
        
    }
    
    @objc func closeAction() {
        self.dismiss(animated: false, completion: nil)
    }
}

private final class NotificationView: UIView {
    let tableView = NotificatinTableView()
    let closeButton = UIButton()
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        
        self.addSubview(tableView)
        self.addSubview(closeButton)
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.backgroundColor = ThemeColor.viewBgColor
        
        // 閉じるボタン
        closeButton.setTitle("×", for: .normal)
        closeButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        closeButton.backgroundColor = ThemeColor.mainButtonsBgColor
        closeButton.frame = CGRect(x: UIScreen.main.bounds.width / 2 - 50 / 2,
                                   y: UIScreen.main.bounds.height - 70,
                                   width: 50,
                                   height: 50)
    }
}

private final class NotificatinTableView: UITableView {
    let model = NotificatinTableModel()
    
    init() {
        super.init(frame: UIScreen.main.bounds, style: UITableViewStyle.plain)
        
        self.delegate = model
        self.dataSource = model
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
