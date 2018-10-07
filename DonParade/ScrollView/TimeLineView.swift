
//
//  TimelineView.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/16.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 各種タイムラインやお気に入りなどを表示するUITableView

import UIKit
import SwiftyGif

final class TimeLineView: UITableView {
    let type: TimeLineViewController.TimeLineType
    let option: String?
    let model = TimeLineViewModel()
    private let refreshCon: UIRefreshControl
    private weak var waitIndicator: UIView?
    private static let tableDispatchQueue = DispatchQueue(label: "TimeLineView")
    private let accessToken = SettingsData.accessToken
    let gifManager = SwiftyGifManager(memoryLimit: 100)
    var mediaOnly: Bool = false
    
    var accountList: [String: AnalyzeJson.AccountData] = [:]
    
    init(type: TimeLineViewController.TimeLineType, option: String?, mentions: ([AnalyzeJson.ContentData], [String: AnalyzeJson.AccountData])?) {
        self.type = type
        self.option = option
        self.refreshCon = UIRefreshControl()
        
        super.init(frame: UIUtils.fullScreen(), style: UITableViewStyle.plain)
        
        self.delegate = model
        self.dataSource = model
        
        self.backgroundColor = ThemeColor.viewBgColor
        self.separatorStyle = .none
        
        if type != .mentions {
            // 引っ張って更新するやつを追加
            self.refreshCon.attributedTitle = NSAttributedString(string: I18n.get("REFRESH_TIMELINE"))
            self.refreshCon.addTarget(self, action: #selector(refresh), for: UIControlEvents.valueChanged)
            if #available(iOS 10.0, *) {
                self.refreshControl = self.refreshCon
            } else {
                self.backgroundView = self.refreshCon
            }
            
            let waitIndicator = WaitIndicator()
            self.waitIndicator = waitIndicator
            self.addSubview(waitIndicator)
        } else {
            // 会話表示
            self.model.showAutoPagerizeCell = false
            self.model.isDetailTimeline = true
            self.model.change(tableView: self, addList: mentions!.0, accountList: mentions!.1)
            self.model.selectedRow = 0
            DispatchQueue.main.async {
                // 古い物を取りに行く
                self.refresh()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // タイムラインを消去
    func clear() {
        self.model.clear()
    }
    
    // タイムラインを初回取得/手動更新
    @objc func refresh() {
        if self.waitingStatusList.count > 0 {
            DispatchQueue.main.async {
                self.refreshCon.endRefreshing()
                self.waitIndicator?.removeFromSuperview()
            }
            
            DispatchQueue.main.async {
                self.analyzeStremingData(string: nil)
            }
            
            // ストリーミングが停止していれば再開
            self.startStreaming(inRefresh: true)
            
            return
        }
        
        guard let hostName = SettingsData.hostName else { return }
        
        var sinceIdStr = ""
        if let id = model.getFirstTootId() {
            sinceIdStr = "&since_id=\(id)"
        }
        
        let url: URL?
        switch self.type {
        case .home:
            url = URL(string: "https://\(hostName)/api/v1/timelines/home?limit=100\(sinceIdStr)")
        case .local:
            url = URL(string: "https://\(hostName)/api/v1/timelines/public?local=1&limit=100\(sinceIdStr)")
        case .federation:
            url = URL(string: "https://\(hostName)/api/v1/timelines/public?limit=100\(sinceIdStr)")
        case .user:
            guard let option = option else { return }
            let mediaOnlyStr = mediaOnly ? "&only_media=1" : ""
            url = URL(string: "https://\(hostName)/api/v1/accounts/\(option)/statuses?limit=100\(sinceIdStr)\(mediaOnlyStr)")
        case .favorites:
            url = URL(string: "https://\(hostName)/api/v1/favourites?limit=50\(sinceIdStr)")
        case .localTag:
            guard let option = option else { return }
            guard let encodedOption = option.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else { return }
            url = URL(string: "https://\(hostName)/api/v1/timelines/tag/\(encodedOption)?local=1&limit=100\(sinceIdStr)")
        case .federationTag:
            guard let option = option else { return }
            guard let encodedOption = option.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else { return }
            url = URL(string: "https://\(hostName)/api/v1/timelines/tag/\(encodedOption)?&limit=100\(sinceIdStr)")
        case .mentions:
            guard let lastInReplyToId = model.getLastInReplyToId() else { return }
            url = URL(string: "https://\(hostName)/api/v1/statuses/\(lastInReplyToId)")
        case .direct:
            url = URL(string: "https://\(hostName)/api/v1/timelines/direct?limit=50\(sinceIdStr)")
        case .list:
            guard let listId = SettingsData.selectedListId(accessToken: SettingsData.accessToken) else {
                DispatchQueue.main.async {
                    self.refreshCon.endRefreshing()
                    self.waitIndicator?.removeFromSuperview()
                }
                return
            }
            url = URL(string: "https://\(hostName)/api/v1/timelines/list/\(listId)?limit=50\(sinceIdStr)")
        }
        
        guard let requestUrl = url else { return }
        
        try? MastodonRequest.get(url: requestUrl) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            DispatchQueue.main.async {
                self?.refreshCon.endRefreshing()
                self?.waitIndicator?.removeFromSuperview()
            }
            
            if let data = data {
                do {
                    if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [AnyObject] {
                        AnalyzeJson.analyzeJsonArray(view: strongSelf, model: strongSelf.model, jsonList: responseJson, isNew: true)
                    } else if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject] {
                        TimeLineView.tableDispatchQueue.async {
                            var acct = ""
                            let contentData = AnalyzeJson.analyzeJson(view: strongSelf, model: strongSelf.model, json: responseJson, acct: &acct)
                            let contentList = [contentData]
                            
                            strongSelf.model.change(tableView: strongSelf, addList: contentList, accountList: strongSelf.accountList)
                            
                            // 続きを取得
                            DispatchQueue.main.sync {
                                strongSelf.reloadData()
                                
                                if self?.type == .mentions {
                                    if contentData.in_reply_to_id == nil {
                                        return // ループ防止
                                    }
                                    strongSelf.refresh()
                                }
                            }
                        }
                    }
                } catch {
                }
            } else if let error = error {
                print(error)
            }
        }
        
        // ストリーミングが停止していれば再開
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.startStreaming()
        }
    }
    
