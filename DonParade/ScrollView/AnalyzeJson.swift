//
//  AnalyzeJson.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/17.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// タイムラインのJSON文字列を解析して、構造体に格納する

import Foundation

final class AnalyzeJson {
    // タイムラインのJSONデータを解析して、リストに格納
    static func analyseJsonArray(view: TimeLineView, model: TimeLineViewModel, jsonList: [AnyObject]) {
        var contentList: [ContentData] = []
        
        var acct: String = ""
        for json in jsonList {
            guard let json = json as? [String: Any] else { continue }
            
            let data = analyseJson(view: view, model: model, json: json, acct: &acct)
            
            contentList.append(data)
        }
        
        model.change(tableView: view, addList: contentList, accountList: view.accountList)
    }
    
    static func analyseJson(view: TimeLineView, model: TimeLineViewModel, json: [String: Any], acct: inout String) -> ContentData {
        if let account = json["account"] as? [String: Any] {
            acct = account["acct"] as? String ?? ""
            let data = analyzeAccountJson(account: account)
            view.accountList.updateValue(data, forKey: acct)
        }
        let reblog = json["reblog"] as? [String: Any]
        var reblog_acct: String? = nil
        if let account = reblog?["account"] as? [String: Any] {
            reblog_acct = acct
            acct = account["acct"] as? String ?? ""
            let data = analyzeAccountJson(account: account)
            view.accountList.updateValue(data, forKey: acct)
        }
        var mediaData: [MediaData]? = nil
        if let media_attachments = json["media_attachments"] as? [[String: Any]] {
            for media_attachment in media_attachments {
                let id = media_attachment["id"] as? Int64
                let preview_url = media_attachment["preview_url"] as? String
                let url = media_attachment["url"] as? String
                let type = media_attachment["type"] as? String
                
                let data = MediaData(id: id,
                                     preview_url: preview_url,
                                     type: type,
                                     url: url)
                if mediaData == nil {
                    mediaData = []
                }
                mediaData?.append(data)
            }
        }
        var mentions: [MensionData]? = nil
        if let mentionsJson = json["mentions"] as? [[String: Any]] {
            for json in mentionsJson {
                let acct = json["acct"] as? String
                let id = json["id"] as? String
                let url = json["url"] as? String
                let username = json["username"] as? String
                
                let data = MensionData(acct: acct,
                                       id: id,
                                       url: url,
                                       username: username)
                if mentions == nil {
                    mentions = []
                }
                mentions?.append(data)
            }
        }
        let application = json["application"] as? [String: Any]
        let content = json["content"] as? String
        let created_at = json["created_at"] as? String
        let emojis = json["emojis"] as? [[String: Any]]
        let favourited = json["favourited"] as? Int
        let favourites_count = json["favourites_count"] as? Int
        let id = json["id"] as? String
        let in_reply_to_account_id = json["in_reply_to_account_id"] as? String
        let in_reply_to_id = json["in_reply_to_id"] as? String
        let language = json["language"] as? String
        let muted = json["muted"] as? Int
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
                               application: application,
                               content: content,
                               created_at: created_at,
                               emojis: emojis,
                               favourited: favourited,
                               favourites_count: favourites_count,
                               id: id,
                               in_reply_to_account_id: in_reply_to_account_id,
                               in_reply_to_id: in_reply_to_id,
                               language: language,
                               mediaData: mediaData,
                               mentions: mentions,
                               muted: muted,
                               reblog_acct: reblog_acct,
                               reblogged: reblogged,
                               reblogs_count: reblogs_count,
                               replies_count: replies_count,
                               sensitive: sensitive,
                               spoiler_text: spoiler_text,
                               tags: tags,
                               uri: uri,
                               url: url,
                               visibility: visibility)
        return data
    }
    
    static func analyzeAccountJson(account: [String: Any]) -> AccountData {
        let acct = account["acct"] as? String ?? ""
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
        let id = account["id"] as? String
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
        return data
    }
    
    // トゥートした人の情報 (あるいはブーストした人)
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
        let id: String? // 数値のID
        let locked: Int?
        let note: String?
        let statuses_count: Int?
        let url: String?
        let username: String?
    }
    
    // トゥート内容
    struct ContentData {
        let accountId: String
        let application: [String: Any]?
        let content: String?
        let created_at: String?
        let emojis: [[String: Any]]?
        let favourited: Int?
        let favourites_count: Int?
        let id: String? // 数値のID
        let in_reply_to_account_id: String?
        let in_reply_to_id: String?
        let language: String?
        let mediaData: [MediaData]?
        let mentions: [MensionData]?
        let muted: Int?
        let reblog_acct: String?
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
    
    // 添付画像、動画
    struct MediaData {
        let id: Int64?
        let preview_url: String?
        let type: String?
        let url: String?
    }
    
    // メンション
    struct MensionData {
        let acct: String?
        let id: String? // 数値のID
        let url: String?
        let username: String?
    }
}
