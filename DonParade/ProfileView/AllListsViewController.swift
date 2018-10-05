//
//  AllListsViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/10/04.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// ユーザーをどのリストに追加するか/削除するか

import UIKit

final class AllListsViewController: MyViewController {
    let accountId: String
    
    init(accountId: String) {
        self.accountId = accountId
        
        super.init(nibName: nil, bundle: nil)
        
        self.modalPresentationStyle = .overCurrentContext
        
        getListData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.getAccountListData()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = AllListsView(accountId: self.accountId)
        self.view = view
        
        view.closeButton.addTarget(self, action: #selector(self.closeAction), for: .touchUpInside)
    }
    
    private func getListData() {
        let urlStr = "https://\(SettingsData.hostName ?? "")/api/v1/lists"
        
        guard let url = URL(string: urlStr) else { return }
        try? MastodonRequest.get(url: url) { (data, response, error) in
            if let data = data {
                do {
                    guard let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: Any]] else { return }
                    
                    var list: [AnalyzeJson.ListData] = []
                    for json in responseJson {
                        let data = AnalyzeJson.ListData(id: json["id"] as? String,
                                                        title: json["title"] as? String)
                        list.append(data)
                    }
                    
                    DispatchQueue.main.async {
                        if let view = self.view as? AllListsView {
                            view.tableView.model.list = list
                            view.tableView.reloadData()
                        }
                    }
                } catch { }
            }
        }
    }
    
    private func getAccountListData() {
        let urlStr = "https://\(SettingsData.hostName ?? "")/api/v1/accounts/\(self.accountId)/lists"
        
        guard let url = URL(string: urlStr) else { return }
        try? MastodonRequest.get(url: url) { (data, response, error) in
            if let data = data {
                do {
                    guard let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: Any]] else { return }
                    
                    print(responseJson)
                    
                    var list: [AnalyzeJson.ListData] = []
                    for json in responseJson {
                        let data = AnalyzeJson.ListData(id: json["id"] as? String,
                                                        title: json["title"] as? String)
                        list.append(data)
                    }
                    
                    DispatchQueue.main.async {
                        if let view = self.view as? AllListsView {
                            view.tableView.model.accountList = list
                            view.tableView.reloadData()
                        }
                    }
                } catch { }
            }
        }
    }
    
    @objc func closeAction() {
        self.dismiss(animated: true, completion: nil)
    }
}

private final class AllListsView: UIView {
    let tableView: AllListsTableView
    let closeButton = UIButton()
    
