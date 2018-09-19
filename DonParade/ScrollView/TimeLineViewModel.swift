//
//  TimeLineViewModel.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/17.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 各種タイムラインやお気に入りなどのデータを保持し、テーブルビューのセルに表示する

import UIKit
import SafariServices

final class TimeLineViewModel: NSObject, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
    private var list: [AnalyzeJson.ContentData] = []
    private var accountList: [String: AnalyzeJson.AccountData] = [:]
    var showGrowlCell = true // 過去遡り用セルを表示するかどうか
    var selectedIndexPath: IndexPath? = nil
    private var selectedAccountId: String?
    private var inReplyToTootId: String?
    private var inReplyToAccountId: String?
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 一番新しいトゥートのID
    func getFirstTootId() -> String? {
        return list.first?.id
    }
    
    // 一番古いトゥートのin_reply_to_id
    func getLastInReplyToId() -> String? {
        return list.last?.in_reply_to_id
    }
    
    // トゥートの追加
    func change(tableView: UITableView, addList: [AnalyzeJson.ContentData], accountList: [String: AnalyzeJson.AccountData]) {
        DispatchQueue.main.async {
            if self.list.count == 0 {
                self.list = addList
            } else if addList.count >= 2, let date1 = self.list.first?.created_at, let date2 = addList.first?.created_at {
                // 前か後に付ければ良い
                if date1 > date2 {
                    self.list = self.list + addList
                } else {
                    self.list = addList + self.list
                }
            } else {
                // すでにあるデータを更新する
                for newContent in addList {
                    var flag = false
                    for (index, listData) in self.list.enumerated() {
                        if listData.id == newContent.id {
                            self.list[index] = newContent
                            flag = true
                            break
                        }
                    }
                    if !flag {
                        self.list.append(newContent)
                    }
                }
            }
            
            // アカウント情報を更新
            for account in accountList {
                self.accountList.updateValue(account.value, forKey: account.key)
            }
            
            tableView.reloadData()
        }
    }
    
    // セルの数
    private var isFirstView = true
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if list.count == 0, isFirstView {
            isFirstView = false
            if let timelineView = tableView as? TimeLineView {
                timelineView.refresh()
            }
        }
        
        return list.count + (showGrowlCell ? 1 : 0)
    }
    
    // セルのだいたいの高さ(スクロールバーの表示用)
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    // セルの正確な高さ
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == list.count {
            // Growl用セルの高さ
            return 55
        }
        
        // セルを拡大表示するかどうか
        let isSelected = !SettingsData.tapDetailMode && indexPath.row == self.selectedIndexPath?.row
        let detailOffset: CGFloat = isSelected ? 40 : 0
            
        // メッセージのビューを一度作り、高さを求める
        let (messageView, data, _) = getMessageViewAndData(indexPath: indexPath, callback: nil)
        
        let imagesOffset: CGFloat
        if let mediaData = data.mediaData {
            imagesOffset = (isSelected ? UIScreen.main.bounds.width - 70 : 90) * CGFloat(mediaData.count)
        } else {
            imagesOffset = 0
        }
        
        if data.reblog_acct != nil {
            return max(55, messageView.frame.height + 28 + 20 + imagesOffset + detailOffset)
        } else {
            return max(55, messageView.frame.height + 28 + imagesOffset + detailOffset)
        }
    }
    
    // メッセージのビューとデータを返す
    private func getMessageViewAndData(indexPath: IndexPath, callback: (()->Void)?) -> (UIView, AnalyzeJson.ContentData, Bool) {
        let data = list[indexPath.row]
        
        // content解析
        let (attributedText, hasLink) = DecodeToot.decodeContent(content: data.content, emojis: data.emojis, callback: callback)
        
        // 行間を広げる
        let paragrahStyle = NSMutableParagraphStyle()
        paragrahStyle.minimumLineHeight = 24
        paragrahStyle.maximumLineHeight = 24
        attributedText.addAttributes([NSAttributedStringKey.paragraphStyle : paragrahStyle],
                                     range: NSMakeRange(0, attributedText.length))
        
        // プロパティ設定
        let messageView: UIView
        if hasLink {
            let msgView = UITextView()
            msgView.attributedText = attributedText
            msgView.font = UIFont.systemFont(ofSize: 14)
            msgView.backgroundColor = TimeLineViewCell.bgColor
            msgView.textContainer.lineBreakMode = .byCharWrapping
            msgView.isOpaque = true
            msgView.isScrollEnabled = false
            msgView.isEditable = false
            msgView.delegate = self // URLタップ用
            
            // URL以外の場所タップ用
            let tapGensture = UITapGestureRecognizer.init(target: self, action: #selector(tapTextViewAction(_:)))
            msgView.addGestureRecognizer(tapGensture)
            
            messageView = msgView
        } else {
            let msgView = UILabel()
            msgView.attributedText = attributedText
            msgView.font = UIFont.systemFont(ofSize: 14)
            msgView.numberOfLines = 0
            msgView.lineBreakMode = .byCharWrapping
            msgView.backgroundColor = TimeLineViewCell.bgColor
            msgView.isOpaque = true
            messageView = msgView
        }
        
        // ビューの高さを決める
        messageView.frame.size.width = UIScreen.main.bounds.width - 66
        messageView.sizeToFit()
        var isContinue = false
        if self.selectedIndexPath?.row == indexPath.row {
            // 詳細表示の場合
        } else {
            if messageView.frame.size.height >= 180 - 28 {
                messageView.frame.size.height = 180 - 28
                isContinue = true
            }
        }
        
        return (messageView, data, isContinue)
    }
    
    // セルを返す
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row >= list.count {
            if self.showGrowlCell, let timelineView = tableView as? TimeLineView {
                // 過去のトゥートに遡る
                timelineView.refreshOld(id: list.last?.id)
            }
            return getCell(view: tableView, height: 55)
        }
        
        var cell: TimeLineViewCell! = nil
        var id: String = ""
        
        let (messageView, data, isContinue) = getMessageViewAndData(indexPath: indexPath, callback: { [weak self] in
            if cell.id == id {
                if let (messageView, _, _) = self?.getMessageViewAndData(indexPath: indexPath, callback: nil) {
                    cell?.messageView?.removeFromSuperview()
                    cell?.messageView = messageView
                    cell?.insertSubview(messageView, at: 2)
                    self?.setCellColor(cell: cell)
                }
            }
        })
        let account = accountList[data.accountId]
        
        cell = getCell(view: tableView, height: max(55, messageView.frame.height + 28))
        cell.id = data.id ?? ""
        id = data.id ?? ""
        cell.tableView = tableView as? TimeLineView
        cell.indexPath = indexPath
        cell.accountId = account?.id
        cell.mensionsList = data.mentions
        cell.contentData = data.content ?? ""
        cell.urlStr = data.url ?? ""
        
        cell.isFaved = (data.favourited == 1)
        cell.isBoosted = (data.reblogged == 1)
        
        cell.messageView = messageView
        cell.insertSubview(messageView, at: 2)
        
        // 詳細表示の場合
        if self.selectedIndexPath?.row == indexPath.row {
            cell.showDetail = true
            cell.isSelected = true
            
            self.selectedAccountId = account?.id
            self.inReplyToTootId = data.in_reply_to_id
            self.inReplyToAccountId = data.in_reply_to_account_id
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.setCellColor(cell: cell)
                
                for subview in tableView.subviews {
                    if let cell = subview as? TimeLineViewCell {
                        if self.selectedIndexPath?.row == cell.indexPath?.row { continue }
                        
                        self.setCellColor(cell: cell)
                    }
                }
            }
            
            // 返信ボタンを追加
            cell.replyButton = UIButton()
            cell.replyButton?.setTitle("↩︎", for: .normal)
            cell.replyButton?.setTitleColor(UIColor.darkGray, for: .normal)
            cell.replyButton?.addTarget(cell, action: #selector(cell.replyAction), for: .touchUpInside)
            cell.addSubview(cell.replyButton!)
            
            // 返信された数
            cell.repliedLabel = UILabel()
            cell.addSubview(cell.repliedLabel!)
            if let replies_count = data.replies_count, replies_count > 0 {
                cell.repliedLabel?.text = "\(replies_count)"
                cell.repliedLabel?.font = UIFont.systemFont(ofSize: 14)
            }
            
            // ブーストボタン
            cell.boostButton = UIButton()
            cell.boostButton?.setTitle("⇄", for: .normal)
            if data.reblogged == 1 {
                cell.boostButton?.setTitleColor(UIColor.blue, for: .normal)
            } else {
                cell.boostButton?.setTitleColor(UIColor.gray, for: .normal)
            }
            cell.boostButton?.addTarget(cell, action: #selector(cell.boostAction), for: .touchUpInside)
            cell.addSubview(cell.boostButton!)
            
            // ブーストされた数
            cell.boostedLabel = UILabel()
            cell.addSubview(cell.boostedLabel!)
            if let reblogs_count = data.reblogs_count, reblogs_count > 0 {
                cell.boostedLabel?.text = "\(reblogs_count)"
                cell.boostedLabel?.font = UIFont.systemFont(ofSize: 14)
            }
            
            // お気に入りボタン
            cell.favoriteButton = UIButton()
            cell.favoriteButton?.setTitle("★", for: .normal)
            if data.favourited == 1 {
                cell.favoriteButton?.setTitleColor(UIColor.blue, for: .normal)
            } else {
                cell.favoriteButton?.setTitleColor(UIColor.gray, for: .normal)
            }
            cell.favoriteButton?.addTarget(cell, action: #selector(cell.favoriteAction), for: .touchUpInside)
            cell.addSubview(cell.favoriteButton!)
            
            // お気に入りされた数
            cell.favoritedLabel = UILabel()
            cell.addSubview(cell.favoritedLabel!)
            if let favourites_count = data.favourites_count, favourites_count > 0 {
                cell.favoritedLabel?.text = "\(favourites_count)"
                cell.favoritedLabel?.font = UIFont.systemFont(ofSize: 14)
            }
            
            // 詳細ボタン
            cell.detailButton = UIButton()
            cell.detailButton?.setTitle("…", for: .normal)
            cell.detailButton?.setTitleColor(UIColor.darkGray, for: .normal)
            cell.detailButton?.addTarget(cell, action: #selector(cell.detailAction), for: .touchUpInside)
            cell.addSubview(cell.detailButton!)
            
            // 使用アプリケーション
            if let application = data.application {
                cell.applicationLabel = UILabel()
                cell.addSubview(cell.applicationLabel!)
                cell.applicationLabel?.text = "\(application["name"] ?? "")"
                cell.applicationLabel?.textColor = UIColor.gray
                cell.applicationLabel?.textAlignment = .right
                cell.applicationLabel?.adjustsFontSizeToFitWidth = true
                cell.applicationLabel?.font = UIFont.systemFont(ofSize: 12)
            }
        } else {
            setCellColor(cell: cell)
        }
        
        ImageCache.image(urlStr: account?.avatar_static, isTemp: false) { image in
            cell.iconView.image = image
        }
        
        cell.nameLabel.attributedText = DecodeToot.decodeName(name: account?.display_name ?? "", emojis: account?.emojis, callback: {
            if cell.id == id {
                cell.nameLabel.attributedText = DecodeToot.decodeName(name: account?.display_name ?? "", emojis: account?.emojis, callback: nil)
                cell?.setNeedsLayout()
            }
        })
        cell.nameLabel.sizeToFit()
        
        cell.idLabel.text = account?.acct
        cell.idLabel.sizeToFit()
        
        if let created_at = data.created_at {
            let date = DecodeToot.decodeTime(text: created_at)
            cell.date = date
            cell.refreshDate()
        }
        
        // 画像や動画ありの場合
        if let mediaData = data.mediaData {
            cell.imageViews = []
            
            for media in mediaData {
                let imageView = UIImageView()
                ImageCache.image(urlStr: media.preview_url, isTemp: true) { image in
                    imageView.image = image
                    cell.setNeedsLayout()
                }
                cell.addSubview(imageView)
                cell.imageViews?.append(imageView)
            }
        }
        
        // 長すぎて省略している場合
        if isContinue {
            cell.continueView = UILabel()
            cell.continueView?.font = UIFont.systemFont(ofSize: 14)
            cell.continueView?.text = "▼"
            cell.continueView?.textColor = UIColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0)
            cell.continueView?.textAlignment = .center
            cell.addSubview(cell.continueView!)
        }
        
        // ブーストの場合
        if let reblog_acct = data.reblog_acct {
            let account = accountList[reblog_acct]
            cell.boostView = UILabel()
            cell.boostView?.font = UIFont.systemFont(ofSize: 12)
            cell.boostView?.textColor = UIColor.darkGray
            cell.boostView?.text = String(format: I18n.get("BOOSTED_BY_%@"), account?.display_name ?? "")
            cell.addSubview(cell.boostView!)
        }
        
        return cell
    }
    
    // セルの色を設定
    private func setCellColor(cell: TimeLineViewCell) {
        func mensionContains(selectedAccountId: String?, mensions: [AnalyzeJson.MensionData]?) -> Bool {
            guard let selectedAccountId = selectedAccountId else { return false }
            guard let mensions = mensions else { return false }
            for mension in mensions {
                if selectedAccountId == mension.id {
                    return true
                }
            }
            return false
        }
        
        if self.selectedIndexPath != nil && self.selectedIndexPath?.row == cell.indexPath?.row {
            // 選択色
            cell.backgroundColor = TimeLineViewCell.selectedBgColor
            cell.messageView?.backgroundColor = TimeLineViewCell.selectedBgColor
            cell.nameLabel.backgroundColor = TimeLineViewCell.selectedBgColor
            cell.idLabel.backgroundColor = TimeLineViewCell.selectedBgColor
            cell.dateLabel.backgroundColor = TimeLineViewCell.selectedBgColor
        } else if self.selectedAccountId == cell.accountId {
            // 関連色
            cell.backgroundColor = TimeLineViewCell.sameAccountBgColor
            cell.messageView?.backgroundColor = TimeLineViewCell.sameAccountBgColor
            cell.nameLabel.backgroundColor = TimeLineViewCell.sameAccountBgColor
            cell.idLabel.backgroundColor = TimeLineViewCell.sameAccountBgColor
            cell.dateLabel.backgroundColor = TimeLineViewCell.sameAccountBgColor
        } else if self.inReplyToTootId == cell.id {
            // 返信先のトゥートの色
            cell.backgroundColor = TimeLineViewCell.mentionedBgColor
            cell.messageView?.backgroundColor = TimeLineViewCell.mentionedBgColor
            cell.nameLabel.backgroundColor = TimeLineViewCell.mentionedBgColor
            cell.idLabel.backgroundColor = TimeLineViewCell.mentionedBgColor
            cell.dateLabel.backgroundColor = TimeLineViewCell.mentionedBgColor
        } else if self.inReplyToAccountId == cell.accountId {
            // 返信先のアカウントの色
            cell.backgroundColor = TimeLineViewCell.mentionedSameBgColor
            cell.messageView?.backgroundColor = TimeLineViewCell.mentionedSameBgColor
            cell.nameLabel.backgroundColor = TimeLineViewCell.mentionedSameBgColor
            cell.idLabel.backgroundColor = TimeLineViewCell.mentionedSameBgColor
            cell.dateLabel.backgroundColor = TimeLineViewCell.mentionedSameBgColor
        } else if mensionContains(selectedAccountId: self.selectedAccountId, mensions: cell.mensionsList) {
            // メンションが選択中アカウントの場合の色
            cell.backgroundColor = TimeLineViewCell.toMentionBgColor
            cell.messageView?.backgroundColor = TimeLineViewCell.toMentionBgColor
            cell.nameLabel.backgroundColor = TimeLineViewCell.toMentionBgColor
            cell.idLabel.backgroundColor = TimeLineViewCell.toMentionBgColor
            cell.dateLabel.backgroundColor = TimeLineViewCell.toMentionBgColor
        } else {
            // 通常色
            cell.backgroundColor = TimeLineViewCell.bgColor
            cell.messageView?.backgroundColor = TimeLineViewCell.bgColor
            cell.nameLabel.backgroundColor = TimeLineViewCell.bgColor
            cell.idLabel.backgroundColor = TimeLineViewCell.bgColor
            cell.dateLabel.backgroundColor = TimeLineViewCell.bgColor
        }
    }
    
    // セルを使い回す
    private func getCell(view: UITableView, height: CGFloat) -> TimeLineViewCell {
        let reuseIdentifier = "TimeLineViewModel\(height)"
        let cell = view.dequeueReusableCell(withIdentifier: reuseIdentifier) as? TimeLineViewCell ?? TimeLineViewCell(reuseIdentifier: reuseIdentifier)
        
        cell.showDetail = false
        cell.messageView?.removeFromSuperview()
        cell.continueView?.removeFromSuperview()
        cell.boostView?.removeFromSuperview()
        cell.boostView = nil
        for imageView in cell.imageViews ?? [] {
            imageView.removeFromSuperview()
        }
        cell.imageViews = []
        if cell.replyButton != nil {
            cell.replyButton?.removeFromSuperview()
            cell.repliedLabel?.removeFromSuperview()
            cell.boostButton?.removeFromSuperview()
            cell.boostedLabel?.removeFromSuperview()
            cell.favoriteButton?.removeFromSuperview()
            cell.favoritedLabel?.removeFromSuperview()
            cell.detailButton?.removeFromSuperview()
            cell.applicationLabel?.removeFromSuperview()
        }
        cell.iconView.image = nil
        
        return cell
    }
    
    // セル選択時の処理
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if SettingsData.tapDetailMode || self.selectedIndexPath?.row == indexPath.row {
            // トゥート詳細画面に移動
            let (_, data, _) = getMessageViewAndData(indexPath: indexPath, callback: nil)
            let mensionsData = getMensionsData(data: data)
            let viewController = TimeLineViewController(type: TimeLineViewController.TimeLineType.mensions, option: nil, mensions: (mensionsData, accountList))
            MainViewController.instance?.addChildViewController(viewController)
            MainViewController.instance?.view.addSubview(viewController.view)
            viewController.view.frame = CGRect(x: UIScreen.main.bounds.width,
                                                              y: 0,
                                                              width: UIScreen.main.bounds.width,
                                                              height: UIScreen.main.bounds.height)
            UIView.animate(withDuration: 0.3) {
                viewController.view.frame.origin.x = 0
            }
            
            tableView.deselectRow(at: indexPath, animated: true)
        } else {
            // セルを拡大して表示
            var indexPaths: [IndexPath] = [indexPath]
            if let oldPath = self.selectedIndexPath {
                indexPaths.append(oldPath)
                
                if oldPath.row < indexPath.row {
                    // 高さのずれを吸収
                    let oldHeight = self.tableView(tableView, heightForRowAt: oldPath)
                    self.selectedIndexPath = indexPath
                    let newHeight = self.tableView(tableView, heightForRowAt: oldPath)
                    
                    DispatchQueue.main.async {
                        tableView.contentOffset.y = max(0, tableView.contentOffset.y + newHeight - oldHeight + 40)
                    }
                }
            }
            
            self.selectedIndexPath = indexPath
            
            tableView.reloadRows(at: indexPaths, with: UITableViewRowAnimation.none)
        }
    }
    
    // 会話部分のデータを取り出す
    private func getMensionsData(data: AnalyzeJson.ContentData) -> [AnalyzeJson.ContentData] {
        var mensionContents: [AnalyzeJson.ContentData] = [data]
        
        var in_reply_to_id = data.in_reply_to_id
        for listData in self.list {
            if listData.id == in_reply_to_id {
                mensionContents.append(listData)
                in_reply_to_id = listData.in_reply_to_id
                if in_reply_to_id == nil { break }
            }
        }
        
        return mensionContents
    }
    
    // UITextViewのリンクタップ時の処理
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        let controller = SFSafariViewController(url: URL)
        MainViewController.instance?.present(controller, animated: true)
        
        return false
    }
    
    // UITextViewのリンク以外タップ時の処理
    @objc func tapTextViewAction(_ gesture: UIGestureRecognizer) {
        guard let msgView = gesture.view else { return }
        guard let cell = msgView.superview as? TimeLineViewCell else { return }
        
        if let tableView = cell.tableView, let indexPath = cell.indexPath {
            // セル選択時の処理を実行
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            self.tableView(tableView, didSelectRowAt: indexPath)
        }
    }
}