    // ストリーミングを開始
    func startStreaming(inRefresh: Bool = false) {
        if !SettingsData.isStreamingMode { return }
        
        // 通知用にhomeのストリーミングを確認
        if self.type != .home {
            checkHomeStreaming()
        }
        
        if self.streamingObject?.isConnect != true {
            if self.type == .home {
                self.streaming(streamingType: "user")
            }
            else if self.type == .local {
                self.streaming(streamingType: "public:local")
            }
            else if self.type == .federation {
                self.streaming(streamingType: "public")
            }
            else {
                return
            }
            
            if !inRefresh {
                // 手動取得する
                refresh()
            }
        }
    }
    
    // 通知用にhomeのストリーミングを確認、接続
    private static var inChecking = false
    private func checkHomeStreaming() {
        if TimeLineView.inChecking { return }
        TimeLineView.inChecking = true
        
        guard let timelineList = MainViewController.instance?.timelineList else { return }
        
        let key = "\(SettingsData.hostName ?? "")_\(SettingsData.accessToken ?? "")_Home"
        if let homeTimelineViewController = timelineList[key] {
            (homeTimelineViewController.view as? TimeLineView)?.startStreaming()
        } else {
            let homeTimelineViewController = TimeLineViewController(type: .home)
            MainViewController.instance?.timelineList.updateValue(homeTimelineViewController, forKey: key)
            (homeTimelineViewController.view as? TimeLineView)?.startStreaming()
        }
        
        TimeLineView.inChecking = false
    }
    
