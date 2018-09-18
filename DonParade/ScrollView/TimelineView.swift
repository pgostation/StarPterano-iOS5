//
//  TimelineView.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/16.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 各種タイムラインやお気に入りなどを表示するUITableView

import UIKit

final class TimeLineView: UITableView {
    private let type: TimeLineViewController.TimeLineType
    private let option: String?
    private let model = TimeLineViewModel()
    private let refreshCon = UIRefreshControl()
    
    var accountList: [String: AnalyzeJson.AccountData] = [:]
    
    init(type: TimeLineViewController.TimeLineType, option: String?) {
        self.type = type
        self.option = option
        
        super.init(frame: UIScreen.main.bounds, style: UITableViewStyle.plain)
        
        self.delegate = model
        self.dataSource = model
        
        self.separatorColor = UIColor.clear
        
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
        
        var sinceIdStr = ""
        if let id = model.getFirstTootId() {
            sinceIdStr = "&since_id=\(id)"
        }
        
        let url: URL?
        switch self.type {
        case .home:
            url = URL(string: "https://\(hostName)/api/v1/timelines/home?limit=200\(sinceIdStr)")
        case .local:
            url = URL(string: "https://\(hostName)/api/v1/timelines/public?local=1&limit=200\(sinceIdStr)")
        case .global:
            url = URL(string: "https://\(hostName)/api/v1/timelines/public?limit=200\(sinceIdStr)")
        case .user:
            guard let option = option else { return }
            url = URL(string: "https://\(hostName)/api/v1/accounts/\(option)/statuses?limit=200\(sinceIdStr)")
        case .favorites:
            url = URL(string: "https://\(hostName)/api/v1/favourites?limit=50\(sinceIdStr)")
        case .localTag:
            guard let option = option else { return }
            guard let encodedOption = option.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else { return }
            url = URL(string: "https://\(hostName)/api/v1/timelines/tag/\(encodedOption)?local=1&limit=200\(sinceIdStr)")
        case .globalTag:
            guard let option = option else { return }
            guard let encodedOption = option.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else { return }
            url = URL(string: "https://\(hostName)/api/v1/timelines/tag/\(encodedOption)?&limit=200\(sinceIdStr)")
        }
        
        guard let requestUrl = url else { return }
        
        try? MastodonRequest.get(url: requestUrl) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            if let data = data {
                do {
                    let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Array<AnyObject>
                    
                    DispatchQueue.main.async {
                        self?.refreshCon.endRefreshing()
                    }
                    
                    if let responseJson = responseJson {
                        AnalyzeJson.analyseJson(view: strongSelf, model: strongSelf.model, jsonList: responseJson)
                    }
                } catch {
                }
            } else if let error = error {
                print(error)
            }
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
        case .global:
            url = URL(string: "https://\(hostName)/api/v1/timelines/public?limit=50\(maxIdStr)")
        case .user:
            guard let option = option else { return }
            url = URL(string: "https://\(hostName)/api/v1/accounts/\(option)/statuses?limit=50\(maxIdStr)")
        case .favorites:
            url = URL(string: "https://\(hostName)/api/v1/favourites?limit=50\(maxIdStr)")
        case .localTag:
            guard let option = option else { return }
            guard let encodedOption = option.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else { return }
            url = URL(string: "https://\(hostName)/api/v1/timelines/tag/\(encodedOption)?local=1&limit=50\(maxIdStr)")
        case .globalTag:
            guard let option = option else { return }
            guard let encodedOption = option.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else { return }
            url = URL(string: "https://\(hostName)/api/v1/timelines/tag/\(encodedOption)?&limit=50\(maxIdStr)")
        }
        
        guard let requestUrl = url else { return }
        
        try? MastodonRequest.get(url: requestUrl) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            if let data = data {
                do {
                    let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Array<AnyObject>
                    
                    if let responseJson = responseJson {
                        AnalyzeJson.analyseJson(view: strongSelf, model: strongSelf.model, jsonList: responseJson)
                    }
                } catch {
                }
            } else if let error = error {
                print(error)
            }
        }
    }
}
