//
//  TimelineView.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/16.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit

final class TimeLineView: UITableView {
    private let type: TimeLineViewController.TimeLineType
    private let option: String?
    private let model = TimeLineViewModel()
    private let refreshCon = UIRefreshControl()
    
    private var accountList: [String: AccountData] = [:]
    
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
                        self?.analyseJson(jsonList: responseJson)
                    }
                } catch {
                }
            } else if let error = error {
                print(error)
            }
        }
    }
    
    // タイムラインのJSONデータを解析して、リストに格納
    private func analyseJson(jsonList: [AnyObject]) {
        var contentList: [ContentData] = []
        
        var acct: String = ""
        for json in jsonList {
            guard let json = json as? [String: Any] else { continue }
            
            if let account = json["account"] as? [String: Any] {
                acct = account["acct"] as? String ?? ""
                let avatar = account["acct"] as? String
                let avatar_static = account["avatar_static"] as? String
                let bot = account["bot"] as? Int
                let created_at = account["created_at"] as? String
                let display_name = account["display_name"] as? String
                let emojis = account["emojis"] as? [[String: Any]]
                let fields = account["fields"] as? [[String: Any]]
                let followers_count = account["followers_count"] as? Int
                let following_count = account["following_count"] as? Int
                let header = account["header"] as? String
                let header_static = account["header_static"] as? String
                let id = account["id"] as? Int
                let locked = account["locked"] as? Int
                let note = account["note"] as? String
                let statuses_count = account["statuses_count"] as? Int
                let url = account["url"] as? String
                let username = account["username"] as? String
                
                let data = AccountData(acct: acct,
                                       avatar: avatar,
                                       avatar_static: avatar_static,
                                       bot: bot,
                                       created_at: created_at,
                                       display_name: display_name,
                                       emojis: emojis,
                                       fields: fields,
                                       followers_count: followers_count,
                                       following_count: following_count,
                                       header: header,
                                       header_static: header_static,
                                       id: id,
                                       locked: locked,
                                       note: note,
                                       statuses_count: statuses_count,
                                       url: url,
                                       username: username)
                self.accountList.updateValue(data, forKey: acct)
            }
            let content = json["content"] as? String
            let created_at = json["created_at"] as? String
            let emojis = json["emojis"] as? [[String: Any]]
            let favourited = json["favourited"] as? Int
            let favourites_count = json["favourites_count"] as? Int
            let id = json["id"] as? Int
            let in_reply_to_account_id = json["in_reply_to_account_id"] as? String
            let in_reply_to_id = json["in_reply_to_account_id"] as? String
            let language = json["language"] as? String
            let media_attachments = json["media_attachments"] as? [String]
            let mentions = json["mentions"] as? [String]
            let muted = json["muted"] as? Int
            let reblog = json["reblog"] as? String
            let reblogged = json["reblogged"] as? Int
            let reblogs_count = json["reblogs_count"] as? Int
            let replies_count = json["replies_count"] as? Int
            let sensitive = json["sensitive"] as? Int
            let spoiler_text = json["spoiler_text"] as? String
            let tags = json["tags"] as? [String]
            let uri = json["uri"] as? String
            let url = json["url"] as? String
            let visibility = json["visibility"] as? String
            
            let data = ContentData(accountId: acct,
                                   content: content,
                                   created_at: created_at,
                                   emojis: emojis,
                                   favourited: favourited,
                                   favourites_count: favourites_count,
                                   id: id,
                                   in_reply_to_account_id: in_reply_to_account_id,
                                   in_reply_to_id: in_reply_to_id,
                                   language: language,
                                   media_attachments: media_attachments,
                                   mentions: mentions,
                                   muted: muted,
                                   reblog: reblog,
                                   reblogged: reblogged,
                                   reblogs_count: reblogs_count,
                                   replies_count: replies_count,
                                   sensitive: sensitive,
                                   spoiler_text: spoiler_text,
                                   tags: tags,
                                   uri: uri,
                                   url: url,
                                   visibility: visibility)
            contentList.append(data)
        }
        
        model.change(tableView: self, addList: contentList, accountList: self.accountList)
    }
    
    struct AccountData {
        let acct: String?
        let avatar: String?
        let avatar_static: String?
        let bot: Int?
        let created_at: String?
        let display_name: String?
        let emojis: [[String: Any]]?
        let fields: [[String: Any]]?
        let followers_count: Int?
        let following_count: Int?
        let header: String?
        let header_static: String?
        let id: Int?
        let locked: Int?
        let note: String?
        let statuses_count: Int?
        let url: String?
        let username: String?
    }
    
    struct ContentData {
        let accountId: String
        let content: String?
        let created_at: String?
        let emojis: [[String: Any]]?
        let favourited: Int?
        let favourites_count: Int?
        let id: Int?
        let in_reply_to_account_id: String?
        let in_reply_to_id: String?
        let language: String?
        let media_attachments: [String]?
        let mentions: [String]?
        let muted: Int?
        let reblog: String?
        let reblogged: Int?
        let reblogs_count: Int?
        let replies_count: Int?
        let sensitive: Int?
        let spoiler_text: String?
        let tags: [String]?
        let uri: String?
        let url: String?
        let visibility: String?
    }
}

