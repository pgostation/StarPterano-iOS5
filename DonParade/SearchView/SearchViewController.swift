//
//  SearchViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/23.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 検索画面

import UIKit

final class SearchViewController: MyViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = SearchView()
        self.view = view
        
        view.closeButton.addTarget(self, action: #selector(self.closeAction), for: .touchUpInside)
        
        // 右スワイプで閉じる
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(closeAction))
        swipeGesture.direction = .right
        self.view?.addGestureRecognizer(swipeGesture)
    }
    
    @objc func closeAction() {
        if let view = view as? SearchView{
            view.textField.resignFirstResponder()
        }
        
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

private final class SearchView: UIView, UITextFieldDelegate {
    let closeButton = UIButton()
    let segmentControl = UISegmentedControl()
    let textField = UITextField()
    var tagTableView: TimeLineView?
    let accountTableView = FollowingTableView()
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        
        self.addSubview(accountTableView)
        self.addSubview(segmentControl)
        self.addSubview(textField)
        self.addSubview(closeButton)
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.backgroundColor = ThemeColor.viewBgColor
        
        // アカウント/トゥートの切り替え
        segmentControl.insertSegment(withTitle: I18n.get("SEARCH_SEG_TAG"), at: 0, animated: false)
        segmentControl.insertSegment(withTitle: I18n.get("SEARCH_SEG_ACCOUNT"), at: 1, animated: false)
        segmentControl.selectedSegmentIndex = 0
        segmentControl.tintColor = ThemeColor.nameColor
        segmentControl.backgroundColor = ThemeColor.cellBgColor
        
        // 検索文字列入力フィールド
        textField.backgroundColor = ThemeColor.cellBgColor
        textField.borderStyle = .line
        textField.textColor = ThemeColor.idColor
        textField.layer.borderWidth = 1
        textField.layer.borderColor = ThemeColor.dateColor.cgColor
        textField.returnKeyType = .search
        textField.delegate = self
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.textField.becomeFirstResponder()
        }
        
        // 閉じるボタン
        closeButton.setTitle(I18n.get("BUTTON_CLOSE"), for: .normal)
        closeButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        closeButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
        closeButton.layer.cornerRadius = 8
        closeButton.clipsToBounds = true
    }
    
    override func layoutSubviews() {
        segmentControl.frame = CGRect(x: UIScreen.main.bounds.width / 2 - 180 / 2 + 60,
                                      y: UIUtils.statusBarHeight() + 1,
                                      width: 180,
                                      height: 40)
        
        textField.frame = CGRect(x: 5,
                                 y: segmentControl.frame.maxY + 4,
                                 width: UIScreen.main.bounds.width - 10,
                                 height: 44)
        
        closeButton.frame = CGRect(x: UIScreen.main.bounds.width / 2 - 150,
                                   y: UIUtils.statusBarHeight() + 1,
                                   width: 90,
                                   height: 40)
        
        tagTableView?.frame = CGRect(x: 0,
                                     y: textField.frame.maxY + 2,
                                     width: UIScreen.main.bounds.width,
                                     height: UIScreen.main.bounds.height - (textField.frame.maxY + 2))
        
        accountTableView.frame = CGRect(x: 0,
                                        y: textField.frame.maxY + 2,
                                        width: UIScreen.main.bounds.width,
                                        height: UIScreen.main.bounds.height - (textField.frame.maxY + 2))
    }
    
    // テキストフィールドでリターン押した時の処理
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text else { return true }
        
        textField.resignFirstResponder()
        
        if segmentControl.selectedSegmentIndex == 0 {
            searchTag(text: text)
            
            self.tagTableView?.isHidden = false
            accountTableView.isHidden = true
        } else {
            searchAccounts(text: text)
            
            self.tagTableView?.isHidden = true
            accountTableView.isHidden = false
        }
        
        return true
    }
    
    // タグ検索
    private func searchTag(text: String) {
        self.tagTableView?.removeFromSuperview()
        
        self.tagTableView = TimeLineView(type: .federationTag, option: text, mentions: nil)
        self.addSubview(self.tagTableView!)
        self.setNeedsLayout()
    }
    
    // アカウント検索
    private var prevLinkStr: String?
    private func searchAccounts(text: String) {
        let waitIndicator = WaitIndicator()
        self.addSubview(waitIndicator)
        
        guard let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/accounts/search?q=\(text.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? "")") else { return }
        
        try? MastodonRequest.get(url: url) { (data, response, error) in
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
                
                DispatchQueue.main.async {
                    if !self.accountTableView.model.change(addList: list) {
                        // 重複したデータを受信したら、終了
                        self.accountTableView.model.showAutoPegerizeCell = false
                    }
                    self.accountTableView.reloadData()
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
                        if let data = data {
                            do {
                                guard let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: Any]] else { return }
                                
                                for json in responseJson {
                                    if let id = json["id"] as? String {
                                        self.accountTableView.model.relationshipList.updateValue(json, forKey: id)
                                    }
                                }
                                
                                DispatchQueue.main.async {
                                    self.accountTableView.reloadData()
                                }
                            } catch { }
                        }
                    }
                }
            } catch { }
            
            if let response = response as? HTTPURLResponse {
                if let linkStr = response.allHeaderFields["Link"] as? String {
                    if linkStr.contains("rel=\"prev\"") {
                        if let prefix = linkStr.split(separator: ">").first {
                            self.prevLinkStr = String(prefix.suffix(prefix.count - 1))
                        }
                    } else {
                        self.accountTableView.model.showAutoPegerizeCell = false
                    }
                } else {
                    self.accountTableView.model.showAutoPegerizeCell = false
                }
            }
        }
    }
}

private final class SearchTableView: UITableView {
    let model = SearchTableViewModel()
    
    init() {
        super.init(frame: UIScreen.main.bounds, style: UITableViewStyle.plain)
        
        self.delegate = model
        self.dataSource = model
        
        self.backgroundColor = ThemeColor.cellBgColor
        self.separatorStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class SearchTableViewModel: NSObject, UITableViewDataSource, UITableViewDelegate {
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func change(addList: [AnalyzeJson.ListData]) {
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)
    }
}
