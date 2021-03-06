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
    
    func getNewestCreatedAt() -> String? {
        return self.list.first?.created_at
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
                
                let height: CGFloat
                if data.type == "mention" {
                    // 返信とお気に入りボタンの分
                    height = self.dummyLabel.frame.height + SettingsData.fontSize * 2 + 20 + 40
                } else {
                    height = self.dummyLabel.frame.height + SettingsData.fontSize * 2 + 20
                }
                
                // 画像がある場合
                if let mediaCount = data.status?.mediaData?.count, mediaCount > 0 {
                    return height + CGFloat(mediaCount) * 65
                }
                
                return height
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
        cell.statusId = data.status?.id
        cell.visibility = data.status?.visibility
        
        ImageCache.image(urlStr: account?.avatar_static, isTemp: false, isSmall: true) { image in
            if cell.id == id {
                cell.iconView.image = image
            }
        }
        
        cell.nameLabel.attributedText = DecodeToot.decodeName(name: account?.display_name ?? "", emojis: account?.emojis, uiLabel: cell.nameLabel, callback: {
            if cell.id == id {
                cell.nameLabel.attributedText = DecodeToot.decodeName(name: account?.display_name ?? "", emojis: account?.emojis, uiLabel: cell.nameLabel, callback: nil)
                cell.setNeedsLayout()
            }
        })
        cell.nameLabel.sizeToFit()
        
        cell.idLabel.text = account?.acct
        cell.idLabel.sizeToFit()
        
        cell.replyButton.isHidden = true
        cell.favoriteButton.isHidden = true
        switch data.type {
        case "mention":
            cell.notificationLabel.text = I18n.get("NOTIFICATION_MENTION")
            cell.replyButton.isHidden = false
            cell.favoriteButton.isHidden = false
            if data.status?.favourited == 1 {
                cell.favoriteButton.setTitleColor(ThemeColor.detailButtonsHiliteColor, for: .normal)
                cell.isFaved = true
            } else {
                cell.favoriteButton.setTitleColor(ThemeColor.detailButtonsColor, for: .normal)
                cell.isFaved = false
            }
        case "reblog":
            cell.notificationLabel.text = I18n.get("NOTIFICATION_BOOST")
        case "favourite":
            cell.notificationLabel.text = I18n.get("NOTIFICATION_FAV")
        case "follow":
            cell.notificationLabel.text = I18n.get("NOTIFICATION_FOLLOW")
        case "poll":
            cell.notificationLabel.text = I18n.get("NOTIFICATION_POLL")
        default:
            cell.notificationLabel.text = data.type
        }
        
        if let created_at = data.created_at {
            let date = DecodeToot.decodeTime(text: created_at)
            cell.date = date
            cell.refreshDate()
        }
        
        if let status = data.status {
            let attibutedText = DecodeToot.decodeContentFast(content: status.content, emojis: status.emojis) {
                if cell.id == id {
                    let attibutedText = DecodeToot.decodeContentFast(content: status.content, emojis: status.emojis) {}
                    cell.statusLabel.attributedText = attibutedText.0
                    cell.statusLabel.textColor = ThemeColor.idColor
                }
            }
            cell.statusLabel.attributedText = attibutedText.0
            cell.statusLabel.textColor = ThemeColor.idColor
        }
        
        for imageView in cell.imageViews {
            imageView.image = nil
        }
        // 画像がある場合
        if let mediaCount = data.status?.mediaData?.count, mediaCount > 0 {
            for i in 0..<mediaCount {
                let mediaData = (data.status?.mediaData?[i])!
                ImageCache.image(urlStr: mediaData.preview_url, isTemp: true, isSmall: false) { (image) in
                    cell.imageViews[i].image = image
                    cell.imageViews[i].contentMode = .scaleAspectFill
                    cell.imageViews[i].clipsToBounds = true
                    cell.setNeedsLayout()
                }
            }
        }
        
        return cell
    }
}
