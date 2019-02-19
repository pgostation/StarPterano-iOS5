//
//  FollowRequestViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/10/06.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit

final class FollowRequestViewController: MyViewController {
    private var prevLinkStr: String?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        getNextData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = FollowRequestView()
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
            urlStr = "https://\(SettingsData.hostName ?? "")/api/v1/follow_requests"
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
                    
                    if let view = self.view as? FollowRequestView {
                        DispatchQueue.main.async {
                            if !view.tableView.model.change(addList: list) {
                                // 重複したデータを受信したら、終了
                                if let view = self.view as? FollowRequestView {
                                    view.tableView.model.showAutoPegerizeCell = false
                                }
                            }
                            view.tableView.reloadData()
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
                        if let view = self.view as? FollowRequestView {
                            view.tableView.model.showAutoPegerizeCell = false
                        }
                    }
                } else {
                    if let view = self.view as? FollowRequestView {
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
            self.removeFromParent()
            self.view.removeFromSuperview()
        })
    }
}

private final class FollowRequestView: UIView {
    let tableView = FollowRequestTableView()
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
        closeButton.layer.cornerRadius = 10
        closeButton.clipsToBounds = true
        closeButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        closeButton.layer.borderWidth = 1
        
        closeButton.frame = CGRect(x: UIScreen.main.bounds.width / 2 - 50 / 2,
                                   y: UIScreen.main.bounds.height - (UIUtils.isIphoneX ? 110 : 70),
                                   width: 50,
                                   height: 50)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class FollowRequestTableView: UITableView {
    let model = FollowRequestTableModel()
    
    init() {
        super.init(frame: UIScreen.main.bounds, style: UITableView.Style.plain)
        
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

final class FollowRequestTableModel: NSObject, UITableViewDataSource, UITableViewDelegate {
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
    
    func clear() {
        self.list = []
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count + (showAutoPegerizeCell ? 1 : 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row >= list.count {
            let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: nil)
            cell.backgroundColor = ThemeColor.cellBgColor
            
            if let vc = UIUtils.getFrontViewController() as? FollowRequestViewController {
                vc.getNextData()
            }
            
            return cell
        }
        
        let reuseIdentifier = "FollowRequestTableModel"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? FollowRequestTableCell ?? FollowRequestTableCell(reuseIdentifier: reuseIdentifier)
        
        let data = list[indexPath.row]
        
        cell.accountId = data.id ?? ""
        cell.accountData = data
        
        cell.iconView.image = nil
        ImageCache.image(urlStr: data.avatar_static, isTemp: false, isSmall: true) { image in
            if cell.accountId == data.acct {
                cell.iconView.image = image
            }
        }
        
        cell.nameLabel.attributedText = DecodeToot.decodeName(name: data.display_name, emojis: data.emojis, uiLabel: cell.nameLabel, callback: {
            if cell.accountId == data.acct {
                cell.nameLabel.attributedText = DecodeToot.decodeName(name: data.display_name, emojis: data.emojis, uiLabel: cell.nameLabel, callback: nil)
                cell.nameLabel.sizeToFit()
                cell.setNeedsLayout()
            }
        })
        cell.nameLabel.sizeToFit()
        
        cell.idLabel.text = list[indexPath.row].acct
        
        return cell
    }
}

private final class FollowRequestTableCell: UITableViewCell {
    var accountId = ""
    
    // 基本ビュー
    let lineLayer = CALayer()
    let iconView = WideTouchImageView()
    let nameLabel = UILabel()
    let idLabel = UILabel()
    
    var acceptButton = UIButton()
    var ignoreButton = UIButton()
    
    var accountData: AnalyzeJson.AccountData?
    
    init(reuseIdentifier: String?) {
        super.init(style: UITableViewCell.CellStyle.default, reuseIdentifier: reuseIdentifier)
        
        // デフォルトのビューは不要
        self.textLabel?.removeFromSuperview()
        self.detailTextLabel?.removeFromSuperview()
        self.imageView?.removeFromSuperview()
        self.contentView.removeFromSuperview()
        
        self.addSubview(iconView)
        self.addSubview(nameLabel)
        self.addSubview(idLabel)
        self.addSubview(acceptButton)
        self.addSubview(ignoreButton)
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
        self.iconView.insets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
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
        
        self.acceptButton.setTitle("✔︎", for: .normal)
        self.acceptButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
        self.acceptButton.setTitleColor(ThemeColor.idColor, for: .normal)
        self.acceptButton.clipsToBounds = true
        self.acceptButton.layer.cornerRadius = 8
        self.acceptButton.addTarget(self, action: #selector(acceptAction), for: .touchUpInside)
        
        self.ignoreButton.setTitle("×", for: .normal)
        self.ignoreButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
        self.ignoreButton.setTitleColor(ThemeColor.idColor, for: .normal)
        self.ignoreButton.clipsToBounds = true
        self.ignoreButton.layer.cornerRadius = 8
        self.ignoreButton.addTarget(self, action: #selector(ignoreAction), for: .touchUpInside)
    }
    
    // アイコンをタップした時の処理
    @objc func tapAccountAction() {
        let accountTimeLineViewController = TimeLineViewController(type: TimeLineViewController.TimeLineType.user, option: accountData?.id ?? "")
        if let timelineView = accountTimeLineViewController.view as? TimeLineView, let accountData = self.accountData {
            timelineView.accountList.updateValue(accountData, forKey: accountData.id ?? "")
        }
        UIUtils.getFrontViewController()?.addChild(accountTimeLineViewController)
        UIUtils.getFrontViewController()?.view.addSubview(accountTimeLineViewController.view)
        accountTimeLineViewController.view.frame = CGRect(x: UIScreen.main.bounds.width,
                                                          y: 0,
                                                          width: UIScreen.main.bounds.width,
                                                          height: UIScreen.main.bounds.height)
        UIView.animate(withDuration: 0.3) {
            accountTimeLineViewController.view.frame.origin.x = 0
        }
    }
    
    @objc func acceptAction() {
        let accountId = self.accountId
        
        let urlStr = "https://\(SettingsData.hostName ?? "")/api/v1/follow_requests/\(accountId)/authorize"
        
        guard let url = URL(string: urlStr) else { return }
        try? MastodonRequest.post(url: url, body: [:]) { (data, response, error) in
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                DispatchQueue.main.async {
                    if self.accountId == accountId {
                        self.acceptButton.isHidden = true
                        self.ignoreButton.isHidden = true
                    }
                }
            }
        }
    }
    
    @objc func ignoreAction() {
        let accountId = self.accountId
        
        let urlStr = "https://\(SettingsData.hostName ?? "")/api/v1/follow_requests/\(accountId)/reject"
        
        guard let url = URL(string: urlStr) else { return }
        try? MastodonRequest.post(url: url, body: [:]) { (data, response, error) in
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                DispatchQueue.main.async {
                    if self.accountId == accountId {
                        self.acceptButton.isHidden = true
                        self.ignoreButton.isHidden = true
                    }
                }
            }
        }
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
                                    width: screenBounds.width - 50 - 50 - 50,
                                    height: SettingsData.fontSize)
        
        self.acceptButton.frame = CGRect(x: screenBounds.width - 100,
                                         y: 8,
                                         width: 40,
                                         height: 40)
        
        self.ignoreButton.frame = CGRect(x: screenBounds.width - 50,
                                         y: 8,
                                         width: 40,
                                         height: 40)
    }
}
