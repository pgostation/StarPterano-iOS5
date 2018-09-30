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
import APNGKit

final class TimeLineViewModel: NSObject, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
    private var list: [AnalyzeJson.ContentData] = []
    private var accountList: [String: AnalyzeJson.AccountData] = [:]
    private var accountIdDict: [String: String] = [:]
    var showAutoPagerizeCell = true // 過去遡り用セルを表示するかどうか
    var selectedRow: Int? = nil
    private var selectedAccountId: String?
    private var inReplyToTootId: String?
    private var inReplyToAccountId: String?
    var isDetailTimeline = false
    
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
    func change(tableView: TimeLineView, addList: [AnalyzeJson.ContentData], accountList: [String: AnalyzeJson.AccountData], isStreaming: Bool = false) {
        
        // ミュートフラグの立っているものは削除しておく
        var addList2 = addList
        if tableView.type == .home || tableView.type == .local || tableView.type == .global {
            for (index, data) in addList2.enumerated().reversed() {
                if data.muted == 1 {
                    addList2.remove(at: index)
                }
            }
        }
        
        DispatchQueue.main.async {
            if self.list.count == 0 {
                self.list = addList2
            } else if let firstDate1 = self.list.first?.created_at, let firstDate2 = addList2.first?.created_at, let lastDate1 = self.list.last?.created_at, let lastDate2 = addList2.last?.created_at {
                // 前か後に付ければ良い
                if lastDate1 > firstDate2 {
                    self.list = self.list + addList2
                    
                    if self.list.count > 100000 {
                        // 10万トゥートを超えると流石に削除する
                        self.list.removeFirst(self.list.count - 100000)
                    }
                } else if lastDate2 > firstDate1 {
                    self.list = addList2 + self.list
                    
                    // 選択位置がずれないようにする
                    if self.selectedRow != nil {
                        self.selectedRow = self.selectedRow! + addList2.count
                    }
                    
                    if addList2.count <= 3 && tableView.contentOffset.y <= 60 {
                        // 一番上の場合、ずれさせる
                    } else {
                        // スクロールして、表示していたツイートがあまりずれないようにする
                        let oldOffsetY = tableView.contentOffset.y
                        DispatchQueue.main.async {
                            tableView.scrollToRow(at: IndexPath(row: addList2.count, section: 0),
                                                  at: UITableViewScrollPosition.top,
                                                  animated: false)
                            tableView.contentOffset.y = max(0, tableView.contentOffset.y + oldOffsetY)
                        }
                    }
                    
                    if self.list.count > 100000 {
                        // 10万トゥートを超えると流石に削除する
                        self.list.removeLast(self.list.count - 100000)
                    }
                } else {
                    // すでにあるデータを更新する
                    var index = 0
                    for newContent in addList2 {
                        while index < self.list.count {
                            let listData = self.list[index]
                            if listData.id == newContent.id {
                                self.list[index] = newContent
                                break
                            }
                            // タイムラインの方が古いので、その前に追加する
                            if (listData.id ?? "") < (newContent.id ?? "") {
                                self.list.insert(newContent, at: index)
                                break
                            }
                            index += 1
                        }
                    }
                }
            }
            
            // アカウント情報を更新
            for account in accountList {
                self.accountList.updateValue(account.value, forKey: account.key)
            }
            
            // アカウントID情報を更新
            for data in addList {
                if let mentions = data.mentions {
                    for mention in mentions {
                        if let acct = mention.acct, let id = mention.id {
                            self.accountIdDict.updateValue(id, forKey: acct)
                        }
                    }
                }
            }
            
            if !isStreaming {
                tableView.reloadData()
            }
        }
    }
    
    // トゥートの削除
    func delete(tableView: UITableView, deleteId: String) {
        DispatchQueue.main.async {
            for (index, data) in self.list.enumerated() {
                if index >= 500 { break }
                
                if deleteId == data.id {
                    self.list.remove(at: index)
                    tableView.reloadData()
                    break
                }
            }
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
        
        if let timelineView = tableView as? TimeLineView {
            if timelineView.type == .user {
                return list.count + 2 // プロフィール表示とオートページャライズ用のセル
            }
        }
        
        return list.count + 1 // オートページャライズ用のセル
    }
    
    // セルのだいたいの高さ(スクロールバーの表示用)
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch SettingsData.isMiniView {
        case .normal:
            return 60
        case .miniView:
            return 44
        case .superMini:
            return 30
        }
    }
    
    // セルの正確な高さ
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var index = indexPath.row
        
        if let timelineView = tableView as? TimeLineView {
            if timelineView.type == .user {
                index -= 1
                if index < 0 {
                    // プロフィール表示用セルの高さ
                    let accountData = timelineView.accountList[timelineView.option ?? ""]
                    let cell = ProfileViewCell(accountData: accountData, isTemp: true)
                    cell.layoutSubviews()
                    return cell.frame.height
                }
            }
        }
        
        if index == list.count {
            // AutoPagerize用セルの高さ
            return UIUtils.isIphoneX ? 150 : 100
        }
        
        let isSelected = !SettingsData.tapDetailMode && indexPath.row == self.selectedRow
        
        if SettingsData.isMiniView == .miniView && !isSelected {
            return 23 + SettingsData.fontSize * 1.5
        }
        if SettingsData.isMiniView == .superMini && !isSelected {
            return 10 + SettingsData.fontSize
        }
        
        // メッセージのビューを一度作り、高さを求める
        let (messageView, data, _) = getMessageViewAndData(index: index, indexPath: indexPath, callback: nil)
        
        // セルを拡大表示するかどうか
        var detailOffset: CGFloat = isSelected ? 40 : 0
        if isDetailTimeline && indexPath.row == selectedRow { // 詳細拡大表示
            detailOffset += 20
            
            // ブーストした人の名前を表示
            if let reblogs_count = data.reblogs_count, reblogs_count > 0 {
                detailOffset += (SettingsData.fontSize + 4) * CGFloat(min(10, reblogs_count)) + 4
            }
            // お気に入りした人の名前を表示
            if let favourites_count = data.favourites_count, favourites_count > 0 {
                detailOffset += (SettingsData.fontSize + 4) * CGFloat(min(10, favourites_count)) + 4
            }
        }
        
        if data.sensitive == 1 || data.spoiler_text != "" { // もっと見る
            detailOffset += 20
        }
        
        let imagesOffset: CGFloat
        if let mediaData = data.mediaData {
            imagesOffset = (isSelected ? UIScreen.main.bounds.width - 70 : 90) * CGFloat(mediaData.count)
        } else {
            imagesOffset = 0
        }
        
        let reblogOffset: CGFloat
        if data.reblog_acct != nil || data.visibility == "direct" {
            reblogOffset = 20
        } else {
            reblogOffset = 0
        }
        
        return max(55, messageView.frame.height + 28 + reblogOffset + imagesOffset + detailOffset)
    }
    
    // メッセージのビューとデータを返す
    private var cacheId = ""
    private var cache: (UIView, AnalyzeJson.ContentData, Bool)?
    private func getMessageViewAndData(index: Int, indexPath: IndexPath, callback: (()->Void)?) -> (UIView, AnalyzeJson.ContentData, Bool) {
        let data = list[index]
        
        if data.emojis == nil,  data.id == cacheId, let cache = self.cache {
            return cache
        }
        
        // content解析
        let (attributedText, hasLink) = DecodeToot.decodeContentFast(content: data.content, emojis: data.emojis, callback: callback)
        
        // 行間を広げる
        let paragrahStyle = NSMutableParagraphStyle()
        paragrahStyle.minimumLineHeight = SettingsData.fontSize + 10
        paragrahStyle.maximumLineHeight = SettingsData.fontSize + 10
        attributedText.addAttributes([NSAttributedStringKey.paragraphStyle : paragrahStyle],
                                     range: NSMakeRange(0, attributedText.length))
        
        // プロパティ設定
        let messageView: UIView
        if hasLink || (SettingsData.useAnimation && data.emojis != nil && data.emojis!.count > 0) {
            let msgView = UITextView()
            msgView.attributedText = attributedText
            msgView.linkTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: ThemeColor.linkTextColor]
            if isDetailTimeline && indexPath.row == selectedRow { // 拡大表示
                msgView.font = UIFont.systemFont(ofSize: SettingsData.fontSize + 3)
            } else {
                msgView.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
            }
            msgView.textColor = ThemeColor.messageColor
            msgView.backgroundColor = ThemeColor.cellBgColor
            msgView.textContainer.lineBreakMode = .byCharWrapping
            msgView.isOpaque = true
            msgView.isScrollEnabled = false
            msgView.isEditable = false
            msgView.delegate = self // URLタップ用
            
            // URL以外の場所タップ用
            let tapGensture = UITapGestureRecognizer(target: self, action: #selector(tapTextViewAction(_:)))
            msgView.addGestureRecognizer(tapGensture)
            
            messageView = msgView
        } else {
            let msgView = UILabel()
            msgView.attributedText = attributedText
            msgView.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
            msgView.textColor = ThemeColor.messageColor
            msgView.numberOfLines = 0
            msgView.lineBreakMode = .byCharWrapping
            msgView.backgroundColor = ThemeColor.cellBgColor
            msgView.isOpaque = true
            messageView = msgView
        }
        
        // ビューの高さを決める
        messageView.frame.size.width = UIScreen.main.bounds.width - (SettingsData.isMiniView != .normal ? 50 : 66)
        messageView.sizeToFit()
        var isContinue = false
        if self.selectedRow == indexPath.row {
            // 詳細表示の場合
        } else {
            if messageView.frame.size.height >= 180 - 28 {
                messageView.frame.size.height = 180 - 28
                isContinue = true
            }
        }
        
        if let id = data.id {
            self.cacheId = id
            self.cache = (messageView, data, isContinue)
        }
        
        return (messageView, data, isContinue)
    }
    
    // セルを返す
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var index = indexPath.row
        
        guard let timelineView = tableView as? TimeLineView else {
            return UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)
        }
        
        if timelineView.type == .user {
            index -= 1
            if index < 0 {
                // プロフィール表示用セル
                let accountData = timelineView.accountList[timelineView.option ?? ""]
                let isTemp = (self.list.count == 0)
                let cell = ProfileViewCell(accountData: accountData, isTemp: isTemp)
                cell.timelineView = tableView as? TimeLineView
                return cell
            }
        }
        
        if index >= list.count {
            if self.showAutoPagerizeCell, let timelineView = tableView as? TimeLineView {
                // 過去のトゥートに遡る
                timelineView.refreshOld(id: list.last?.id)
            }
            let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)
            cell.backgroundColor = ThemeColor.viewBgColor
            cell.selectionStyle = .none
            return cell
        }
        
        var cell: TimeLineViewCell! = nil
        var id: String = ""
        
        // 表示用のデータを取得
        let (messageView, data, isContinue) = getMessageViewAndData(index: index, indexPath: indexPath, callback: { [weak self] in
            // あとから絵文字が読み込めた場合の更新処理
            if cell.id == id {
                if let (messageView, _, _) = self?.getMessageViewAndData(index: index, indexPath: indexPath, callback: nil) {
                    let isHidden = cell?.messageView?.isHidden ?? false
                    messageView.isHidden = isHidden
                    cell?.messageView?.removeFromSuperview()
                    cell?.messageView = messageView
                    cell?.insertSubview(messageView, at: 1)
                    self?.setCellColor(cell: cell)
                    if cell?.isMiniView != .normal && self?.selectedRow != indexPath.row {
                        (messageView as? UILabel)?.numberOfLines = 1
                        messageView.sizeToFit()
                    }
                    let y = cell.isMiniView == .superMini ? -9 : cell.detailDateLabel?.frame.maxY ?? cell.spolerTextLabel?.frame.maxY ?? ((cell.isMiniView != .normal ? -9 : 5) + SettingsData.fontSize)
                        messageView.frame.origin.y = y
                }
            }
        })
        
        // カスタム絵文字のAPNGアニメーション対応
        if SettingsData.useAnimation, let emojis = data.emojis, emojis.count > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                guard let messageView = cell?.messageView as? UITextView else { return }
                
                let list = DecodeToot.getEmojiList(attributedText: messageView.attributedText, textStorage: messageView.textStorage)
                for data in list {
                    let beginning = messageView.beginningOfDocument
                    guard let start = messageView.position(from: beginning, offset: data.0.location) else { continue }
                    guard let end = messageView.position(from: start, offset: data.0.length) else { continue }
                    guard let textRange = messageView.textRange(from: start, to: end) else { continue }
                    let position = messageView.firstRect(for: textRange)
                    
                    for emoji in emojis {
                        if emoji["shortcode"] as? String == data.1 {
                            APNGImageCache.image(urlStr: emoji["url"] as? String) { image in
                                if image.frameCount <= 1 { return }
                                let apngView = APNGImageView(image: image)
                                apngView.tag = 5555
                                apngView.autoStartAnimation = true
                                apngView.backgroundColor = ThemeColor.cellBgColor
                                let size = min(position.size.width, position.size.height)
                                apngView.frame = CGRect(x: position.origin.x,
                                                        y: position.origin.y + 2,
                                                        width: size,
                                                        height: size)
                                messageView.addSubview(apngView)
                            }
                            break
                        }
                    }
                }
            }
        }
        
        
        let account = accountList[data.accountId]
        
        cell = getCell(view: tableView, height: max(55, messageView.frame.height + 28))
        cell.id = data.id ?? ""
        id = data.id ?? ""
        cell.tableView = tableView as? TimeLineView
        cell.indexPath = indexPath
        cell.accountId = account?.id
        cell.mentionsList = data.mentions
        cell.contentData = data.content ?? ""
        cell.urlStr = data.url ?? ""
        cell.isMiniView = SettingsData.isMiniView
        cell.accountData = account
        cell.visibility = data.visibility
        
        if cell.isMiniView != .normal && self.selectedRow != indexPath.row {
            (messageView as? UILabel)?.numberOfLines = 1
            messageView.sizeToFit()
        }
        
        cell.isFaved = (data.favourited == 1)
        cell.isBoosted = (data.reblogged == 1)
        
        cell.messageView = messageView
        cell.insertSubview(messageView, at: 1)
        
        // 「もっと見る」の場合
        if data.sensitive == 1 || data.spoiler_text != "" {
            messageView.isHidden = true
            cell.spolerTextLabel = UILabel()
            cell.spolerTextLabel?.textColor = ThemeColor.messageColor
            cell.spolerTextLabel?.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
            cell.spolerTextLabel?.attributedText = DecodeToot.decodeName(name: data.spoiler_text ?? "", emojis: data.emojis, callback: {
                if cell.id == id {
                    cell.spolerTextLabel?.attributedText = DecodeToot.decodeName(name: data.spoiler_text ?? "", emojis: data.emojis, callback: nil)
                    cell?.setNeedsLayout()
                }
            })
            cell.spolerTextLabel?.numberOfLines = 0
            cell.spolerTextLabel?.lineBreakMode = .byCharWrapping
            cell.spolerTextLabel?.sizeToFit()
            cell.addSubview(cell.spolerTextLabel!)
        }
        
        if data.visibility == "direct" || data.visibility == "private" {
            // ダイレクトメッセージは赤、プライベートメッセージはオレンジ
            let color = (data.visibility == "direct") ? ThemeColor.directBar: ThemeColor.privateBar
            cell.DMBarLeft = UIView()
            cell.DMBarLeft?.backgroundColor = color
            cell.addSubview(cell.DMBarLeft!)
            cell.DMBarRight = UIView()
            cell.DMBarRight?.backgroundColor = color
            cell.addSubview(cell.DMBarRight!)
        }
        
        // 詳細表示の場合
        if self.selectedRow == indexPath.row {
            cell.showDetail = true
            cell.isSelected = true
            
            self.selectedAccountId = account?.id
            self.inReplyToTootId = data.in_reply_to_id
            self.inReplyToAccountId = data.in_reply_to_account_id
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.setCellColor(cell: cell)
                
                for subview in tableView.subviews {
                    if let cell = subview as? TimeLineViewCell {
                        if self.selectedRow == cell.indexPath?.row { continue }
                        
                        self.setCellColor(cell: cell)
                    }
                }
            }
            
            // 返信ボタンを追加
            cell.replyButton = UIButton()
            cell.replyButton?.setTitle("↩︎", for: .normal)
            cell.replyButton?.setTitleColor(ThemeColor.detailButtonsColor, for: .normal)
            cell.replyButton?.addTarget(cell, action: #selector(cell.replyAction), for: .touchUpInside)
            cell.addSubview(cell.replyButton!)
            
            // 返信された数
            cell.repliedLabel = UILabel()
            cell.addSubview(cell.repliedLabel!)
            if let replies_count = data.replies_count, replies_count > 0 {
                cell.repliedLabel?.text = "\(replies_count)"
                cell.repliedLabel?.textColor = ThemeColor.messageColor
                cell.repliedLabel?.font = UIFont.systemFont(ofSize: SettingsData.fontSize - 2)
            }
            
            // ブーストボタン
            cell.boostButton = UIButton()
            if data.visibility == "direct" || data.visibility == "private" {
                cell.boostButton?.setTitle("🔐", for: .normal)
            } else {
                cell.boostButton?.setTitle("⇄", for: .normal)
                if data.reblogged == 1 {
                    cell.boostButton?.setTitleColor(ThemeColor.detailButtonsHiliteColor, for: .normal)
                } else {
                    cell.boostButton?.setTitleColor(ThemeColor.detailButtonsColor, for: .normal)
                }
                cell.boostButton?.addTarget(cell, action: #selector(cell.boostAction), for: .touchUpInside)
            }
            cell.addSubview(cell.boostButton!)
            
            // ブーストされた数
            cell.boostedLabel = UILabel()
            cell.addSubview(cell.boostedLabel!)
            if let reblogs_count = data.reblogs_count, reblogs_count > 0 {
                cell.boostedLabel?.text = "\(reblogs_count)"
                cell.boostedLabel?.textColor = ThemeColor.messageColor
                cell.boostedLabel?.font = UIFont.systemFont(ofSize: SettingsData.fontSize - 2)
            }
            
            // お気に入りボタン
            cell.favoriteButton = UIButton()
            cell.favoriteButton?.setTitle("★", for: .normal)
            if data.favourited == 1 {
                cell.favoriteButton?.setTitleColor(ThemeColor.detailButtonsHiliteColor, for: .normal)
            } else {
                cell.favoriteButton?.setTitleColor(ThemeColor.detailButtonsColor, for: .normal)
            }
            cell.favoriteButton?.addTarget(cell, action: #selector(cell.favoriteAction), for: .touchUpInside)
            cell.addSubview(cell.favoriteButton!)
            
            // お気に入りされた数
            cell.favoritedLabel = UILabel()
            cell.addSubview(cell.favoritedLabel!)
            if let favourites_count = data.favourites_count, favourites_count > 0 {
                cell.favoritedLabel?.text = "\(favourites_count)"
                cell.favoritedLabel?.textColor = ThemeColor.messageColor
                cell.favoritedLabel?.font = UIFont.systemFont(ofSize: SettingsData.fontSize - 2)
            }
            
            // 詳細ボタン
            cell.detailButton = UIButton()
            cell.detailButton?.setTitle("…", for: .normal)
            cell.detailButton?.setTitleColor(ThemeColor.detailButtonsColor, for: .normal)
            cell.detailButton?.addTarget(cell, action: #selector(cell.detailAction), for: .touchUpInside)
            cell.addSubview(cell.detailButton!)
            
            // 使用アプリケーション
            if let application = data.application {
                cell.applicationLabel = UILabel()
                cell.addSubview(cell.applicationLabel!)
                cell.applicationLabel?.text = "\(application["name"] ?? "")"
                cell.applicationLabel?.textColor = ThemeColor.dateColor
                cell.applicationLabel?.textAlignment = .right
                cell.applicationLabel?.adjustsFontSizeToFitWidth = true
                cell.applicationLabel?.font = UIFont.systemFont(ofSize: SettingsData.fontSize - 2)
            }
        } else {
            setCellColor(cell: cell)
        }
        
        ImageCache.image(urlStr: account?.avatar ?? account?.avatar_static, isTemp: false, isSmall: true) { image in
            if cell.id == id {
                if image.imageCount != nil {
                    // GIFアニメーション
                    cell.iconView = UIImageView(gifImage: image, manager: timelineView.gifManager, loopCount: SettingsData.useAnimation ? -1 : 0)
                } else {
                    cell.iconView = UIImageView()
                }
                
                cell.addSubview(cell.iconView!)
                cell.iconView?.image = image
                cell.iconView?.layer.cornerRadius = 5
                cell.iconView?.clipsToBounds = true
                
                // アイコンのタップジェスチャー
                let tapGesture = UITapGestureRecognizer(target: cell, action: #selector(cell.tapAccountAction))
                cell.iconView?.addGestureRecognizer(tapGesture)
                cell.iconView?.isUserInteractionEnabled = true
                
                // アイコンの長押しジェスチャー
                let pressGesture = UILongPressGestureRecognizer(target: cell, action: #selector(cell.pressAccountAction(_:)))
                cell.iconView?.addGestureRecognizer(pressGesture)
                let iconSize = SettingsData.iconSize
                
                cell.iconView?.frame = CGRect(x: cell.isMiniView != .normal ? 4 : 8,
                                              y: cell.isMiniView == .superMini ? 12 - iconSize / 2 : (cell.isMiniView != .normal ? 6 : 10),
                                              width: iconSize,
                                              height: iconSize)
            }
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
        
        if let created_at = data.reblog_created_at ?? data.created_at {
            let date = DecodeToot.decodeTime(text: created_at)
            
            if isDetailTimeline && indexPath.row == selectedRow { // 拡大表示
                cell.dateLabel.isHidden = true
                cell.detailDateLabel = UILabel()
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .medium
                cell.detailDateLabel?.text = dateFormatter.string(from: date)
                cell.detailDateLabel?.textColor = ThemeColor.dateColor
                cell.detailDateLabel?.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
                cell.detailDateLabel?.textAlignment = .right
                cell.addSubview(cell.detailDateLabel!)
            } else {
                cell.date = date
                cell.refreshDate()
                if cell.isMiniView != .superMini {
                    cell.dateLabel.isHidden = false
                }
            }
        }
        
        // 画像や動画ありの場合
        if let mediaData = data.mediaData {
            cell.imageViews = []
            cell.previewUrls = []
            cell.imageUrls = []
            
            for media in mediaData {
                let imageView = UIImageView()
                if !SettingsData.isLoadPreviewImage {
                    imageView.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
                }
                imageView.clipsToBounds = true
                
                // タップで全画面表示
                let tapGesture = UITapGestureRecognizer(target: cell, action: #selector(cell.imageTapAction(_:)))
                imageView.addGestureRecognizer(tapGesture)
                imageView.isUserInteractionEnabled = true
                
                ImageCache.image(urlStr: media.preview_url, isTemp: true, isSmall: false, isPreview: true) { image in
                    imageView.image = image
                    cell.setNeedsLayout()
                }
                cell.addSubview(imageView)
                cell.imageViews?.append(imageView)
                
                if data.sensitive == 1 || data.spoiler_text != "" {
                    imageView.isHidden = true
                }
                
                cell.previewUrls.append(media.preview_url ?? "")
                cell.imageUrls.append(media.url ?? "")
            }
        }
        
        // 長すぎて省略している場合
        if isContinue {
            cell.continueView = UILabel()
            cell.continueView?.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
            cell.continueView?.text = "▼"
            cell.continueView?.textColor = ThemeColor.nameColor
            cell.continueView?.textAlignment = .center
            cell.addSubview(cell.continueView!)
        }
        
        // ブーストの場合
        if let reblog_acct = data.reblog_acct {
            let account = accountList[reblog_acct]
            cell.boostView = UILabel()
            cell.boostView?.font = UIFont.systemFont(ofSize: SettingsData.fontSize - 2)
            cell.boostView?.textColor = ThemeColor.dateColor
            let name = String(format: I18n.get("BOOSTED_BY_%@"), account?.display_name ?? "")
            cell.boostView?.attributedText = DecodeToot.decodeName(name: name, emojis: account?.emojis, callback: nil)
            cell.addSubview(cell.boostView!)
        }
        
        // もっと見るの場合
        if data.sensitive == 1 || data.spoiler_text != "" {
            cell.showMoreButton = UIButton()
            cell.showMoreButton?.setTitle(I18n.get("BUTTON_SHOW_MORE"), for: .normal)
            cell.showMoreButton?.setTitleColor(ThemeColor.nameColor, for: .normal)
            cell.showMoreButton?.addTarget(cell, action: #selector(cell.showMoreAction), for: .touchUpInside)
            cell.addSubview(cell.showMoreButton!)
            
            if let id = data.id, id != "" && TimeLineViewCell.showMoreList.contains(id) {
                // すでに解除済み
                cell.showMoreAction()
            }
        }
        
        // DMの場合
        if data.visibility == "direct" {
            cell.boostView = UILabel()
            cell.boostView?.font = UIFont.boldSystemFont(ofSize: SettingsData.fontSize)
            cell.boostView?.textColor = UIColor.red
            cell.boostView?.text = I18n.get("THIS_TOOT_IS_DIRECT_MESSAGE")
            cell.addSubview(cell.boostView!)
        }
        
        // お気に入りした人やブーストした人の名前表示
        if isDetailTimeline && indexPath.row == selectedRow { // 詳細拡大表示
            // ブーストした人の名前を表示
            if let reblogs_count = data.reblogs_count, reblogs_count > 0 {
                for _ in 0..<min(10, reblogs_count) {
                    let label = UILabel()
                    cell.rebologerLabels.append(label)
                    label.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
                    label.textColor = ThemeColor.idColor
                    cell.addSubview(label)
                }
                
                if let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/statuses/\(data.id ?? "")/reblogged_by?limit=10") {
                    try? MastodonRequest.get(url: url) { (data, response, error) in
                        if cell.id != id { return }
                        if let data = data {
                            do {
                                if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: AnyObject]] {
                                    DispatchQueue.main.async {
                                        var count = 0
                                        for json in responseJson {
                                            let accountData = AnalyzeJson.analyzeAccountJson(account: json)
                                            if count >= cell.rebologerLabels.count { break }
                                            let label = cell.rebologerLabels[count]
                                            label.attributedText = DecodeToot.decodeName(name: "🔁 " + (accountData.display_name ?? "") + " " + (accountData.acct ?? ""), emojis: accountData.emojis, callback: nil)
                                            count += 1
                                        }
                                    }
                                }
                            } catch { }
                        }
                    }
                }
            }
            // お気に入りした人の名前を表示
            if let favourites_count = data.favourites_count, favourites_count > 0 {
                for _ in 0..<min(10, favourites_count) {
                    let label = UILabel()
                    cell.favoriterLabels.append(label)
                    label.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
                    label.textColor = ThemeColor.idColor
                    cell.addSubview(label)
                }
                
                if let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/statuses/\(data.id ?? "")/favourited_by?limit=10") {
                    try? MastodonRequest.get(url: url) { (data, response, error) in
                        if cell.id != id { return }
                        if let data = data {
                            do {
                                if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: AnyObject]] {
                                    DispatchQueue.main.async {
                                        var count = 0
                                        for json in responseJson {
                                            let accountData = AnalyzeJson.analyzeAccountJson(account: json)
                                            if count >= cell.favoriterLabels.count { break }
                                            let label = cell.favoriterLabels[count]
                                            label.attributedText = DecodeToot.decodeName(name: "⭐️ " + (accountData.display_name ?? "") + " " + (accountData.acct ?? ""), emojis: accountData.emojis, callback: nil)
                                            count += 1
                                        }
                                    }
                                }
                            } catch { }
                        }
                    }
                }
            }
        }
        
        return cell
    }
    
    // セルの色を設定
    private func setCellColor(cell: TimeLineViewCell) {
        func mentionContains(selectedAccountId: String?, mentions: [AnalyzeJson.MentionData]?) -> Bool {
            guard let selectedAccountId = selectedAccountId else { return false }
            guard let mentions = mentions else { return false }
            for mention in mentions {
                if selectedAccountId == mention.id {
                    return true
                }
            }
            return false
        }
        
        if self.selectedRow != nil && self.selectedRow == cell.indexPath?.row {
            // 選択色
            cell.backgroundColor = ThemeColor.selectedBgColor
            cell.messageView?.backgroundColor = ThemeColor.selectedBgColor
            cell.nameLabel.backgroundColor = ThemeColor.selectedBgColor
            cell.idLabel.backgroundColor = ThemeColor.selectedBgColor
            cell.dateLabel.backgroundColor = ThemeColor.selectedBgColor
        } else if self.selectedAccountId == cell.accountId {
            // 関連色
            cell.backgroundColor = ThemeColor.sameAccountBgColor
            cell.messageView?.backgroundColor = ThemeColor.sameAccountBgColor
            cell.nameLabel.backgroundColor = ThemeColor.sameAccountBgColor
            cell.idLabel.backgroundColor = ThemeColor.sameAccountBgColor
            cell.dateLabel.backgroundColor = ThemeColor.sameAccountBgColor
        } else if self.inReplyToTootId == cell.id {
            // 返信先のトゥートの色
            cell.backgroundColor = ThemeColor.mentionedBgColor
            cell.messageView?.backgroundColor = ThemeColor.mentionedBgColor
            cell.nameLabel.backgroundColor = ThemeColor.mentionedBgColor
            cell.idLabel.backgroundColor = ThemeColor.mentionedBgColor
            cell.dateLabel.backgroundColor = ThemeColor.mentionedBgColor
        } else if self.inReplyToAccountId == cell.accountId {
            // 返信先のアカウントの色
            cell.backgroundColor = ThemeColor.mentionedSameBgColor
            cell.messageView?.backgroundColor = ThemeColor.mentionedSameBgColor
            cell.nameLabel.backgroundColor = ThemeColor.mentionedSameBgColor
            cell.idLabel.backgroundColor = ThemeColor.mentionedSameBgColor
            cell.dateLabel.backgroundColor = ThemeColor.mentionedSameBgColor
        } else if mentionContains(selectedAccountId: self.selectedAccountId, mentions: cell.mentionsList) {
            // メンションが選択中アカウントの場合の色
            cell.backgroundColor = ThemeColor.toMentionBgColor
            cell.messageView?.backgroundColor = ThemeColor.toMentionBgColor
            cell.nameLabel.backgroundColor = ThemeColor.toMentionBgColor
            cell.idLabel.backgroundColor = ThemeColor.toMentionBgColor
            cell.dateLabel.backgroundColor = ThemeColor.toMentionBgColor
        } else {
            // 通常色
            cell.backgroundColor = ThemeColor.cellBgColor
            cell.messageView?.backgroundColor = ThemeColor.cellBgColor
            cell.nameLabel.backgroundColor = ThemeColor.cellBgColor
            cell.idLabel.backgroundColor = ThemeColor.cellBgColor
            cell.dateLabel.backgroundColor = ThemeColor.cellBgColor
        }
    }
    
    // セルを使い回す
    private func getCell(view: UITableView, height: CGFloat) -> TimeLineViewCell {
        let reuseIdentifier = "TimeLineViewModel"
        let cell = view.dequeueReusableCell(withIdentifier: reuseIdentifier) as? TimeLineViewCell ?? TimeLineViewCell(reuseIdentifier: reuseIdentifier)
        
        return cell
    }
    
    // セル選択時の処理
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var index = indexPath.row
        
        if let timelineView = tableView as? TimeLineView {
            if timelineView.type == .user {
                index -= 1
                if index < 0 {
                    return
                }
            }
        }
        
        if SettingsData.tapDetailMode || self.selectedRow == indexPath.row {
            if self.isDetailTimeline { return } // すでに詳細表示画面
            if TootViewController.isShown { return } // トゥート画面表示中は移動しない
            
            // トゥート詳細画面に移動
            let (_, data, _) = getMessageViewAndData(index: index, indexPath: indexPath, callback: nil)
            let mentionsData = getMentionsData(data: data)
            let viewController = TimeLineViewController(type: TimeLineViewController.TimeLineType.mentions, option: nil, mentions: (mentionsData, accountList))
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
            if self.selectedRow != nil {
                let oldPath = IndexPath(row: self.selectedRow ?? 0, section: 0)
                indexPaths.append(oldPath)
                
                if oldPath.row < indexPath.row {
                    // 高さのずれを吸収
                    let oldHeight = self.tableView(tableView, heightForRowAt: oldPath)
                    self.selectedRow = indexPath.row
                    let newHeight = self.tableView(tableView, heightForRowAt: oldPath)
                    
                    DispatchQueue.main.async {
                        tableView.contentOffset.y = max(0, tableView.contentOffset.y + newHeight - oldHeight + 40)
                    }
                }
            }
            
            self.selectedRow = indexPath.row
            
            tableView.reloadRows(at: indexPaths, with: UITableViewRowAnimation.none)
        }
    }
    
    // 会話部分のデータを取り出す
    private func getMentionsData(data: AnalyzeJson.ContentData) -> [AnalyzeJson.ContentData] {
        var mentionContents: [AnalyzeJson.ContentData] = [data]
        
        var in_reply_to_id = data.in_reply_to_id
        for listData in self.list {
            if listData.id == in_reply_to_id {
                mentionContents.append(listData)
                in_reply_to_id = listData.in_reply_to_id
                if in_reply_to_id == nil { break }
            }
        }
        
        return mentionContents
    }
    
    // UITextViewのリンクタップ時の処理
    func textView(_ textView: UITextView, shouldInteractWith Url: URL, in characterRange: NSRange) -> Bool {
        if Url.path.hasPrefix("/tags/") {
            // ハッシュタグの場合
            let viewController = TimeLineViewController(type: TimeLineViewController.TimeLineType.globalTag,
                                                        option: String(Url.path.suffix(Url.path.count - 6)))
            MainViewController.instance?.addChildViewController(viewController)
            MainViewController.instance?.view.addSubview(viewController.view)
            viewController.view.frame = CGRect(x: UIScreen.main.bounds.width,
                                               y: 0,
                                               width: UIScreen.main.bounds.width,
                                               height: UIScreen.main.bounds.height)
            UIView.animate(withDuration: 0.3) {
                viewController.view.frame.origin.x = 0
            }
            return false
        }
        
        if Url.path.hasPrefix("/@") {
            let host: String?
            if Url.host == SettingsData.hostName {
                host = nil
            } else {
                host = Url.host
            }
            let accountId = String(Url.path.suffix(Url.path.count - 2))
            if let id = convertAccountToId(host: host, accountId: accountId) {
                // @でのIDコール
                let viewController = TimeLineViewController(type: TimeLineViewController.TimeLineType.user,
                                                            option: id)
                
                func show() {
                    MainViewController.instance?.addChildViewController(viewController)
                    MainViewController.instance?.view.addSubview(viewController.view)
                    viewController.view.frame = CGRect(x: UIScreen.main.bounds.width,
                                                       y: 0,
                                                       width: UIScreen.main.bounds.width,
                                                       height: UIScreen.main.bounds.height)
                    UIView.animate(withDuration: 0.3) {
                        viewController.view.frame.origin.x = 0
                    }
                }
                
                let acct = accountId + (host != nil ? "@\(host!)" : "")
                if let timelineView = viewController.view as? TimeLineView {
                    if let accountData = self.accountList[acct] {
                        // すぐに表示
                        timelineView.accountList.updateValue(accountData, forKey: id)
                        show()
                    } else {
                        // 情報を取得してから表示
                        guard let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/accounts/\(id)") else { return false }
                        try? MastodonRequest.get(url: url) { (data, response, error) in
                            if let data = data {
                                do {
                                    if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                                        let accountData = AnalyzeJson.analyzeAccountJson(account: responseJson)
                                        timelineView.accountList.updateValue(accountData, forKey: id)
                                    }
                                } catch { }
                            }
                            DispatchQueue.main.async {
                                show()
                            }
                        }
                    }
                }
                return false
            }
        }
        
        let controller = SFSafariViewController(url: Url)
        MainViewController.instance?.present(controller, animated: true)
        
        return false
    }
    
    // アカウント文字列から数値IDに変換
    private func convertAccountToId(host: String?, accountId: String) -> String? {
        let key: String
        if let host = host {
            key = accountId + "@" + host
        } else {
            key = accountId
        }
        
        return accountIdDict[key]
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
    
    // スクロールしている間ボタンを隠す
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        MainViewController.instance?.hideButtons()
    }
}