    // ストリーミングを受信
    //   ホーム(通知含む)、ローカル、連合のみ
    private var streamingObject: MastodonStreaming?
    private var waitingStatusList: [AnalyzeJson.ContentData] = []
    @objc func streaming(streamingType: String) {
        guard let hostName = SettingsData.hostName else { return }
        guard let url = URL(string: "wss://\(hostName)/api/v1/streaming/?access_token=\(SettingsData.accessToken!)&stream=\(streamingType)") else { return }
        
        self.streamingObject = MastodonStreaming(url: url, callback: { [weak self] string in
            self?.analyzeStremingData(string: string)
        })
    }
    
    //
    private func analyzeStremingData(string: String?) {
        func update() {
            self.model.change(tableView: self, addList: self.waitingStatusList, accountList: self.accountList, isStreaming: true)
            self.waitingStatusList = []
            
            DispatchQueue.main.async {
                self.reloadData()
            }
        }
        
        if let data = string?.data(using: String.Encoding.utf8) {
            do {
                let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                
                guard let event = responseJson?["event"] as? String else { return }
                let payload = responseJson?["payload"]
                
                switch event {
                case "update":
                    if let string = payload as? String {
                        guard let json = try JSONSerialization.jsonObject(with: string.data(using: String.Encoding.utf8)!, options: .allowFragments) as? [String: Any] else { return }
                        TimeLineView.tableDispatchQueue.async {
                            var acct = ""
                            let statusData = AnalyzeJson.analyzeJson(view: self, model: self.model, json: json, acct: &acct)
                            
                            self.waitingStatusList.insert(statusData, at: 0)
                            
                            var offsetY: CGFloat = 0
                            DispatchQueue.main.sync {
                                offsetY = self.contentOffset.y
                            }
                            
                            if offsetY > 60 {
                                // スクロール位置が一番上でない場合、テーブルビューには反映せず裏に持っておく
                                return
                            }
                            
                            update()
                        }
                    }
                case "notification":
                    // 通知ボタンにマークをつけるだけ
                    MainViewController.instance?.markNotificationButton(accessToken: accessToken ?? "", to: true)
                case "delete":
                    if let deleteId = payload as? String {
                        // waitingStatusListからの削除
                        for (index, data) in waitingStatusList.enumerated() {
                            if deleteId == data.id {
                                waitingStatusList.remove(at: index)
                                return
                            }
                        }
                        
                        // 表示中のリストからの削除
                        self.model.delete(tableView: self, deleteId: deleteId)
                    }
                case "filters_changed":
                    break
                default:
                    break
                }
            } catch { }
        } else {
            update()
        }
    }
    
