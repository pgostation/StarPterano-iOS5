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
import AVFoundation

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
    
    //
    func clear() {
        self.list = []
        self.showAutoPagerizeCell = true
        clearSelection()
    }
    
    //
    func clearSelection() {
        self.selectedRow = nil
        self.selectedAccountId = nil
        self.inReplyToTootId = nil
        self.inReplyToAccountId = nil
    }
    
    // トゥートの追加
    func change(tableView: TimeLineView, addList: [AnalyzeJson.ContentData], accountList: [String: AnalyzeJson.AccountData], isStreaming: Bool = false, isNewRefresh: Bool = false, isBoosted: Bool = false) {
        
        // ミュートフラグの立っているものは削除しておく
        var addList2 = addList
        if tableView.type == .home || tableView.type == .local || tableView.type == .federation {
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
                
                if addList2.count == 1 && isBoosted {
                    // 自分でブーストした場合、上に持ってくるとおかしくなるので
                    // すでにあるデータを更新する
                    if let newContent = addList2.first {
                        var index = 0
                        while index < self.list.count {
                            let listData = self.list[index]
                            if listData.id == newContent.id || listData.id == newContent.reblog_id || listData.reblog_id == newContent.reblog_id || listData.reblog_id == newContent.id {
                                self.list[index] = newContent
                                break
                            }
                            // タイムラインの方が古いので、その前に追加する
                            if (listData.id ?? "") < (newContent.reblog_id ?? "") {
                                self.list.insert(newContent, at: index)
                                
                                // 選択位置がずれないようにする
                                if self.selectedRow != nil && index < self.selectedRow! {
                                    self.selectedRow = self.selectedRow! + 1
                                }
                                break
                            }
                            index += 1
                        }
                    }
                } else if lastDate1 > firstDate2 {
                    // 後に付ければ良い
                    self.list = self.list + addList2
                    
                    if self.list.count > 100000 {
                        // 10万トゥートを超えると流石に削除する
                        self.list.removeFirst(self.list.count - 100000)
                    }
                } else if lastDate2 > firstDate1 {
                    if isNewRefresh && addList.count >= 40 {
                        // 再読み込み用のセルをつける
                        self.list.insert(AnalyzeJson.emptyContentData(), at: 0)
                    }
                    // 前に付ければ良い
                    self.list = addList2 + self.list
                    
                    // 選択位置がずれないようにする
                    if self.selectedRow != nil {
                        self.selectedRow = self.selectedRow! + addList2.count
                    }
                    
                    if addList2.count <= 3 && tableView.contentOffset.y <= 60 {
                        // 一番上の場合、ずれさせる
                    } else {
                        DispatchQueue.main.async {
                            // スクロールして、表示していたツイートがあまりずれないようにする
                            let oldOffsetY = tableView.contentOffset.y
                            let indexPath = IndexPath(row: addList2.count, section: 0)
                            tableView.scrollToRow(at: indexPath,
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
                        var flag = false
                        while index < self.list.count {
                            let listData = self.list[index]
                            if listData.id == newContent.id {
                                // 更新
                                self.list[index] = newContent
                                flag = true
                                break
                            }
                            // タイムラインの方が古いので、その前に追加する
                            if (listData.id ?? "") < (newContent.id ?? "") {
                                self.list.insert(newContent, at: index)
                                flag = true
                                
                                // 選択位置がずれないようにする
                                if self.selectedRow != nil && index < self.selectedRow! {
                                    self.selectedRow = self.selectedRow! + 1
                                }
                                
                                break
                            }
                            index += 1
                        }
                        if !flag {
                            self.list.append(newContent)
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
                    // 選択位置がずれないようにする
                    if self.selectedRow != nil && index < self.selectedRow! {
                        self.selectedRow = self.selectedRow! - 1
                    }
                    
                    // 削除
                    self.list.remove(at: index)
                    tableView.reloadData()
                    break
                }
            }
        }
    }
    
    // 途中読み込みセルをタップしたら
    @objc func reloadOld(_ sender: UIButton) {
        // 一番上で見つかった途中読み込みセルより前をすべて消す
        for (index, data) in self.list.enumerated() {
            if data.id == nil {
                self.list.removeLast(self.list.count - index)
                if let tableView = sender.superview?.superview as? UITableView {
                    tableView.reloadData()
                }
                break
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
    
    // セルのだいたいの高さ(スクロールバーの表示とスクロール位置の調整用)
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let timelineView = tableView as? TimeLineView {
            if timelineView.type == .user && indexPath.row == 0 {
                let accountData = timelineView.accountList[timelineView.option ?? ""]
                if let count = accountData?.fields?.count {
                    return 350 + CGFloat(count) * 40
                } else {
                    return 350
                }
            }
        }
        
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
            return UIUtils.isIphoneX ? 350 : 300
        }
        
        let isSelected = !SettingsData.tapDetailMode && indexPath.row == self.selectedRow
        
        if SettingsData.isMiniView == .miniView && !isSelected {
            return 23 + SettingsData.fontSize * 1.5
        }
        if SettingsData.isMiniView == .superMini && !isSelected {
            return 10 + SettingsData.fontSize
        }
        
        // メッセージのビューを一度作り、高さを求める
        let (messageView, data, _) = getMessageViewAndData(index: index, indexPath: indexPath, add: false, callback: nil)
        
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
        
        if (data.sensitive == 1 && data.mediaData != nil) { // もっと見る
            detailOffset += 20
        }
        if data.spoiler_text != "" && data.spoiler_text != nil {
            if data.spoiler_text!.count > 15 {
                let spolerTextLabel = UILabel()
                spolerTextLabel.text = data.spoiler_text
                spolerTextLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
                spolerTextLabel.numberOfLines = 0
                spolerTextLabel.lineBreakMode = .byCharWrapping
                spolerTextLabel.frame.size.width = UIScreen.main.bounds.width - 70
                spolerTextLabel.sizeToFit()
                detailOffset += 20 + spolerTextLabel.frame.height
            } else {
                detailOffset += 20 + SettingsData.fontSize + 5
            }
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
    private func getMessageViewAndData(index: Int, indexPath: IndexPath, add: Bool, callback: (()->Void)?) -> (UIView, AnalyzeJson.ContentData, Bool) {
        let data = list[index]
        
        if data.emojis == nil, data.id == cacheId, let cache = self.cache {
            if !add || cache.0.superview == nil {
                return cache
            }
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
            let msgView = dequeueReusableTextView()
            msgView.attributedText = attributedText
            msgView.linkTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: ThemeColor.linkTextColor]
            msgView.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
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
        messageView.frame.size.width = UIScreen.main.bounds.width - (SettingsData.iconSize * 2 + 2)
        if SettingsData.isMiniView == .normal || self.selectedRow == indexPath.row {
            messageView.sizeToFit()
        }
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
    
    // UITextViewをリサイクル
    private static var cacheTextView: [UITextView] = []
    private func dequeueReusableTextView() -> UITextView {
        if let textView = TimeLineViewModel.cacheTextView.popLast() {
            textView.isHidden = false
            return textView
        }
        return MyTextView()
    }
    
    class MyTextView: UITextView {
        override func removeFromSuperview() {
            super.removeFromSuperview()
            TimeLineViewModel.cacheTextView.append(self)
        }
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
        let (messageView, data, isContinue) = getMessageViewAndData(index: index, indexPath: indexPath, add: true, callback: { [weak self] in
            // あとから絵文字が読み込めた場合の更新処理
            if cell.id != id { return }
            if let (messageView, _, _) = self?.getMessageViewAndData(index: index, indexPath: indexPath, add: true, callback: nil) {
                if cell.id != id { return }
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
        })
        
        if data.id == nil && (timelineView.type != .user && timelineView.type != .mentions) {
            // タイムライン途中読み込み用のセル
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.backgroundColor = ThemeColor.viewBgColor
            cell.selectionStyle = .none
            let loadButton = UIButton()
            loadButton.setTitle("🔄", for: .normal)
            loadButton.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: SettingsData.isMiniView == .normal ? 60 : (SettingsData.isMiniView == .miniView ? 44 : 30))
            cell.addSubview(loadButton)
            loadButton.addTarget(self, action: #selector(reloadOld(_:)), for: .touchUpInside)
            return cell
        }
        
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
        cell.reblog_id = data.reblog_id
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
        if (data.sensitive == 1 && data.mediaData != nil) || (data.spoiler_text != nil && data.spoiler_text != "") {
            if data.spoiler_text != nil && data.spoiler_text != "" {
                messageView.isHidden = true
            }
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
            cell.spolerTextLabel?.frame.size.width = UIScreen.main.bounds.width - 70
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
                cell.iconView?.removeFromSuperview()
                if image.imageCount != nil {
                    // GIFアニメーション
                    cell.iconView = WideTouchImageView(gifImage: image, manager: timelineView.gifManager, loopCount: SettingsData.useAnimation ? -1 : 0)
                    if !tableView.visibleCells.contains(cell) {
                        timelineView.gifManager.deleteImageView(cell.iconView!)
                    }
                } else {
                    cell.iconView = WideTouchImageView()
                }
                
                cell.addSubview(cell.iconView!)
                cell.iconView?.image = image
                cell.iconView?.layer.cornerRadius = 5
                cell.iconView?.clipsToBounds = true
                cell.iconView?.insets = UIEdgeInsetsMake(5, 5, 5, 5)
                
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
        DispatchQueue.main.async {
            cell.nameLabel.sizeToFit()
        }
        
        cell.idLabel.text = account?.acct
        
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
            cell.previewUrls = []
            cell.imageUrls = []
            cell.originalUrls = []
            cell.imageTypes = []
            
            for (index, media) in mediaData.enumerated() {
                func addImageView(withPlayButton: Bool) {
                    let imageView = UIImageView()
                    
                    imageView.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
                    imageView.clipsToBounds = true
                    
                    // タップで全画面表示
                    let tapGesture = UITapGestureRecognizer(target: cell, action: #selector(cell.imageTapAction(_:)))
                    imageView.addGestureRecognizer(tapGesture)
                    imageView.isUserInteractionEnabled = true
                    
                    // 画像読み込み
                    let isPreview = !(isDetailTimeline && indexPath.row == selectedRow)
                    ImageCache.image(urlStr: media.preview_url, isTemp: true, isSmall: false, isPreview: isPreview) { image in
                        imageView.image = image
                        imageView.backgroundColor = nil
                        cell.setNeedsLayout()
                    }
                    cell.addSubview(imageView)
                    cell.imageViews.append(imageView)
                    
                    if data.sensitive == 1 || data.spoiler_text != "" {
                        imageView.isHidden = true
                    }
                    
                    cell.previewUrls.append(media.preview_url ?? "")
                    cell.imageUrls.append(media.url ?? "")
                    cell.originalUrls.append(media.remote_url ?? "")
                    cell.imageTypes.append(media.type ?? "")
                    
                    if withPlayButton {
                        // 再生の絵文字を表示
                        let triangleView = UILabel()
                        triangleView.text = "▶️"
                        triangleView.font = UIFont.systemFont(ofSize: 24)
                        triangleView.sizeToFit()
                        imageView.addSubview(triangleView)
                        DispatchQueue.main.async {
                            triangleView.center = CGPoint(x: imageView.bounds.width / 2, y: imageView.bounds.height / 2)
                        }
                    }
                }
                
                if media.type == "unknown" {
                    // 不明
                    addImageView(withPlayButton: false)
                    
                    // リンク先のファイル名を表示
                    let label = UILabel()
                    label.text = String((media.remote_url ?? "").split(separator: "/").last ?? "")
                    label.textAlignment = .center
                    label.numberOfLines = 0
                    label.lineBreakMode = .byCharWrapping
                    label.textColor = ThemeColor.linkTextColor
                    cell.imageViews.last?.addSubview(label)
                    DispatchQueue.main.async {
                        label.frame = cell.imageViews.last?.bounds ?? CGRect(x: 0, y: 0, width: 0, height: 0)
                    }
                } else if media.type == "gifv" || media.type == "video" {
                    // 動画の場合
                    if indexPath.row == selectedRow {
                        // とりあえずプレビューを表示
                        addImageView(withPlayButton: false)
                        
                        // 動画読み込み
                        MovieCache.movie(urlStr: media.url) { player, queuePlayer, looper in
                            if let player = player {
                                // レイヤーの追加
                                let playerLayer = AVPlayerLayer(player: player)
                                cell.layer.addSublayer(playerLayer)
                                cell.movieLayers.append(playerLayer)
                                
                                if index < cell.imageViews.count {
                                    cell.layoutSubviews()
                                    playerLayer.frame = cell.imageViews[index].frame
                                }
                                
                                // 再生
                                player.play()
                                
                                if data.sensitive == 1 || data.spoiler_text != "" {
                                    playerLayer.isHidden = true
                                }
                            } else {
                                if #available(iOS 10.0, *) {
                                    if let queuePlayer = queuePlayer as? AVQueuePlayer, let looper = looper as? AVPlayerLooper {
                                        // レイヤーの追加
                                        let playerLayer = AVPlayerLayer(player: queuePlayer)
                                        cell.layer.addSublayer(playerLayer)
                                        cell.movieLayers.append(playerLayer)
                                        cell.looper = looper
                                        
                                        if index < cell.imageViews.count {
                                            cell.layoutSubviews()
                                            playerLayer.frame = cell.imageViews[index].frame
                                        }
                                        
                                        // ループ再生
                                        queuePlayer.play()
                                        
                                        if data.sensitive == 1 || data.spoiler_text != "" {
                                            playerLayer.isHidden = true
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        addImageView(withPlayButton: true)
                    }
                } else {
                    // 静止画の場合
                    addImageView(withPlayButton: false)
                }
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
            var username = account?.display_name ?? ""
            if username == "" {
                username = account?.acct ?? ""
            }
            let name = String(format: I18n.get("BOOSTED_BY_%@"), username)
            cell.boostView?.attributedText = DecodeToot.decodeName(name: name, emojis: account?.emojis, callback: nil)
            cell.addSubview(cell.boostView!)
        }
        
        // もっと見るの場合
        if (data.sensitive == 1 && data.mediaData != nil) || (data.spoiler_text != "" && data.spoiler_text != nil) {
            cell.showMoreButton = UIButton()
            cell.showMoreButton?.setTitle(I18n.get("BUTTON_SHOW_MORE"), for: .normal)
            cell.showMoreButton?.setTitleColor(ThemeColor.nameColor, for: .normal)
            cell.showMoreButton?.addTarget(cell, action: #selector(cell.showMoreAction), for: .touchUpInside)
            cell.addSubview(cell.showMoreButton!)
            
            if let id = data.id, id != "" && TimeLineViewCell.showMoreList.contains(id) {
                // すでに解除済み
                cell.showMoreAction(forceShow: true)
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
            getBoosterAndFavoriter(data: data, cell: cell)
        }
        
        return cell
    }
    
    // トゥートを更新してからブーストした人やお気に入りした人を取得する
    private var waitingQueryId: String? = nil
    private func getBoosterAndFavoriter(data: AnalyzeJson.ContentData, cell: TimeLineViewCell) {
        if self.waitingQueryId == data.id {
            // 2回目が来たらリクエスト発行
            self.waitingQueryId = nil
            self.getBoosterAndFavoriterInner(data: data, cell: cell)
            return
        }
        self.waitingQueryId = data.id
        
        // 2秒以内にリクエストが来なければ発行
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if self.waitingQueryId == nil {
                return
            }
            self.getBoosterAndFavoriterInner(data: data, cell: cell)
        }
    }
    
    private func getBoosterAndFavoriterInner(data: AnalyzeJson.ContentData, cell: TimeLineViewCell) {
        if cell.id != data.id { return }
        
        let id = data.id
        
        // ブーストした人の名前を表示
        let reblogs_count = data.reblogs_count ?? 0
        if reblogs_count > 0 || data.reblogged == 1 {
            if let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/statuses/\(data.reblog_id ?? data.id ?? "")/reblogged_by?limit=10") {
                try? MastodonRequest.get(url: url) { (data, response, error) in
                    if cell.id != id { return }
                    if let data = data {
                        do {
                            if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: AnyObject]] {
                                DispatchQueue.main.async {
                                    var count = 0
                                    for json in responseJson {
                                        let accountData = AnalyzeJson.analyzeAccountJson(account: json)
                                        if count >= 10 { break }
                                        if cell.rebologerLabels.count <= count {
                                            let label = BoosterLabel()
                                            cell.rebologerLabels.append(label)
                                            label.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
                                            label.textColor = ThemeColor.idColor
                                            cell.addSubview(label)
                                            
                                            label.accountData = accountData
                                            label.setGesture()
                                        }
                                        let label = cell.rebologerLabels[count]
                                        label.attributedText = DecodeToot.decodeName(name: "🔁 " + (accountData.display_name ?? "") + " " + (accountData.acct ?? ""), emojis: accountData.emojis, callback: nil)
                                        count += 1
                                    }
                                    cell.setNeedsLayout()
                                }
                            }
                        } catch { }
                    }
                }
            }
        }
        
        // お気に入りした人の名前を表示
        let favourites_count = data.favourites_count ?? 0
        if favourites_count > 0 || data.favourited == 1 {
            if let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/statuses/\(data.reblog_id ?? data.id ?? "")/favourited_by?limit=10") {
                try? MastodonRequest.get(url: url) { (data, response, error) in
                    if cell.id != id { return }
                    if let data = data {
                        do {
                            if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: AnyObject]] {
                                DispatchQueue.main.async {
                                    var count = 0
                                    for json in responseJson {
                                        let accountData = AnalyzeJson.analyzeAccountJson(account: json)
                                        if count >= 10 { break }
                                        if cell.favoriterLabels.count <= count {
                                            let label = BoosterLabel()
                                            cell.favoriterLabels.append(label)
                                            label.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
                                            label.textColor = ThemeColor.idColor
                                            cell.addSubview(label)
                                            
                                            label.accountData = accountData
                                            label.setGesture()
                                        }
                                        let label = cell.favoriterLabels[count]
                                        label.attributedText = DecodeToot.decodeName(name: "⭐️ " + (accountData.display_name ?? "") + " " + (accountData.acct ?? ""), emojis: accountData.emojis, callback: nil)
                                        count += 1
                                    }
                                    cell.setNeedsLayout()
                                }
                            }
                        } catch { }
                    }
                }
            }
        }
    }
    
    private class BoosterLabel: UILabel {
        var accountData: AnalyzeJson.AccountData? = nil
        
        func setGesture() {
            self.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))
            self.addGestureRecognizer(tapGesture)
        }
        
        @objc func tapAction() {
            if let accountId = self.accountData?.id {
                if let timelineView = self.superview?.superview as? TimeLineView {
                    if timelineView.option == accountId {
                        return
                    }
                }
                
                let accountTimeLineViewController = TimeLineViewController(type: TimeLineViewController.TimeLineType.user, option: accountId)
                if let timelineView = accountTimeLineViewController.view as? TimeLineView, let accountData = self.accountData {
                    timelineView.accountList.updateValue(accountData, forKey: accountId)
                }
                UIUtils.getFrontViewController()?.addChildViewController(accountTimeLineViewController)
                UIUtils.getFrontViewController()?.view.addSubview(accountTimeLineViewController.view)
                accountTimeLineViewController.view.frame = CGRect(x: UIScreen.main.bounds.width,
                                                                  y: 0,
                                                                  width: UIScreen.main.bounds.width,
                                                                  height: UIScreen.main.bounds.height)
                UIView.animate(withDuration: 0.3) {
                    accountTimeLineViewController.view.frame.origin.x = 0
                }
            }
        }
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
        
        if SettingsData.isMiniView == .superMini {
            cell.nameLabel.isHidden = true
            cell.idLabel.isHidden = true
            cell.dateLabel.isHidden = true
        } else {
            cell.nameLabel.isHidden = false
            cell.idLabel.isHidden = false
            cell.dateLabel.isHidden = false
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? TimeLineViewCell else { return }
        
        if cell.iconView?.image?.imageCount != nil {
            _ = (tableView as? TimeLineView)?.gifManager.addImageView(cell.iconView!)
        }
        
        // タイマーでN秒ごとに時刻を更新
        if #available(iOS 10.0, *) {
            let interval: TimeInterval
            if Date().timeIntervalSince(cell.date) < 60 {
                interval = 5
            } else if Date().timeIntervalSince(cell.date) < 600 {
                interval = 15
            } else {
                interval = 60
            }
            
            cell.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { timer in
                if cell.superview == nil {
                    return
                }
                
                cell.refreshDate()
            })
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? TimeLineViewCell else { return }
        
        if cell.iconView?.image?.imageCount != nil {
            (tableView as? TimeLineView)?.gifManager.deleteImageView(cell.iconView!)
        }
        
        cell.timer?.invalidate()
    }
    
    // セル選択時の処理
    private var isAnimating = false
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
            
            // 連打防止
            if self.isAnimating { return }
            self.isAnimating = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isAnimating = false
            }
            
            // トゥート詳細画面に移動
            let (_, data, _) = getMessageViewAndData(index: index, indexPath: indexPath, add: true, callback: nil)
            let mentionsData = getMentionsData(data: data)
            let viewController = TimeLineViewController(type: TimeLineViewController.TimeLineType.mentions, option: nil, mentions: (mentionsData, accountList))
            UIUtils.getFrontViewController()?.addChildViewController(viewController)
            UIUtils.getFrontViewController()?.view.addSubview(viewController.view)
            viewController.view.frame = CGRect(x: UIScreen.main.bounds.width,
                                               y: 0,
                                               width: UIScreen.main.bounds.width,
                                               height: UIScreen.main.bounds.height)
            UIView.animate(withDuration: 0.3) {
                viewController.view.frame.origin.x = 0
            }
            
            tableView.deselectRow(at: indexPath, animated: true)
            
            // ステータスの内容を更新する(お気に入りの数とか)
            guard let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/statuses/\(data.id ?? "-")") else { return }
            try? MastodonRequest.get(url: url) { [weak self] (data, response, error) in
                guard let strongSelf = self else { return }
                guard let data = data else { return }
                do {
                    if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject] {
                        var acct = ""
                        let contentData = AnalyzeJson.analyzeJson(view: tableView as? TimeLineView, model: strongSelf, json: responseJson, acct: &acct)
                        let contentList = [contentData]
                        
                        // 詳細ビューと元のビューの両方に反映する
                        strongSelf.change(tableView: tableView as! TimeLineView, addList: contentList, accountList: strongSelf.accountList)
                        if let tlView = viewController.view as? TimeLineView {
                            tlView.model.change(tableView: tlView, addList: contentList, accountList: tlView.accountList)
                        }
                    }
                } catch { }
            }
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
            let viewController = TimeLineViewController(type: TimeLineViewController.TimeLineType.federationTag,
                                                        option: String(Url.path.suffix(Url.path.count - 6)))
            UIUtils.getFrontViewController()?.addChildViewController(viewController)
            UIUtils.getFrontViewController()?.view.addSubview(viewController.view)
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
                    UIUtils.getFrontViewController()?.addChildViewController(viewController)
                    UIUtils.getFrontViewController()?.view.addSubview(viewController.view)
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
