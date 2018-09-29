//
//  FollowingViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/28.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 指定ユーザーのFollowing/Followers一覧を表示する画面

import UIKit

final class FollowingViewController: MyViewController {
    private let type: String
    private var prevLinkStr: String?
    
    init(type: String) {
        self.type = type
        
        super.init(nibName: nil, bundle: nil)
        
        self.modalPresentationStyle = .overCurrentContext
        
        getNextData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = FollowingView()
        self.view = view
        
        view.closeButton.addTarget(self, action: #selector(self.closeAction), for: .touchUpInside)
        
        // 右スワイプで閉じる
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(closeAction))
        swipeGesture.direction = .right
        self.view?.addGestureRecognizer(swipeGesture)
        
        // アニメーション
        self.view.frame = CGRect(x: UIScreen.main.bounds.width,
                                 y: 0,
                                 width: UIScreen.main.bounds.width,
                                 height: UIScreen.main.bounds.height)
        UIView.animate(withDuration: 0.3) {
            self.view.frame = CGRect(x: 0,
                                     y: 0,
                                     width: UIScreen.main.bounds.width,
                                     height: UIScreen.main.bounds.height)
        }
    }
    
    func getNextData() {
        let urlStr: String
        if let prevLinkStr = self.prevLinkStr {
            urlStr = prevLinkStr
        } else {
            urlStr = "https://\(SettingsData.hostName ?? "")/api/v1/\(type)"
        }
        
        guard let url = URL(string: urlStr) else { return }
        try? MastodonRequest.get(url: url) { (data, response, error) in
            if let data = data {
                do {
                    guard let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Array<AnyObject> else { return }
                    
                    var list: [AnalyzeJson.AccountData] = []
                    for json in responseJson {
                        if let accountJson = json as? [String: Any] {
                            let accountData = AnalyzeJson.analyzeAccountJson(account: accountJson)
                            list.append(accountData)
                        }
                    }
                    
                    if let view = self.view as? FollowingView {
                        DispatchQueue.main.async {
                            if !view.tableView.model.change(addList: list) {
                                // 重複したデータを受信したら、終了
                                if let view = self.view as? FollowingView {
                                    view.tableView.model.showAutoPegerizeCell = false
                                }
                            }
                            view.tableView.reloadData()
                        }
                    }
                    
                    // フォロー関係を取得
                    var idStr = ""
                    for accountData in list {
                        if let id = accountData.id {
                            if idStr != "" {
                                idStr += "&"
                            }
                            idStr += "id[]=" + id
                        }
                    }
                    if let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/accounts/relationships/?\(idStr)") {
                        try? MastodonRequest.get(url: url) { (data, response, error) in
                            guard let view = self.view as? FollowingView else { return }
                            
                            if let data = data {
                                do {
                                    guard let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: Any]] else { return }
                                    
                                    for json in responseJson {
                                        if let id = json["id"] as? String {
                                            view.tableView.model.relationshipList.updateValue(json, forKey: id)
                                        }
                                    }
                                    
                                    DispatchQueue.main.async {
                                        view.tableView.reloadData()
                                    }
                                } catch { }
                            }
                        }
                    }
                } catch { }
            }
            
            if let response = response as? HTTPURLResponse {
                if let linkStr = response.allHeaderFields["Link"] as? String {
                    if linkStr.contains("rel=\"prev\"") {
                        if let prefix = linkStr.split(separator: ">").first {
                            self.prevLinkStr = String(prefix.suffix(prefix.count - 1))
                        }
                    } else {
                        if let view = self.view as? FollowingView {
                            view.tableView.model.showAutoPegerizeCell = false
                        }
                    }
                } else {
                    if let view = self.view as? FollowingView {
                        view.tableView.model.showAutoPegerizeCell = false
                    }
                }
            }
        }
    }
    
    @objc func closeAction() {
        UIView.animate(withDuration: 0.3, animations: {
            self.view.frame = CGRect(x: UIScreen.main.bounds.width,
                                     y: 0,
                                     width: UIScreen.main.bounds.width,
                                     height: UIScreen.main.bounds.height)
        }, completion: { _ in
            self.dismiss(animated: false, completion: nil)
        })
    }
}

private final class FollowingView: UIView {
    let tableView = FollowingTableView()
    let closeButton = UIButton()
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        
        self.addSubview(tableView)
        self.addSubview(closeButton)
        
        self.backgroundColor = ThemeColor.cellBgColor
        
