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
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = ListSelectView()
        self.view = view
        
        view.closeButton.addTarget(self, action: #selector(self.closeAction), for: .touchUpInside)
        
        // 右スワイプで閉じる
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(closeAction))
        swipeGesture.direction = .right
        self.view?.addGestureRecognizer(swipeGesture)
    }
    
    @objc func closeAction() {
        self.dismiss(animated: true, completion: nil)
    }
}

private final class ListSelectView: UIView {
    let tableView = ListSelectTableView()
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
        closeButton.layer.cornerRadius = 10
        closeButton.clipsToBounds = true
        closeButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        closeButton.layer.borderWidth = 1
        
        closeButton.frame = CGRect(x: UIScreen.main.bounds.width / 2 - 50 / 2,
                                   y: UIScreen.main.bounds.height - 70,
                                   width: 50,
                                   height: 50)
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
        
        getLists()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func getLists() {
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
        let cell =  UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)
        
        let data = list[indexPath.row]
        
        cell.textLabel?.text = data.title
        
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