    init(accountId: String) {
        self.tableView = AllListsTableView(accountId: accountId)
        
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

final class AllListsTableView: UITableView {
    let model: AllListsTableModel
    
    init(accountId: String) {
        self.model = AllListsTableModel(accountId: accountId)
        
        super.init(frame: UIScreen.main.bounds, style: UITableViewStyle.plain)
        
        self.delegate = model
        self.dataSource = model
        
        self.rowHeight = 52
        self.separatorStyle = .none
        
        self.backgroundColor = ThemeColor.cellBgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class AllListsTableModel: NSObject, UITableViewDataSource, UITableViewDelegate {
    private let accountId: String
    var list: [AnalyzeJson.ListData] = []
    var accountList: [AnalyzeJson.ListData]? = nil // アカウントが属しているリスト
    
    init(accountId: String) {
        self.accountId = accountId
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count + 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row >= list.count {
            let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)
            cell.backgroundColor = ThemeColor.cellBgColor
            return cell
        }
        
        let reuseIdentifier = "AllListsTableModel"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? AllListsTableCell ?? AllListsTableCell(reuseIdentifier: reuseIdentifier)
        
        let data = list[indexPath.row]
        
        cell.accountId = self.accountId
        cell.listId = data.id ?? ""
        
        cell.nameLabel.text = data.title
        
        // ボタンの表示/非表示
        cell.addButton.isHidden = true
        cell.removeButton.isHidden = true
        if let accountList = self.accountList {
            print("accountList =\(accountList)")
            print("data = \(data)")
            var flag = false
            for hasAccount in accountList {
                if data.id == hasAccount.id {
                    flag = true
                    break
                }
            }
            
            if flag {
                cell.removeButton.isHidden = false
            } else {
                cell.addButton.isHidden = false
            }
        }
        
        return cell
    }
}

private final class AllListsTableCell: UITableViewCell {
    var listId = ""
    var accountId = ""
    
    // 基本ビュー
    let lineLayer = CALayer()
    let nameLabel = UILabel()
    
    let addButton = UIButton()
    let removeButton = UIButton()
    
    init(reuseIdentifier: String?) {
        super.init(style: UITableViewCellStyle.default, reuseIdentifier: reuseIdentifier)
        
        // デフォルトのビューは不要
        self.textLabel?.removeFromSuperview()
        self.detailTextLabel?.removeFromSuperview()
        self.imageView?.removeFromSuperview()
        self.contentView.removeFromSuperview()
        
        self.addSubview(nameLabel)
        self.addSubview(addButton)
        self.addSubview(removeButton)
        self.layer.addSublayer(self.lineLayer)
        
        addButton.addTarget(self, action: #selector(addButtonAction), for: .touchUpInside)
        removeButton.addTarget(self, action: #selector(removeButtonAction), for: .touchUpInside)
        
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
        
        self.nameLabel.textColor = ThemeColor.nameColor
        self.nameLabel.font = UIFont.boldSystemFont(ofSize: SettingsData.fontSize + 2)
        self.nameLabel.backgroundColor = ThemeColor.cellBgColor
        self.nameLabel.isOpaque = true
        
        self.lineLayer.backgroundColor = ThemeColor.separatorColor.cgColor
        self.lineLayer.isOpaque = true
        
        self.addButton.setTitle("+", for: .normal)
        self.addButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        self.addButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
        self.addButton.setTitleColor(UIColor.blue, for: .normal)
        self.addButton.clipsToBounds = true
        self.addButton.layer.cornerRadius = 8
        
        self.removeButton.setTitle("-", for: .normal)
        self.removeButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        self.removeButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
        self.removeButton.setTitleColor(ThemeColor.idColor, for: .normal)
        self.removeButton.clipsToBounds = true
        self.removeButton.layer.cornerRadius = 8
    }
    
    // リストに追加
    @objc func addButtonAction() {
        guard let hostName = SettingsData.hostName else { return }
        
        let url = URL(string: "https://\(hostName)/api/v1/lists/\(self.listId)/accounts")!
        
        try? MastodonRequest.post(url: url, body: ["account_ids": ["\(self.accountId)"]]) { (data, response, error) in
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                DispatchQueue.main.async {
                    self.removeButton.isHidden = false
                    self.addButton.isHidden = true
                }
            }
        }
    }
    
    // リストから削除
    @objc func removeButtonAction() {
        guard let hostName = SettingsData.hostName else { return }
        
        let url = URL(string: "https://\(hostName)/api/v1/lists/\(self.listId)/accounts")!
        
        try? MastodonRequest.delete(url: url, body: ["account_ids": ["\(self.accountId)"]]) { (data, response, error) in
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                DispatchQueue.main.async {
                    self.removeButton.isHidden = true
                    self.addButton.isHidden = false
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
        
        self.nameLabel.frame = CGRect(x: 20,
                                      y: 52 / 2 - (SettingsData.fontSize + 2) / 2,
                                      width: screenBounds.width - 20 - 60,
                                      height: SettingsData.fontSize + 2)
        
        self.addButton.frame = CGRect(x: screenBounds.width - 60,
                                      y: 8,
                                      width: 40,
                                      height: 40)
        
        self.removeButton.frame = CGRect(x: screenBounds.width - 60,
                                         y: 8,
                                         width: 40,
                                         height: 40)
    }
}