        // 閉じるボタン
        closeButton.setTitle("×", for: .normal)
        closeButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        closeButton.backgroundColor = ThemeColor.mainButtonsBgColor
        closeButton.frame = CGRect(x: UIScreen.main.bounds.width / 2 - 50 / 2,
                                   y: UIScreen.main.bounds.height - 70,
                                   width: 50,
                                   height: 50)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class FollowingTableView: UITableView {
    let model = FollowingTableModel()
    
    init() {
        super.init(frame: UIScreen.main.bounds, style: UITableViewStyle.plain)
        
        self.delegate = model
        self.dataSource = model
        
        self.rowHeight = 56
        self.separatorStyle = .none
        
        self.backgroundColor = ThemeColor.cellBgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class FollowingTableModel: NSObject, UITableViewDataSource, UITableViewDelegate {
    var showAutoPegerizeCell = true
    private var list: [AnalyzeJson.AccountData] = []
    var relationshipList: [String: [String: Any]] = [:]
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func change(addList: [AnalyzeJson.AccountData]) -> Bool {
        if let first = addList.first {
            for data in self.list {
                if data.id == first.id {
                    return false
                }
            }
        }
        self.list += addList
        
        return true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count + (showAutoPegerizeCell ? 1 : 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row >= list.count {
            let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)
            cell.backgroundColor = ThemeColor.cellBgColor
            
            if let vc = UIUtils.getFrontViewController() as? FollowingViewController {
                vc.getNextData()
            }
            
            return cell
        }
        
        let reuseIdentifier = "FollowingTableModel"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? FollowingTableCell ?? FollowingTableCell(reuseIdentifier: reuseIdentifier)
        
        let data = list[indexPath.row]
        
        cell.accountId = data.acct ?? ""
        cell.accountData = data
        
        cell.iconView.image = nil
        ImageCache.image(urlStr: data.avatar_static, isTemp: false, isSmall: true) { image in
            if cell.accountId == data.acct {
                cell.iconView.image = image
            }
        }
        
        cell.nameLabel.attributedText = DecodeToot.decodeName(name: data.display_name, emojis: data.emojis, callback: {
            if cell.accountId == data.acct {
                cell.nameLabel.attributedText = DecodeToot.decodeName(name: data.display_name, emojis: data.emojis, callback: nil)
                cell.nameLabel.sizeToFit()
                cell.setNeedsLayout()
            }
        })
        cell.nameLabel.sizeToFit()
        
        cell.idLabel.text = list[indexPath.row].acct
        
        cell.followButton.alpha = 0
        cell.followButton.removeTarget(cell, action: #selector(cell.followAction), for: .touchUpInside)
        cell.followButton.removeTarget(cell, action: #selector(cell.unfollowAction), for: .touchUpInside)
        
        if let relationShipJson = relationshipList[data.id ?? ""] {
            cell.followButton.alpha = 1
            if relationShipJson["following"] as? Int == 1 {
                cell.followButton.setTitle("☑️", for: .normal)
                cell.followButton.backgroundColor = UIColor.blue.withAlphaComponent(0.5)
                cell.followButton.addTarget(cell, action: #selector(cell.unfollowAction), for: .touchUpInside)
            } else {
                cell.followButton.setTitle("+", for: .normal)
                cell.followButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 32)
                cell.followButton.setTitleColor(UIColor.blue, for: .normal)
                cell.followButton.backgroundColor = UIColor.gray
                cell.followButton.addTarget(cell, action: #selector(cell.followAction), for: .touchUpInside)
            }
        }
        
        return cell
    }
}

private final class FollowingTableCell: UITableViewCell {
    var accountId = ""
    
    // 基本ビュー
    let lineLayer = CALayer()
    let iconView = UIImageView()
    let nameLabel = UILabel()
    let idLabel = UILabel()
    
    var followButton = UIButton()
    
    var accountData: AnalyzeJson.AccountData?
    
    init(reuseIdentifier: String?) {
        super.init(style: UITableViewCellStyle.default, reuseIdentifier: reuseIdentifier)
        
        // デフォルトのビューは不要
        self.textLabel?.removeFromSuperview()
        self.detailTextLabel?.removeFromSuperview()
        self.imageView?.removeFromSuperview()
        self.contentView.removeFromSuperview()
        
        self.addSubview(iconView)
        self.addSubview(nameLabel)
        self.addSubview(idLabel)
        self.addSubview(followButton)
        self.layer.addSublayer(self.lineLayer)
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        // 固定プロパティは初期化時に設定
        self.clipsToBounds = true
        self.backgroundColor = ThemeColor.cellBgColor
        self.isOpaque = true
        self.selectionStyle = .none
        
        self.iconView.layer.cornerRadius = 5
        self.iconView.clipsToBounds = true
        
        self.nameLabel.textColor = ThemeColor.nameColor
        self.nameLabel.font = UIFont.boldSystemFont(ofSize: SettingsData.fontSize)
        self.nameLabel.backgroundColor = ThemeColor.cellBgColor
        self.nameLabel.isOpaque = true
        
        self.idLabel.textColor = ThemeColor.idColor
        self.idLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize - 2)
        self.idLabel.backgroundColor = ThemeColor.cellBgColor
        self.idLabel.isOpaque = true
        
        self.lineLayer.backgroundColor = ThemeColor.separatorColor.cgColor
        self.lineLayer.isOpaque = true
        
        // アイコンのタップジェスチャー
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAccountAction))
        self.iconView.addGestureRecognizer(tapGesture)
        self.iconView.isUserInteractionEnabled = true
        
        if SettingsData.isNameTappable {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAccountAction))
            self.nameLabel.addGestureRecognizer(tapGesture)
            self.nameLabel.isUserInteractionEnabled = true
        }
        
        self.followButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
        self.followButton.setTitleColor(ThemeColor.idColor, for: .normal)
        self.followButton.clipsToBounds = true
        self.followButton.layer.cornerRadius = 8
        self.followButton.alpha = 0
    }
    
    // アイコンをタップした時の処理
    @objc func tapAccountAction() {
        let accountTimeLineViewController = TimeLineViewController(type: TimeLineViewController.TimeLineType.user, option: accountData?.id ?? "")
        if let timelineView = accountTimeLineViewController.view as? TimeLineView, let accountData = self.accountData {
            timelineView.accountList.updateValue(accountData, forKey: accountData.id ?? "")
        }
        UIUtils.getFrontViewController()?.addChildViewController(accountTimeLineViewController)
        UIUtils.getFrontViewController()?.view.addSubview(accountTimeLineViewController.view)
        accountTimeLineViewController.view.frame = CGRect(x: UIScreen.main.bounds.width,
                                                          y: 0,
                                                          width: UIScreen.main.bounds.width,
                                                          height: UIScreen.main.bounds.height)
        UIView.animate(withDuration: 0.3) {
            accountTimeLineViewController.view.frame.origin.x = 0
        }
    }
    
    @objc func followAction() {
        ProfileAction.follow(id: self.accountData?.id ?? "")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/accounts/relationships/?id=\(self.accountData?.id ?? "")") {
                try? MastodonRequest.get(url: url) { (data, response, error) in
                    guard let view = self.superview as? FollowingTableView else { return }
                    
                    if let data = data {
                        do {
                            guard let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else { return }
                            
                            if let id = responseJson["id"] as? String {
                                view.model.relationshipList.updateValue(responseJson, forKey: id)
                            }
                            
                            DispatchQueue.main.async {
                                view.reloadData()
                            }
                        } catch { }
                    }
                }
            }
        }
    }
    
    @objc func unfollowAction() {
        Dialog.show(message: I18n.get("ALERT_UNFOLLOW"),
                    okName: I18n.get("ACTION_UNFOLLOW"),
                    cancelName: I18n.get("BUTTON_CANCEL"),
                    callback: { result in
                        ProfileAction.unfollow(id: self.accountData?.id ?? "")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/accounts/relationships/?id=\(self.accountData?.id ?? "")") {
                                try? MastodonRequest.get(url: url) { (data, response, error) in
                                    guard let view = self.superview as? FollowingTableView else { return }
                                    
                                    if let data = data {
                                        do {
                                            guard let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else { return }
                                            
                                            if let id = responseJson["id"] as? String {
                                                view.model.relationshipList.updateValue(responseJson, forKey: id)
                                            }
                                            
                                            DispatchQueue.main.async {
                                                view.reloadData()
                                            }
                                        } catch { }
                                    }
                                }
                            }
                        }
        })
    }
    
    override func layoutSubviews() {
        let screenBounds = UIScreen.main.bounds
        
        self.lineLayer.frame = CGRect(x: 0,
                                      y: 0,
                                      width: screenBounds.width,
                                      height: 1 / UIScreen.main.scale)
        
        self.iconView.frame = CGRect(x: 6,
                                     y: 8,
                                     width: 40,
                                     height: 40)
        
        self.nameLabel.frame = CGRect(x: 50,
                                      y: 7,
                                      width: self.nameLabel.frame.width,
                                      height: SettingsData.fontSize + 1)
        
        self.idLabel.frame = CGRect(x: 50,
                                    y: 32,
                                    width: screenBounds.width - 110,
                                    height: SettingsData.fontSize)
        
        self.followButton.frame = CGRect(x: screenBounds.width - 60,
                                         y: 8,
                                         width: 40,
                                         height: 40)
    }
    
}
