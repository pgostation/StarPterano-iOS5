//
//  NotificationTableModel.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/23.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 通知画面に表示する内容

import UIKit

final class NotificationTableModel: NSObject, UITableViewDataSource, UITableViewDelegate {
    private var list: [AnalyzeJson.NotificationData] = []
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func change(addList: [AnalyzeJson.NotificationData]) {
        if list.count == 0 {
            list = addList
        } else {
            list += addList
        }
    }
    
    // セルの数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count + 1 // 一番下に余白をつけるため1加える
    }
    
    // セルの正確な高さ
    private let dummyLabel = UILabel()
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row >= list.count {
            return 100
        }
        
        let data = list[indexPath.row]
        if data.type == "follow" {
            return 15 + SettingsData.fontSize * 2
        } else {
            if let status = data.status {
                let attibutedText = DecodeToot.decodeContent(content: status.content, emojis: status.emojis) {
                }
                self.dummyLabel.attributedText = attibutedText.0
                self.dummyLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize - 2)
                self.dummyLabel.numberOfLines = 0
                self.dummyLabel.lineBreakMode = .byCharWrapping
                self.dummyLabel.frame.size.width = UIScreen.main.bounds.width - 55
                self.dummyLabel.sizeToFit()
                
                return self.dummyLabel.frame.height + SettingsData.fontSize * 2 + 20
            }
            return SettingsData.fontSize * 2
        }
    }
    
    // セルの中身を設定して返す
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row >= list.count {
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        
        let reuseIdentifier = "NotificationTable"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? NotificationTableCell ?? NotificationTableCell(reuseIdentifier: reuseIdentifier)
        
        let data = list[indexPath.row]
        let account = data.account
        let id = data.id ?? ""
        
        cell.id = id
        cell.accountId = data.account?.id
        
        ImageCache.image(urlStr: account?.avatar_static, isTemp: false, isSmall: true) { image in
            cell.iconView.image = image
        }
        
        cell.nameLabel.attributedText = DecodeToot.decodeName(name: account?.display_name ?? "", emojis: account?.emojis, callback: {
            if cell.id == id {
                cell.nameLabel.attributedText = DecodeToot.decodeName(name: account?.display_name ?? "", emojis: account?.emojis, callback: nil)
                cell.setNeedsLayout()
            }
        })
        cell.nameLabel.sizeToFit()
        
        cell.idLabel.text = account?.acct
        cell.idLabel.sizeToFit()
        
        switch data.type {
        case "mention":
            cell.notificationLabel.text = I18n.get("NOTIFICATION_MENTION")
        case "reblog":
            cell.notificationLabel.text = I18n.get("NOTIFICATION_BOOST")
        case "favourite":
            cell.notificationLabel.text = I18n.get("NOTIFICATION_FAV")
        case "follow":
            cell.notificationLabel.text = I18n.get("NOTIFICATION_FOLLOW")
        default:
            cell.notificationLabel.text = nil
        }
        
        if let created_at = data.created_at {
            let date = DecodeToot.decodeTime(text: created_at)
            cell.date = date
            cell.refreshDate()
        }
        
        if let status = data.status {
            let attibutedText = DecodeToot.decodeContent(content: status.content, emojis: status.emojis) {
            }
            cell.statusLabel.attributedText = attibutedText.0
        }
        
        return cell
    }
}
