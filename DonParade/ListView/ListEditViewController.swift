//
//  ListEditViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/10/04.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit

final class ListEditViewController: MyViewController {
    private let name: String
    private let id: String
    
    init(name: String?, id: String) {
        self.name = name ?? ""
        self.id = id
        
        super.init(nibName: nil, bundle: nil)
        
        self.modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = ListEditView(name: self.name, id: self.id)
        self.view = view
        
        view.searchButton.addTarget(self, action: #selector(self.searchAction), for: .touchUpInside)
        view.closeButton.addTarget(self, action: #selector(self.closeAction), for: .touchUpInside)
        
        // 右スワイプで閉じる
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(closeAction))
        swipeGesture.direction = .right
        self.view?.addGestureRecognizer(swipeGesture)
    }
    
    // ユーザーの検索ボタン
    @objc func searchAction() {
        Dialog.showWithTextInput(message: I18n.get("LIST_SEARCH_ACCOUNT"),
                                 okName: I18n.get("BUTTON_SEARCH"),
                                 cancelName: I18n.get("BUTTON_CANCEL"),
                                 defaultText: nil) { (textField, result) in
                                    if !result || textField.text == nil { return }
                                    self.searchUser(text: textField.text!)
        }
    }
    
    // ユーザーの検索処理
    private func searchUser(text: String) {
        guard let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/accounts/search?following=1&q=\(text.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? "")") else { return }
        
        try? MastodonRequest.get(url: url) { [weak self] (data, response, error) in
            guard let data = data else { return }
            
            do {
                guard let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Array<AnyObject> else { return }
                
                var list: [AnalyzeJson.AccountData] = []
                for json in responseJson {
                    if let accountJson = json as? [String: Any] {
                        let accountData = AnalyzeJson.analyzeAccountJson(account: accountJson)
                        list.append(accountData)
                    }
                }
                
                /* リストに自分は追加できなかった
                let myName = SettingsData.accountUsername(accessToken: SettingsData.accessToken ?? "")
                if text == myName {
                    let myData = AnalyzeJson.AccountData(acct: nil,
                                                         avatar: nil,
                                                         avatar_static: SettingsData.accountIconUrl(accessToken: SettingsData.accessToken ?? ""),
                                                         bot: nil,
                                                         created_at: nil,
                                                         display_name: myName,
                                                         emojis: nil,
                                                         fields: nil,
                                                         followers_count: nil,
                                                         following_count: nil,
                                                         header: nil,
                                                         header_static: nil,
                                                         id: SettingsData.accountNumberID(accessToken: SettingsData.accessToken ?? ""),
                                                         locked: nil,
                                                         note: nil,
                                                         statuses_count: nil,
                                                         url: nil,
                                                         username: nil)
                    list.append(myData)
                }*/
                
                DispatchQueue.main.async {
                    if let view = self?.view as? ListEditView {
                        view.tableView.model.searchList = list
                        view.tableView.model.isSearched = true
                        view.tableView.reloadData()
                    }
                }
            } catch { }
        }
    }
    
    @objc func closeAction() {
        UIView.animate(withDuration: 0.3, animations: {
            self.view.frame.origin.x = UIScreen.main.bounds.width
        }, completion: { _ in
            self.removeFromParent()
            self.view.removeFromSuperview()
        })
    }
}

private final class ListEditView: UIView {
    let name: String
    let tableView: ListEditTableView
    let closeButton = UIButton()
    let titleLabel = UILabel()
    let searchButton = UIButton()
    
    init(name: String, id: String) {
        self.name = name
        self.tableView = ListEditTableView(id: id)
        
        super.init(frame: UIScreen.main.bounds)
        
        self.addSubview(tableView)
        self.addSubview(searchButton)
        self.addSubview(titleLabel)
        self.addSubview(closeButton)
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.backgroundColor = ThemeColor.viewBgColor
        
        // 検索ボタン
        searchButton.setTitle("＋", for: .normal)
        searchButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        searchButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        searchButton.backgroundColor = ThemeColor.mainButtonsBgColor
        searchButton.layer.cornerRadius = 10
        searchButton.clipsToBounds = true
        searchButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        searchButton.layer.borderWidth = 1
        
        // 閉じるボタン
        closeButton.setTitle("×", for: .normal)
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        closeButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        closeButton.backgroundColor = ThemeColor.mainButtonsBgColor
        closeButton.layer.cornerRadius = 10
        closeButton.clipsToBounds = true
        closeButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        closeButton.layer.borderWidth = 1
        
        // タイトル
        titleLabel.text = self.name
        titleLabel.textAlignment = .center
        titleLabel.textColor = ThemeColor.idColor
    }
    
