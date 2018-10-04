//
//  ListSelectViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/23.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// リスト選択画面

import UIKit

final class ListSelectViewController: MyViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        
        self.modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = ListSelectView()
        self.view = view
        
        view.createButton.addTarget(self, action: #selector(self.createAction), for: .touchUpInside)
        view.closeButton.addTarget(self, action: #selector(self.closeAction), for: .touchUpInside)
        
        // 右スワイプで閉じる
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(closeAction))
        swipeGesture.direction = .right
        self.view?.addGestureRecognizer(swipeGesture)
    }
    
    // リストの新規作成 (名前入力ダイアログを表示)
    @objc func createAction() {
        Dialog.showWithTextInput(message: I18n.get("リスト名"),
                                 okName: "作成",
                                 cancelName: "キャンセル",
                                 defaultText: nil) { (textField, result) in
                                    if !result { return }
                                    
                                    if let text = textField.text {
                                        self.createList(name: text)
                                    }
        }
    }
    
    // リストの新規作成のリクエストを投げる
    private func createList(name: String) {
        let waitIndicator = WaitIndicator()
        self.view.addSubview(waitIndicator)
        
        guard let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/lists") else { return }
        
        try? MastodonRequest.post(url: url, body: ["title": name]) { [weak self] (data, response, error) in
            DispatchQueue.main.async {
                waitIndicator.removeFromSuperview()
            }
            
            (self?.view as? ListSelectView)?.tableView.getLists(force: true)
        }
    }
    
    @objc func closeAction() {
        self.dismiss(animated: true, completion: nil)
    }
}

private final class ListSelectView: UIView {
    let tableView = ListSelectTableView()
    let closeButton = UIButton()
    let createButton = UIButton()
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        
        self.addSubview(tableView)
        self.addSubview(createButton)
        self.addSubview(closeButton)
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.backgroundColor = ThemeColor.viewBgColor
        
        // 作成ボタン
        createButton.setTitle(I18n.get("BUTTON_CREATE_LIST"), for: .normal)
        createButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        createButton.backgroundColor = ThemeColor.mainButtonsBgColor
        createButton.layer.cornerRadius = 10
        createButton.clipsToBounds = true
        createButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        createButton.layer.borderWidth = 1
        
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
        
        createButton.frame = CGRect(x: screenBounds.width / 2 - 150 / 2,
                                    y: UIUtils.statusBarHeight(),
                                    width: 150,
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

private final class ListSelectTableView: UITableView {
    let model = ListSelectTableModel()
    
    init() {
        super.init(frame: UIScreen.main.bounds, style: UITableViewStyle.plain)
        
        self.delegate = model
        self.dataSource = model
        
        self.backgroundColor = ThemeColor.cellBgColor
        self.separatorStyle = .none
        
        self.rowHeight = 52
        
        getLists()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // リスト一覧を取得
    func getLists(force: Bool = false) {
        // キャッシュがあれば使う
        if !force, let cache = ListData.getCache(accessToken: SettingsData.accessToken ?? "") {
            DispatchQueue.main.async {
                self.model.list = cache
                self.reloadData()
            }
            return
        }
        
        let waitIndicator = WaitIndicator()
        self.addSubview(waitIndicator)
        
        guard let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/lists") else { return }
        
        try? MastodonRequest.get(url: url) { [weak self] (data, response, error) in
            DispatchQueue.main.async {
                waitIndicator.removeFromSuperview()
            }
            
            if let data = data {
                do {
                    if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: AnyObject]] {
                        var list: [AnalyzeJson.ListData] = []
                        for listJson in responseJson {
                            let data = AnalyzeJson.ListData(id: listJson["id"] as? String,
                                                            title: listJson["title"] as? String)
                            list.append(data)
                        }
                        
                        if let accessToken = SettingsData.accessToken {
                            ListData.setCache(accessToken: accessToken, value: list)
                        }
                        
                        DispatchQueue.main.async {
                            self?.model.list = list
                            self?.reloadData()
                        }
                    }
                } catch {
                    
                }
            }
        }
    }
}

private final class ListSelectTableModel: NSObject, UITableViewDataSource, UITableViewDelegate {
    var list: [AnalyzeJson.ListData] = []
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "ListSelectTableViewCell"
        let cell = (tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? ListSelectTableViewCell) ?? ListSelectTableViewCell(reuseIdentifier: reuseIdentifier)
        
        let data = list[indexPath.row]
        
        cell.nameLabel.text = data.title
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = list[indexPath.row]
        
        if let vc = UIUtils.getFrontViewController() as? ListSelectViewController {
            vc.closeAction()
            
            DispatchQueue.main.async {
                SettingsData.selectListId(accessToken: SettingsData.accessToken, listId: data.id)
                MainViewController.instance?.showListTL()
            }
        }
    }
}
