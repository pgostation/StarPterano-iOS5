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
    var useAutopagerize = true
    private var list: [AnalyzeJson.NotificationData] = []
    private var filteredList: [AnalyzeJson.NotificationData] = []
    
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
    
    func getLastId() -> String? {
        return self.list.last?.id
    }
    
    // セルの数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let selectedSegmentIndex = (tableView.superview as? NotificationView)?.segmentControl.selectedSegmentIndex ?? 0
        
        self.filteredList = getFilteredList(list: self.list, selectedSegmentIndex: selectedSegmentIndex)
        
        return self.filteredList.count + 1 // 一番下に余白をつけるため1加える
    }
    
    private func getFilteredList(list: [AnalyzeJson.NotificationData], selectedSegmentIndex: Int) -> [AnalyzeJson.NotificationData] {
        var filteredList: [AnalyzeJson.NotificationData] = []
        
        for data in list {
            switch selectedSegmentIndex {
            case 0:
                filteredList.append(data)
            case 1:
                if data.type == "mention" {
                    filteredList.append(data)
                }
            case 2:
                if data.type == "follow" {
                    filteredList.append(data)
                }
            case 3:
                if data.type == "favourite" {
                    filteredList.append(data)
                }
            case 4:
                if data.type == "reblog" {
                    filteredList.append(data)
                }
            default:
                filteredList.append(data)
            }
        }
        
        return filteredList
    }
    
    // セルの正確な高さ
    private let dummyLabel = UITextView()
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row >= filteredList.count {
            if self.useAutopagerize && self.filteredList.count > 0 {
                // Autopagerize
                NotificationViewController.instance?.addOld()
            }
            
            return 150
        }
        
        let data = filteredList[indexPath.row]
        if data.type == "follow" {
            return 15 + SettingsData.fontSize * 2
        } else {
            if let status = data.status {
                let attibutedText = DecodeToot.decodeContentFast(content: status.content, emojis: status.emojis) {
                }
                self.dummyLabel.attributedText = attibutedText.0
                self.dummyLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize - 2)
                self.dummyLabel.frame.size.width = UIScreen.main.bounds.width - 55
                self.dummyLabel.sizeToFit()
                
                return self.dummyLabel.frame.height + SettingsData.fontSize * 2 + 20
            }
            return SettingsData.fontSize * 2
        }
    }
    
    // セルの中身を設定して返す
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row >= filteredList.count {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.backgroundColor = ThemeColor.viewBgColor
            cell.selectionStyle = .none
            return cell
        }
        
        let reuseIdentifier = "NotificationTable"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? NotificationTableCell ?? NotificationTableCell(reuseIdentifier: reuseIdentifier)
        
        let data = filteredList[indexPath.row]
        let account = data.account
        let id = data.id ?? ""
        
        cell.id = id
        cell.accountId = account?.id
        cell.accountData = account
        
        ImageCache.image(urlStr: account?.avatar_static, isTemp: false, isSmall: true) { image in
            if cell.id == id {
                cell.iconView.image = image
            }
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
            let attibutedText = DecodeToot.decodeContentFast(content: status.content, emojis: status.emojis) {
            }
            cell.statusLabel.attributedText = attibutedText.0
            cell.statusLabel.textColor = ThemeColor.idColor
        }
        
        return cell
    }
}