private final class TimeLineViewModel: NSObject, UITableViewDataSource, UITableViewDelegate {
    private var list: [TimeLineView.ContentData] = []
    private var accountList: [String: TimeLineView.AccountData] = [:]
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func change(tableView: UITableView, addList: [TimeLineView.ContentData], accountList: [String: TimeLineView.AccountData]) {
        DispatchQueue.main.async {
            self.list += addList
            
            self.accountList = accountList
            
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let cell = self.tableView(tableView, cellForRowAt: indexPath) as? TimeLineViewCell else { return 60 }
        
        return cell.messageView.frame.height + 14
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = getCell(view: tableView)
        
        if indexPath.row >= list.count { return cell }
        let data = list[indexPath.row]
        let account = accountList[data.accountId]
        
        ImageCache.image(urlStr: account?.avatar_static) { image in
            cell.iconView.image = image
            cell.iconView.layer.cornerRadius = 22
            cell.iconView.clipsToBounds = true
        }
        
        cell.messageView.text = data.content
        cell.messageView.font = UIFont.systemFont(ofSize: 16)
        cell.messageView.frame.size.width = UIScreen.main.bounds.width - 56
        cell.messageView.sizeToFit()
        if cell.messageView.frame.size.height >= 140 - 14 {
            cell.messageView.frame.size.height = 140 - 14
        }
        
        cell.nameLabel.text = account?.display_name
        cell.nameLabel.font = UIFont.boldSystemFont(ofSize: 13)
        cell.nameLabel.sizeToFit()
        
        cell.idLabel.text = account?.acct
        cell.idLabel.font = UIFont.systemFont(ofSize: 13)
        cell.idLabel.textColor = UIColor.darkGray
        cell.idLabel.sizeToFit()
        
        cell.dateLabel.text = data.created_at
        cell.dateLabel.font = UIFont.systemFont(ofSize: 13)
        cell.dateLabel.textAlignment = .right
        
        return cell
    }
    
    // セルを使い回す
    private func getCell(view: UITableView) -> TimeLineViewCell {
        let reuseIdentifier = "TimeLineViewModel"
        let cell = view.dequeueReusableCell(withIdentifier: reuseIdentifier) as? TimeLineViewCell ?? TimeLineViewCell(reuseIdentifier: reuseIdentifier)
        return cell
    }
}

private final class TimeLineViewCell: UITableViewCell {
    let iconView = UIImageView()
    let nameLabel = UILabel()
    let idLabel = UILabel()
    let dateLabel = UILabel()
    let messageView = UITextView()
    
    init(reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        
        self.textLabel?.removeFromSuperview()
        self.detailTextLabel?.removeFromSuperview()
        
        self.addSubview(self.iconView)
        self.addSubview(self.nameLabel)
        self.addSubview(self.idLabel)
        self.addSubview(self.dateLabel)
        self.addSubview(self.messageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        self.iconView.frame = CGRect(x: 6,
                                     y: 6,
                                     width: 44,
                                     height: 44)
        
        self.nameLabel.frame = CGRect(x: 50,
                                      y: 0,
                                      width: self.nameLabel.frame.width,
                                      height: 16)
        
        self.idLabel.frame = CGRect(x: 50 + self.nameLabel.frame.width + 5,
                                    y: 0,
                                    width: self.idLabel.frame.width,
                                    height: 16)
        
        self.dateLabel.frame = CGRect(x: UIScreen.main.bounds.width - 100,
                                      y: 0,
                                      width: 100,
                                      height: 16)
        
        self.messageView.frame = CGRect(x: 50,
                                        y: 14,
                                        width: self.messageView.frame.width,
                                        height: self.messageView.frame.height)
    }
}