    // タイムラインに古いトゥートを追加
    func refreshOld(id: String?) {
        guard let hostName = SettingsData.hostName else { return }
        
        if id == nil { return }
        
        let maxIdStr = "&max_id=\(id ?? "")"
        
        let url: URL?
        switch self.type {
        case .home:
            url = URL(string: "https://\(hostName)/api/v1/timelines/home?limit=50\(maxIdStr)")
        case .local:
            url = URL(string: "https://\(hostName)/api/v1/timelines/public?local=1&limit=50\(maxIdStr)")
        case .federation:
            url = URL(string: "https://\(hostName)/api/v1/timelines/public?limit=50\(maxIdStr)")
        case .user:
            guard let option = option else { return }
            let mediaOnlyStr = mediaOnly ? "&only_media=1" : ""
            url = URL(string: "https://\(hostName)/api/v1/accounts/\(option)/statuses?limit=50\(maxIdStr)\(mediaOnlyStr)")
        case .favorites:
            url = URL(string: "https://\(hostName)/api/v1/favourites?limit=50\(maxIdStr)")
        case .localTag:
            guard let option = option else { return }
            guard let encodedOption = option.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else { return }
            url = URL(string: "https://\(hostName)/api/v1/timelines/tag/\(encodedOption)?local=1&limit=50\(maxIdStr)")
        case .federationTag:
            guard let option = option else { return }
            guard let encodedOption = option.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else { return }
            url = URL(string: "https://\(hostName)/api/v1/timelines/tag/\(encodedOption)?&limit=50\(maxIdStr)")
        case .mentions:
            return
        case .direct:
            url = URL(string: "https://\(hostName)/api/v1/timelines/direct?limit=50\(maxIdStr)")
        case .list:
            guard let listId = SettingsData.selectedListId(accessToken: SettingsData.accessToken) else {
                DispatchQueue.main.async {
                    self.refreshCon.endRefreshing()
                    self.waitIndicator?.removeFromSuperview()
                }
                return
            }
            url = URL(string: "https://\(hostName)/api/v1/timelines/list/\(listId)?limit=50\(maxIdStr)")
        }
        
        guard let requestUrl = url else { return }
        
        try? MastodonRequest.get(url: requestUrl) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            if let data = data {
                do {
                    let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Array<AnyObject>
                    
                    if let responseJson = responseJson {
                        TimeLineView.tableDispatchQueue.async {
                            // ループ防止
                            if responseJson.count == 0 {
                                strongSelf.model.showAutoPagerizeCell = false
                            }
                            
                            AnalyzeJson.analyzeJsonArray(view: strongSelf, model: strongSelf.model, jsonList: responseJson, isNew: false)
                            
                        }
                    }
                } catch {
                }
            } else if let error = error {
                print(error)
            }
        }
    }
    
    // お気に入りにする/解除する
    func favoriteAction(id: String, isFaved: Bool) {
        guard let hostName = SettingsData.hostName else { return }
        
        let url: URL
        if isFaved {
            url = URL(string: "https://\(hostName)/api/v1/statuses/\(id)/unfavourite")!
        } else {
            url = URL(string: "https://\(hostName)/api/v1/statuses/\(id)/favourite")!
        }
        
        try? MastodonRequest.post(url: url, body: [:]) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            if let data = data {
                do {
                    if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject] {
                        var acct = ""
                        let contentData = AnalyzeJson.analyzeJson(view: strongSelf, model: strongSelf.model, json: responseJson, acct: &acct)
                        let contentList = [contentData]
                        
                        DispatchQueue.main.async {
                            strongSelf.model.change(tableView: strongSelf, addList: contentList, accountList: [:])
                        }
                    }
                } catch {
                    
                }
            }
        }
    }
    
    // ブーストする/解除する
    func boostAction(id: String, isBoosted: Bool) {
        guard let hostName = SettingsData.hostName else { return }
        
        let url: URL
        if isBoosted {
            url = URL(string: "https://\(hostName)/api/v1/statuses/\(id)/unreblog")!
        } else {
            url = URL(string: "https://\(hostName)/api/v1/statuses/\(id)/reblog")!
        }
        
        try? MastodonRequest.post(url: url, body: [:]) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            if let data = data {
                do {
                    if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject] {
                        var acct = ""
                        let contentData = AnalyzeJson.analyzeJson(view: strongSelf, model: strongSelf.model, json: responseJson, acct: &acct)
                        let contentList = [contentData]
                        
                        DispatchQueue.main.async {
                            strongSelf.model.change(tableView: strongSelf, addList: contentList, accountList: [:], isBoosted: true)
                        }
                    }
                } catch {
                    
                }
            }
        }
    }
    
    // ミニビューにする
    func enterMiniView() {
        switch SettingsData.isMiniView {
        case .normal:
            SettingsData.isMiniView = .miniView
        case .miniView:
            SettingsData.isMiniView = .superMini
        case .superMini:
            break
        }
        
        self.reloadData()
    }
    
    // ミニビューを解除する
    func exitMiniView() {
        switch SettingsData.isMiniView {
        case .normal:
            break
        case .miniView:
            SettingsData.isMiniView = .normal
        case .superMini:
            SettingsData.isMiniView = .miniView
        }
        
        self.reloadData()
    }
    
    // タッチしている間ボタンを隠す
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        MainViewController.instance?.hideButtons()
    }
}