    override func layoutSubviews() {
        let screenBounds = UIScreen.main.bounds
        
        titleLabel.frame = CGRect(x: screenBounds.width / 2 - 100 / 2,
                                  y: UIUtils.statusBarHeight(),
                                  width: 100,
                                  height: 40)
        
        searchButton.frame = CGRect(x: screenBounds.width - 50,
                                    y: UIUtils.statusBarHeight(),
                                    width: 40,
                                    height: 40)
        
        closeButton.frame = CGRect(x: screenBounds.width / 2 - 50 / 2,
                                   y: screenBounds.height - (UIUtils.isIphoneX ? 110 : 70),
                                   width: 50,
                                   height: 50)
        
        tableView.frame = CGRect(x: 0,
                                 y: UIUtils.statusBarHeight() + 42,
                                 width: screenBounds.width,
                                 height: screenBounds.height - (UIUtils.statusBarHeight() + 42))
    }
}

private final class ListEditTableView: UITableView {
    let model: ListEditTableModel
    
    init(id: String) {
        self.model = ListEditTableModel(listId: id)
        
        super.init(frame: UIScreen.main.bounds, style: UITableView.Style.plain)
        
        self.delegate = model
        self.dataSource = model
        
        self.backgroundColor = ThemeColor.cellBgColor
        self.separatorStyle = .none
        
        self.rowHeight = 52
        
        getListAccounts(id: id)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // リストに含まれるアカウントを取得
    private func getListAccounts(id: String) {
        let waitIndicator = WaitIndicator()
        self.addSubview(waitIndicator)
        
        guard let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/lists/\(id)/accounts") else { return }
        
        try? MastodonRequest.get(url: url) { [weak self] (data, response, error) in
            DispatchQueue.main.async {
                waitIndicator.removeFromSuperview()
            }
            
            guard let data = data else { return }
            
            do {
                guard let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Array<AnyObject> else { return }
                
                var list: [AnalyzeJson.AccountData] = []
                for json in responseJson {
                    if let accountJson = json as? [String: Any] {
                        let accountData = AnalyzeJson.analyzeAccountJson(account: accountJson)
                        list.append(accountData)
                    }
                }
                
                // ID順にソートする
                list.sort(by: { (data1, data2) -> Bool in
                    (data1.acct ?? "").lowercased() < (data2.acct ?? "").lowercased()
                })
                
                DispatchQueue.main.async {
                    self?.model.list = list
                    self?.reloadData()
                }
            } catch { }
        }
    }
}

private final class ListEditTableModel: NSObject, UITableViewDataSource, UITableViewDelegate {
    var searchList: [AnalyzeJson.AccountData] = []
    var list: [AnalyzeJson.AccountData] = []
    var isSearched = false
    let listId: String
    
    init(listId: String) {
        self.listId = listId
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearched {
            return searchList.count + 2
        } else {
            return list.count + 2
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let list: [AnalyzeJson.AccountData]
        if isSearched {
            list = self.searchList
        } else {
            list = self.list
        }
        
        if indexPath.row >= list.count {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.backgroundColor = ThemeColor.cellBgColor
            return cell
        }
        
        let reuseIdentifier = "ListEditTableViewCell"
        let cell = (tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? ListEditTableViewCell) ?? ListEditTableViewCell(reuseIdentifier: reuseIdentifier)
        
        let data = list[indexPath.row]
        
        cell.listId = self.listId
        cell.id = data.id ?? ""
        
        cell.nameLabel.attributedText = DecodeToot.decodeName(name: data.display_name, emojis: data.emojis) {
            if cell.id != data.id { return }
            cell.nameLabel.attributedText = DecodeToot.decodeName(name: data.display_name, emojis: data.emojis) {}
        }
        
        cell.idLabel.text = data.acct
        
        cell.iconView.image = nil
        ImageCache.image(urlStr: data.avatar_static, isTemp: false, isSmall: true) { image in
            if cell.id == data.id {
                cell.iconView.image = image
                cell.iconView.layer.cornerRadius = 5
                cell.iconView.clipsToBounds = true
            }
        }
        
        if isSearched {
            cell.addButton.isHidden = false
            cell.removeButton.isHidden = true
            
            for exitstData in self.list {
                if data.id == exitstData.id {
                    cell.addButton.isHidden = true
                    cell.removeButton.isHidden = true
                }
            }
        } else {
            cell.addButton.isHidden = true
            cell.removeButton.isHidden = false
        }
        
        return cell
    }
}
