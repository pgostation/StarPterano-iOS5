//
//  TimeLineViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/15.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit

final class TimeLineViewController: MyViewController {
    enum TimeLineType {
        case home // ホーム
        case local // ローカルタイムライン
        case global // 連合タイムライン
        case user // 指定ユーザータイムライン
        case favorites // お気に入り
        case localTag
        case globalTag
    }
    
    private let type: TimeLineType
    private let option: String? // user指定時はユーザID、タグ指定時はタグ
    
    init(type: TimeLineType, option: String? = nil) {
        self.type = type
        self.option = option
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = TimeLineView(type: self.type, option: self.option)
        self.view = view
    }
}

private final class TimeLineView: UITableView {
    private let type: TimeLineViewController.TimeLineType
    private let option: String?
    private let model = TimeLineViewModel()
    private let refreshCon = UIRefreshControl()
    
    init(type: TimeLineViewController.TimeLineType, option: String?) {
        self.type = type
        self.option = option
        
        super.init(frame: UIScreen.main.bounds, style: UITableViewStyle.plain)
        
        self.delegate = model
        self.dataSource = model
        
        // 引っ張って更新するやつを追加
        self.refreshCon.attributedTitle = NSAttributedString(string: I18n.get("REFRESH_TIMELINE"))
        self.refreshCon.addTarget(self, action: #selector(refresh), for: UIControlEvents.valueChanged)
        if #available(iOS 10.0, *) {
            self.refreshControl = self.refreshCon
        } else {
            self.backgroundView = self.refreshCon
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // タイムラインを更新
    @objc func refresh() {
        guard let hostName = SettingsData.hostName else { return }
        
        let url: URL?
        switch self.type {
        case .home:
            url = URL(string: "https://\(hostName)/api/v1/timelines/home?limit=50")
        case .local:
            url = URL(string: "https://\(hostName)/api/v1/timelines/public?local=&limit=50")
        case .global:
            url = URL(string: "https://\(hostName)/api/v1/timelines/public?limit=50")
        case .user:
            guard let option = option else { return }
            url = URL(string: "https://\(hostName)/api/v1/accounts/\(option)/statuses?limit=50")
        case .favorites:
            url = URL(string: "https://\(hostName)/api/v1/favourites?limit=50")
        case .localTag:
            guard let option = option else { return }
            guard let encodedOption = option.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else { return }
            url = URL(string: "https://\(hostName)/api/v1/timelines/tag/\(encodedOption)?local=&limit=50")
        case .globalTag:
            guard let option = option else { return }
            guard let encodedOption = option.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else { return }
            url = URL(string: "https://\(hostName)/api/v1/timelines/tag/\(encodedOption)?local=&limit=50")
        }
        
        guard let requestUrl = url else { return }
        
        try? MastodonRequest.get(url: requestUrl) { [weak self] (data, response, error) in
            if let data = data {
                do {
                    let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Array<AnyObject>
                    
                    DispatchQueue.main.async {
                        self?.refreshCon.endRefreshing()
                    }
                    
                    if let responseJson = responseJson {
                        self?.analyseJson(json: responseJson)
                        print("#### responseJson3=\(responseJson)")
                    }
                } catch {
                }
            } else if let error = error {
                print(error)
            }
        }
    }
    
    // タイムラインのJSONデータを解析して、リストに格納
    private func analyseJson(json: Array<AnyObject>) {
        
    }
}

private final class TimeLineViewModel: NSObject, UITableViewDataSource, UITableViewDelegate {
    private var list: [Date: TootStruct] = [:]
    private var sortedKeys: [Date] = []
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func change(tableView: UITableView, addList: [Date: TootStruct]) {
        for data in addList {
            var time = data.key
            while list.keys.contains(time) {
                time = time.addingTimeInterval(0.001)
            }
            list.updateValue(data.value, forKey: time)
        }
        
        // 日付順にキーをソートして保持
        sortedKeys = list.keys.sorted().reversed()
        
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = getCell(view: tableView)
        
        if indexPath.row >= sortedKeys.count { return cell }
        
        let key = sortedKeys[indexPath.row]
        guard let data = list[key] else { return cell }
        
        cell.textLabel?.text = data.text
        cell.detailTextLabel?.text = data.id
        
        return cell
    }
    
    // セルを使い回す
    private func getCell(view: UITableView) -> UITableViewCell {
        let reuseIdentifier = "TimeLineViewModel"
        let cell = view.dequeueReusableCell(withIdentifier: reuseIdentifier) ?? UITableViewCell.init(style: UITableViewCellStyle.subtitle, reuseIdentifier: reuseIdentifier)
        return cell
        
    }
}

// トゥート構造体
struct TootStruct {
    let id: String
    let text: String
}
