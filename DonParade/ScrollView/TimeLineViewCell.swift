//
//  TimeLineViewCell.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/17.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// トゥートの内容を表示するセル

import UIKit
import APNGKit
import AVFoundation
import AVKit
import SafariServices

final class TimeLineViewCell: UITableViewCell {
    static var showMoreList: [String] = []
    static let iconViewTag = 48947229
    
    var id = "" // トゥートのID
    var reblog_id: String? = nil
    
    // 基本ビュー
    let lineLayer = CALayer()
    var iconView: WideTouchImageView?
    let nameLabel = UILabel()
    let idLabel = UILabel()
    let dateLabel = UILabel()
    var messageView: UIView?
    
    //追加ビュー
    var continueView: UILabel? // 長すぎるトゥートで、続きがあることを表示
    var boostView: UILabel? // 誰がboostしたかを表示
    var imageViews: [UIImageView] = [] // 添付画像を表示
    var movieLayers: [AVPlayerLayer] = []
    var looper: Any? //AVPlayerLooper?
    var showMoreButton: UIButton? // もっと見る
    var spolerTextLabel: UILabel?
    var detailDateLabel: UILabel?
    var DMBarLeft: UIView?
    var DMBarRight: UIView?
    var pinnedView: UILabel?
    var rightFavButton: UIButton?
    
    // 詳細ビュー
    var showDetail = false
    var replyButton: UIButton?
    var repliedLabel: UILabel?
    var boostButton: UIButton?
    var boostedLabel: UILabel?
    var favoriteButton: UIButton?
    var favoritedLabel: UILabel?
    var detailButton: UIButton?
    var applicationLabel: UILabel?
    var cardView: CardView?
    var pollView: PollView?
    
    // お気に入りした人やブーストした人の名前表示
    var rebologerLabels: [UILabel] = []
    var rebologerList: [String]?
    var favoriterLabels: [UILabel] = []
    var favoriterList: [String]?
    
    weak var tableView: TimeLineView?
    var indexPath: IndexPath?
    var date: Date
    var timer: Timer?
    var accountId: String?
    var accountData: AnalyzeJson.AccountData?
    var contentData: String = ""
    var urlStr: String = ""
    var mentionsList: [AnalyzeJson.MentionData]?
    var isMiniView = SettingsData.MiniView.normal
    var imageUrls: [String] = []
    var originalUrls: [String] = []
    var imageTypes: [String] = []
    var previewUrls: [String] = []
    var visibility: String?
    
    var isFaved = false
    var isBoosted = false
    var isPinned = false
    var isBookmarked = false
    
    // セルの初期化
    init(reuseIdentifier: String?) {
        self.date = Date()
        
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        
        // デフォルトのテキストラベルは不要
        self.textLabel?.removeFromSuperview()
        self.detailTextLabel?.removeFromSuperview()
        
        // 固定プロパティは初期化時に設定
        self.clipsToBounds = true
        self.backgroundColor = ThemeColor.cellBgColor
        self.isOpaque = true
        self.selectionStyle = .none
        
        self.nameLabel.textColor = ThemeColor.nameColor
        self.nameLabel.font = UIFont.boldSystemFont(ofSize: SettingsData.fontSize)
        self.nameLabel.backgroundColor = ThemeColor.cellBgColor
        self.nameLabel.isOpaque = true
        
        self.idLabel.textColor = ThemeColor.idColor
        self.idLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize - 2)
        self.idLabel.backgroundColor = ThemeColor.cellBgColor
        self.idLabel.isOpaque = true
        
        self.dateLabel.textColor = ThemeColor.dateColor
        self.dateLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize - 2)
        self.dateLabel.textAlignment = .right
        self.dateLabel.backgroundColor = ThemeColor.cellBgColor
        self.dateLabel.adjustsFontSizeToFitWidth = true
        self.dateLabel.isOpaque = true
        
        self.lineLayer.backgroundColor = ThemeColor.separatorColor.cgColor
        self.lineLayer.isOpaque = true
        
        // addする
        self.addSubview(self.idLabel)
        self.addSubview(self.dateLabel)
        self.addSubview(self.nameLabel)
        self.layer.addSublayer(self.lineLayer)
        
        if SettingsData.isNameTappable {
            // アカウント名のタップジェスチャー
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAccountAction))
            self.nameLabel.addGestureRecognizer(tapGesture)
            self.nameLabel.isUserInteractionEnabled = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 再利用前に呼ばれる
    override func prepareForReuse() {
        self.id = ""
        self.showDetail = false
        while let apngBackView = self.messageView?.viewWithTag(5555) {
            if let apngView = apngBackView.subviews.first as? APNGImageView {
                apngView.stopAnimating()
                apngView.removeFromSuperview()
            }
            apngBackView.removeFromSuperview()
        }
        self.messageView?.removeFromSuperview()
        self.messageView = nil
        self.continueView?.removeFromSuperview()
        self.continueView = nil
        self.boostView?.removeFromSuperview()
        self.boostView = nil
        self.showMoreButton?.removeFromSuperview()
        self.showMoreButton = nil
        self.spolerTextLabel?.removeFromSuperview()
        self.spolerTextLabel = nil
        self.detailDateLabel?.removeFromSuperview()
        self.detailDateLabel = nil
        self.DMBarLeft?.removeFromSuperview()
        self.DMBarLeft = nil
        self.DMBarRight?.removeFromSuperview()
        self.DMBarRight = nil
        for label in self.rebologerLabels {
            label.removeFromSuperview()
        }
        self.rebologerLabels = []
        self.rebologerList = nil
        for label in self.favoriterLabels {
            label.removeFromSuperview()
        }
        self.favoriterLabels = []
        self.favoriterList = nil
        for imageView in self.imageViews {
            imageView.removeFromSuperview()
        }
        self.imageViews = []
        for playerLayer in self.movieLayers {
            playerLayer.player?.pause()
            playerLayer.removeFromSuperlayer()
        }
        self.movieLayers = []
        self.looper = nil
        if self.replyButton != nil {
            self.replyButton?.removeFromSuperview()
            self.repliedLabel?.removeFromSuperview()
            self.boostButton?.removeFromSuperview()
            self.boostedLabel?.removeFromSuperview()
            self.favoriteButton?.removeFromSuperview()
            self.favoritedLabel?.removeFromSuperview()
            self.detailButton?.removeFromSuperview()
            self.applicationLabel?.removeFromSuperview()
            
            self.replyButton = nil
            self.repliedLabel = nil
            self.boostButton = nil
            self.boostedLabel = nil
            self.favoriteButton = nil
            self.favoritedLabel = nil
            self.detailButton = nil
            self.applicationLabel = nil
        }
        self.iconView?.removeFromSuperview()
        self.iconView?.image = nil
        for gesture in self.iconView?.gestureRecognizers ?? [] {
            self.iconView?.removeGestureRecognizer(gesture)
        }
        self.iconView = nil
        if let view = self.viewWithTag(TimeLineViewCell.iconViewTag) {
            view.removeFromSuperview()
        }
        self.cardView?.removeFromSuperview()
        self.cardView = nil
        self.pollView?.removeFromSuperview()
        self.pollView = nil
        self.pinnedView?.removeFromSuperview()
        self.pinnedView = nil
        self.rightFavButton?.removeFromSuperview()
        self.rightFavButton = nil
        
        while let apngView = self.nameLabel.viewWithTag(5555) as? APNGImageView {
            apngView.stopAnimating()
            apngView.removeFromSuperview()
        }
        
        // フォントサイズと色を指定
        self.nameLabel.textColor = ThemeColor.nameColor
        self.nameLabel.font = UIFont.boldSystemFont(ofSize: SettingsData.fontSize)
        
        self.idLabel.textColor = ThemeColor.idColor
        self.idLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize - 2)
        
        self.dateLabel.textColor = ThemeColor.dateColor
        self.dateLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize - 2)
        
        self.lineLayer.backgroundColor = ThemeColor.separatorColor.cgColor
    }
    
    // アイコンをタップした時の処理
    private static var doubleTapFlag = false
    @objc func tapAccountAction() {
        if TimeLineViewCell.doubleTapFlag { return }
        TimeLineViewCell.doubleTapFlag = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            TimeLineViewCell.doubleTapFlag = false
        }
        
        if TootViewController.isShown {
            // トゥート画面表示中は移動せず、@IDを入力する
            pressAccountAction(nil)
            return
        }
        
        if let accountId = self.accountId {
            if let timelineView = self.superview as? TimeLineView {
                if timelineView.option == accountId {
                    return
                }
            }
            
            let accountTimeLineViewController = TimeLineViewController(type: TimeLineViewController.TimeLineType.user, option: accountId)
            if let timelineView = accountTimeLineViewController.view as? TimeLineView, let accountData = self.accountData {
                timelineView.accountList.updateValue(accountData, forKey: accountId)
            }
            UIUtils.getFrontViewController()?.addChild(accountTimeLineViewController)
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
    
    // アイコンを長押しした時の処理
    @objc func pressAccountAction(_ gesture: UILongPressGestureRecognizer?) {
        if let gesture = gesture, gesture.state != .began { return }
        
        // トゥート画面を開いていなければ開く
        if !TootViewController.isShown {
            MainViewController.instance?.tootAction(nil)
        }
        
        // @IDを入力する
        DispatchQueue.main.asyncAfter(deadline: .now() + (TootViewController.isShown ? 0.0 : 0.2)) {
            if let vc = TootViewController.instance, let view = vc.view as? TootView {
                if let text = view.textField.text, text.count > 0 {
                    let spaceString = text.last == " " ? "" : " "
                    view.textField.text = text + spaceString + "@\(self.idLabel.text ?? "") "
                } else {
                    view.textField.text = "@\(self.idLabel.text ?? "") "
                }
            }
        }
    }
    
    // リプライボタンをタップした時の処理
    @objc func replyAction() {
        if TootViewController.isShown, let vc = TootViewController.instance, let view = vc.view as? TootView, let text = view.textField.text, text.count > 0 {
            Dialog.show(message: I18n.get("ALERT_TEXT_EXISTS"))
        } else {
            // 返信先を設定
            TootView.inReplyToId = self.id
            TootView.inReplyToContent = (self.nameLabel.text ?? "") + " " + (self.idLabel.text ?? "") + "\n"
            if let messageView = self.messageView as? UILabel {
                TootView.inReplyToContent! += String(messageView.text ?? "")
            } else if let messageView = self.messageView as? UITextView {
                TootView.inReplyToContent! += String(messageView.text ?? "")
            }
            
            // トゥート画面を開いていなければ開く
            if !TootViewController.isShown {
                MainViewController.instance?.tootAction(nil)
                
                // 公開範囲を低い方に合わせる
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    // 公開範囲設定を変更
                    if let visibility = self.visibility {
                        guard let view = TootViewController.instance?.view as? TootView else { return }
                        
                        var mode = TimeLineViewCell.lowerVisibility(m1: SettingsData.ProtectMode(rawValue: visibility),
                                                        m2: SettingsData.protectMode)
                        if mode == SettingsData.ProtectMode.publicMode {
                            mode = SettingsData.ProtectMode.unlisted // inreplytoではLTLに流さない
                        }
                        view.protectMode = mode
                        view.refresh()
                    }
                }
            } else {
                (TootViewController.instance?.view as? TootView)?.inReplyToLabel.text = "↩︎"
            }
            
            // @IDを入力する
            DispatchQueue.main.asyncAfter(deadline: .now() + (TootViewController.isShown ? 0.0 : 0.2)) {
                if let vc = TootViewController.instance, let view = vc.view as? TootView {
                    view.textField.text = "@\(self.idLabel.text ?? "") "
                    
                    do {
                        let string = (self.messageView as? UITextView)?.text ?? (self.messageView as? UITextField)?.text ?? ""
                        let regex = try? NSRegularExpression(pattern: "@[a-zA-Z0-9_]+",
                                                             options: NSRegularExpression.Options())
                        let matches = regex?.matches(in: string,
                                                     options: NSRegularExpression.MatchingOptions(),
                                                     range: NSMakeRange(0, string.count))
                        for result in matches ?? [] {
                            for i in 0..<result.numberOfRanges {
                                let idStr = (string as NSString).substring(with: result.range(at: i))
                                if idStr != "@" + (SettingsData.accountUsername(accessToken: SettingsData.accessToken ?? "") ?? "") && idStr != "@\(self.idLabel.text ?? "")" {
                                    view.textField.text += idStr + " "
                                }
                            }
                        }
                    }
                }
                
                if let acctStr = self.idLabel.text {
                    SettingsData.addRecentMention(key: acctStr)
                }
            }
        }
    }
    
    // 低い方の公開範囲を返す
    static func lowerVisibility(m1: SettingsData.ProtectMode?, m2: SettingsData.ProtectMode) -> SettingsData.ProtectMode {
        guard let m1 = m1 else { return m2 }
        
        let v1: Int
        switch m1 {
        case .direct:
            v1 = 0
        case .privateMode:
            v1 = 1
        case .unlisted:
            v1 = 2
        case .publicMode:
            v1 = 3
        }
        
        let v2: Int
        switch m2 {
        case .direct:
            v2 = 0
        case .privateMode:
            v2 = 1
        case .unlisted:
            v2 = 2
        case .publicMode:
            v2 = 3
        }
        
        let v = min(v1, v2)
        
        switch v {
        case 0:
            return .direct
        case 1:
            return .privateMode
        case 2:
            return .unlisted
        case 3:
            return .publicMode
        default:
            return .publicMode
        }
    }
    
    // ブーストボタンをタップした時の処理
    @objc func boostAction() {
        self.boostButton?.isHidden = true
        
        tableView?.boostAction(id: self.reblog_id ?? self.id, isBoosted: self.isBoosted)
    }
    
    // お気に入りボタンをタップした時の処理
    @objc func favoriteAction() {
        let id = self.reblog_id ?? self.id
        let isFaved = self.isFaved
        
        func favAction() {
            self.favoriteButton?.isHidden = true
            self.rightFavButton?.isHidden = true
            
            tableView?.favoriteAction(id: id, isFaved: isFaved)
        }
        
        if SettingsData.showFavDialog {
            Dialog.show(message: isFaved ? I18n.get("ALERT_UNFAVORITE") : I18n.get("ALERT_FAVORITE"),
                        okName: isFaved ? I18n.get("BUTTON_UNFAVORITE") : I18n.get("BUTTON_FAVORITE"),
                        cancelName: I18n.get("BUTTON_CANCEL")) { result in
                            if result {
                                favAction()
                            }
            }
        } else {
            favAction()
        }
    }
    
    // 「・・・」ボタンをタップした時の処理
    @objc func detailAction() {
        if self.tableView?.type == .scheduled {
            detailScheduledAction()
            return
        }
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        // 選択解除
        alertController.addAction(UIAlertAction(
            title: I18n.get("ACTION_DESELECT"),
            style: UIAlertAction.Style.default,
            handler: { _ in
                self.tableView?.model.clearSelection()
                self.tableView?.reloadData()
        }))
        
        if self.accountId == SettingsData.accountNumberID(accessToken: SettingsData.accessToken ?? "") {
            // トゥートを削除
            alertController.addAction(UIAlertAction(
                title: I18n.get("ACTION_DELETE_TOOT"),
                style: UIAlertAction.Style.destructive,
                handler: { _ in
                    guard let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/statuses/\(self.id)") else { return }
                    try? MastodonRequest.delete(url: url, completionHandler: { (data, response, error) in
                        if let error = error {
                            Dialog.show(message: I18n.get("ALERT_DELETE_TOOT_FAILURE") + "\n " + error.localizedDescription)
                        }
                    })
            }))
        }
        
        // 通報する
        guard let accountId = self.accountId else { return }
        let id = self.id
        
        alertController.addAction(UIAlertAction(
            title: I18n.get("ACTION_REPORT_TOOT"),
            style: UIAlertAction.Style.destructive,
            handler: { _ in
                Dialog.showWithTextInput(
                    message: I18n.get("ALERT_INPUT_REPORT_REASON"),
                    okName: I18n.get("BUTTON_REPORT"),
                    cancelName: I18n.get("BUTTON_CANCEL"),
                    defaultText: nil,
                    callback: { textField, result in
                        if !result { return }
                        
                        if textField.text == nil || textField.text!.count == 0 {
                            Dialog.show(message: I18n.get("ALERT_REASON_IS_NIL"))
                            return
                        }
                        
                        guard let hostName = SettingsData.hostName else { return }
                        
                        let url = URL(string: "https://\(hostName)/api/v1/reports")!
                        
                        let bodyDict = ["account_id": accountId,
                                        "status_ids": id,
                                        "comment": textField.text!]
                        
                        try? MastodonRequest.post(url: url, body: bodyDict) { (data, response, error) in
                            if let error = error {
                                Dialog.show(message: I18n.get("ALERT_REPORT_TOOT_FAILURE") + "\n" + error.localizedDescription)
                            } else {
                                if let response = response as? HTTPURLResponse {
                                    if response.statusCode == 200 {
                                        //
                                    } else {
                                        Dialog.show(message: I18n.get("ALERT_REPORT_TOOT_FAILURE") + "\nHTTP status \(response.statusCode)")
                                    }
                                }
                            }
                        }
                })
        }))
        
        // ペーストボードにコピー
        alertController.addAction(UIAlertAction(
            title: I18n.get("ACTION_COPY_TOOT"),
            style: UIAlertAction.Style.default,
            handler: { _ in
                self.copyToot()
        }))
        
        // Safariで開く
        alertController.addAction(UIAlertAction(
            title: I18n.get("ACTION_OPEN_WITH_SAFARI"),
            style: UIAlertAction.Style.default,
            handler: { _ in
                guard let url = URL(string: self.urlStr) else { return }
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
        }))
        
        /*
         // 生データを表示
         alertController.addAction(UIAlertAction(
         title: "生データを表示",
         style: UIAlertActionStyle.default,
         handler: { _ in
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
         Dialog.show(message: self.contentData)
         }
         }))*/
        
        // 固定トゥートにする/解除する
        if self.accountId == SettingsData.accountNumberID(accessToken: SettingsData.accessToken ?? "") {
            alertController.addAction(UIAlertAction(
                title: self.isPinned ? I18n.get("ACTION_UNPIN") : I18n.get("ACTION_PIN"),
                style: UIAlertAction.Style.default,
                handler: { _ in
                    self.tableView?.pinAction(id: id, isPinned: self.isPinned)
            }))
        }
        
        // このサーバーのタイムラインを見る
        if self.accountData?.acct?.contains("@") == true {
            let accountHostName = String((self.accountData?.acct ?? "").split(separator: "@").last ?? "")
            alertController.addAction(UIAlertAction(
                title: I18n.get("ACTION_SHOW_OTHER_LTL"),
                style: UIAlertAction.Style.default,
                handler: { _ in
                    guard let url = URL(string: "https://\(accountHostName)/public") else { return }
                    let controller = SFSafariViewController(url: url)
                    UIUtils.getFrontViewController()?.present(controller, animated: true)
            }))
        }
        
        // ブックマークする/解除する
        alertController.addAction(UIAlertAction(
            title: self.isBookmarked ? I18n.get("ACTION_UNBOOKMARK") : I18n.get("ACTION_BOOKMARK"),
            style: UIAlertAction.Style.default,
            handler: { _ in
                self.tableView?.bookmarkAction(id: id, isBookmarked: self.isBookmarked)
        }))
        
        // キャンセル
        alertController.addAction(UIAlertAction(
            title: I18n.get("BUTTON_CANCEL"),
            style: UIAlertAction.Style.cancel,
            handler: { _ in
        }))
        
        UIUtils.getFrontViewController()?.present(alertController, animated: true, completion: nil)
    }
    
    // 「・・・」ボタンをタップした時の処理
    @objc func detailScheduledAction() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        // トゥートを削除
        alertController.addAction(UIAlertAction(
            title: I18n.get("ACTION_DELETE_TOOT"),
            style: UIAlertAction.Style.destructive,
            handler: { _ in
                guard let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/scheduled_statuses/\(self.id)") else { return }
                try? MastodonRequest.delete(url: url, completionHandler: { (data, response, error) in
                    if let error = error {
                        Dialog.show(message: I18n.get("ALERT_DELETE_TOOT_FAILURE") + "\n " + error.localizedDescription)
                    } else {
                        DispatchQueue.main.async {
                            var vc = UIUtils.getFrontViewController()
                            while vc?.children.last != nil {
                                vc = vc?.children.last
                            }
                            if let vc = vc as? TimeLineViewController, let view = vc.view as? TimeLineView, view.type == .scheduled {
                                vc.closeAction()
                            }
                        }
                    }
                })
        }))
        
        // ペーストボードにコピー
        alertController.addAction(UIAlertAction(
            title: I18n.get("ACTION_COPY_TOOT"),
            style: UIAlertAction.Style.default,
            handler: { _ in
                self.copyToot()
        }))
        
        // キャンセル
        alertController.addAction(UIAlertAction(
            title: I18n.get("BUTTON_CANCEL"),
            style: UIAlertAction.Style.cancel,
            handler: { _ in
        }))
        
        UIUtils.getFrontViewController()?.present(alertController, animated: true, completion: nil)
    }
    
    // ペーストボードにコピー
    private func copyToot() {
        let spoilerText: String
        if let attrtext = self.spolerTextLabel?.attributedText {
            spoilerText = DecodeToot.encodeEmoji(attributedText: attrtext, textStorage: NSTextStorage(attributedString: attrtext))
        } else {
            spoilerText = ""
        }
        
        let text: String
        if let label = self.messageView as? UILabel, let attrtext = label.attributedText {
            text = DecodeToot.encodeEmoji(attributedText: attrtext, textStorage: NSTextStorage(attributedString: attrtext))
        } else if let textView = self.messageView as? UITextView, let attrtext = textView.attributedText {
            text = DecodeToot.encodeEmoji(attributedText: attrtext, textStorage: textView.textStorage)
        } else {
            text = ""
        }
        
        let finalText: String
        if spoilerText != "" && text != "" {
            finalText = spoilerText + "\n" + text
        } else if spoilerText != "" {
            finalText = spoilerText
        } else {
            finalText = text
        }
        
        UIPasteboard.general.string = finalText
    }
    
    // もっと見る
    @objc func showMoreAction(forceShow: Bool = true) {
        if !forceShow && TimeLineViewCell.showMoreList.contains(self.id) {
            // やっぱり隠す
            for (index, data) in TimeLineViewCell.showMoreList.enumerated() {
                if data == self.id {
                    TimeLineViewCell.showMoreList.remove(at: index)
                    break
                }
            }
            if self.spolerTextLabel?.text != "" {
                self.messageView?.isHidden = true
            }
            for imageView in self.imageViews {
                imageView.isHidden = true
            }
            cardView?.isHidden = true
            self.showMoreButton?.setTitle(I18n.get("BUTTON_SHOW_MORE"), for: .normal)
            return
        }
        
        self.messageView?.isHidden = false
        for imageView in self.imageViews {
            imageView.isHidden = false
        }
        cardView?.isHidden = false
        
        self.showMoreButton?.setTitle(I18n.get("BUTTON_HIDE_REDO"), for: .normal)
        
        if !TimeLineViewCell.showMoreList.contains(self.id) && self.id != "" {
            TimeLineViewCell.showMoreList.append(self.id)
        }
    }
    
    // 画像をタップ
    @objc func imageTapAction(_ gesture: UITapGestureRecognizer) {
        for (index, imageView) in self.imageViews.enumerated() {
            if imageView == gesture.view {
                if imageTypes[index] == "unknown" && imageView.image == nil {
                    // 分からんので内蔵ブラウザで開く
                    guard let url = URL(string: originalUrls[index]) else { return }
                    let safariVC = SFSafariViewController(url: url)
                    UIUtils.getFrontViewController()?.present(safariVC, animated: true, completion: nil)
                } else if imageTypes[index] == "video" || imageTypes[index] == "gifv" {
                    // 動画
                    let waitIndicator = WaitIndicator()
                    UIUtils.getFrontViewController()?.view.addSubview(waitIndicator)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        waitIndicator.removeFromSuperview()
                    }
                    
                    MovieCache.movie(urlStr: imageUrls[index]) { [weak self] player, queuePlayer, looper in
                        DispatchQueue.main.async {
                            waitIndicator.removeFromSuperview()
                            
                            if let player = player {
                                let viewController = AVPlayerViewController()
                                viewController.player = player
                                UIUtils.getFrontViewController()?.present(viewController, animated: true) {
                                    player.play()
                                }
                            } else {
                                if #available(iOS 10.0, *) {
                                    if let queuePlayer = queuePlayer as? AVQueuePlayer, let looper = looper as? AVPlayerLooper {
                                        let viewController = AVPlayerViewController()
                                        viewController.player = queuePlayer
                                        self?.looper = looper
                                        UIUtils.getFrontViewController()?.present(viewController, animated: true) {
                                            queuePlayer.play()
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // 静止画
                    let fromRect = imageView.convert(imageView.bounds, to: UIUtils.getFrontViewController()?.view ?? imageView)
                    let vc = ImageViewController(imagesUrls: self.imageUrls, previewUrls: self.previewUrls, index: index, fromRect: fromRect, smallImage: imageView.image)
                    vc.modalTransitionStyle = .crossDissolve
                    UIUtils.getFrontViewController()?.present(vc, animated: false, completion: nil)
                    
                    // ボタンを隠す
                    MainViewController.instance?.hideButtonsForce()
                    
                    break
                }
            }
        }
    }
    
    // 日時表示を更新
    func refreshDate() {
        if self.tableView?.type == .scheduled {
            refreshDateAbsoluteLong()
        } else if SettingsData.useAbsoluteTime || (self.tableView?.type == .scheduled) {
            refreshDateAbsolute()
        } else {
            refreshDateRelated()
        }
    }
    
    // 絶対時間で表示
    private static var timeLongFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter
    }()
    private static var monthLongFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy-MM-dd"
        return formatter
    }()
    private func refreshDateAbsoluteLong() {
        let diffTime = Int(Date().timeIntervalSince(self.date))
        if diffTime / 86400 < 365 {
            self.dateLabel.text = TimeLineViewCell.timeLongFormatter.string(from: self.date)
        } else {
            self.dateLabel.text = TimeLineViewCell.monthLongFormatter.string(from: self.date)
        }
    }
    
    // 絶対時間で表示
    private static var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }()
    private static var monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy-MM"
        return formatter
    }()
    private func refreshDateAbsolute() {
        let diffTime = Int(Date().timeIntervalSince(self.date))
        let dateStr = TimeLineViewCell.dateFormatter.string(from: self.date)
        let nowDateStr = TimeLineViewCell.dateFormatter.string(from: Date())
        if diffTime / 3600 < 18 || (dateStr == nowDateStr && diffTime / 3600 <= 24) {
            self.dateLabel.text = TimeLineViewCell.timeFormatter.string(from: self.date)
        }
        else if diffTime / 86400 < 365 {
            self.dateLabel.text = dateStr
        }
        else {
            self.dateLabel.text = TimeLineViewCell.monthFormatter.string(from: self.date)
        }
    }
    
    // 相対時間で表示
    private func refreshDateRelated() {
        let diffTime = Int(Date().timeIntervalSince(self.date))
        if diffTime <= 0 {
            self.dateLabel.text = I18n.get("DATETIME_NOW")
        }
        else if diffTime < 60 {
            self.dateLabel.text = String(format: I18n.get("DATETIME_%D_SECS_AGO"), diffTime)
        }
        else if diffTime / 60 < 60 {
            self.dateLabel.text = String(format: I18n.get("DATETIME_%D_MINS_AGO"), diffTime / 60)
        }
        else if diffTime / 3600 < 24 {
            if diffTime / 3600 < 10 && diffTime % 3600 >= 1800 {
                self.dateLabel.text = String(format: I18n.get("DATETIME_%D_HOURS_HALF_AGO"), diffTime / 3600)
            } else {
                self.dateLabel.text = String(format: I18n.get("DATETIME_%D_HOURS_AGO"), diffTime / 3600)
            }
        }
        else if diffTime / 86400 < 365 {
            self.dateLabel.text = String(format: I18n.get("DATETIME_%D_DAYS_AGO"), diffTime / 86400)
        }
        else {
            self.dateLabel.text = String(format: I18n.get("DATETIME_%D_YEARS_AGO"), diffTime / 86400 / 365)
        }
    }

    // セル内のレイアウト
    override func layoutSubviews() {
        let screenBounds = UIScreen.main.bounds
        let isDetailMode = !SettingsData.tapDetailMode && self.showDetail
        let isMiniView = isDetailMode ? .normal : self.isMiniView
        let iconSize = isMiniView != .normal ? SettingsData.iconSize - 4 : SettingsData.iconSize
        
        if isDetailMode {
            self.nameLabel.isHidden = false
            self.idLabel.isHidden = false
        }
        
        self.lineLayer.frame = CGRect(x: 0,
                                      y: 0,
                                      width: screenBounds.width,
                                      height: 1 / UIScreen.main.scale)
        
        self.iconView?.frame = CGRect(x: isMiniView != .normal ? 2 : 4,
                                      y: isMiniView == .superMini ? 12 - iconSize / 2 : (isMiniView != .normal ? 6 : 10),
                                      width: iconSize,
                                      height: iconSize)
        
        let nameLeft = iconSize + 7
        self.nameLabel.frame = CGRect(x: nameLeft,
                                      y: isMiniView != .normal ? 2 : 6,
                                      width: min(self.nameLabel.frame.width, screenBounds.width - nameLeft - 50),
                                      height: SettingsData.fontSize + 3)
        
        let idWidth: CGFloat
        if self.detailDateLabel != nil {
            idWidth = screenBounds.width - (self.nameLabel.frame.width + nameLeft)
        } else {
            idWidth = screenBounds.width - (self.nameLabel.frame.width + nameLeft + 45 + 5)
        }
        self.idLabel.frame = CGRect(x: nameLeft + self.nameLabel.frame.width + 5,
                                    y: isMiniView != .normal ? 3 : 6,
                                    width: idWidth,
                                    height: SettingsData.fontSize)
        
        if self.tableView?.type == .scheduled {
            self.dateLabel.frame = CGRect(x: screenBounds.width - 100,
                                          y: isMiniView != .normal ? 3 : 6,
                                          width: 90,
                                          height: SettingsData.fontSize)
        } else {
            self.dateLabel.frame = CGRect(x: screenBounds.width - 50,
                                          y: isMiniView != .normal ? 3 : 6,
                                          width: 45,
                                          height: SettingsData.fontSize)
        }
        
        self.pinnedView?.frame = CGRect(x: screenBounds.width - 20,
                                        y: self.dateLabel.frame.maxY,
                                        width: 20,
                                        height: 16)
        
        self.detailDateLabel?.frame = CGRect(x: 50,
                                             y: 22,
                                             width: screenBounds.width - 55,
                                             height: 18)
        
        self.spolerTextLabel?.frame = CGRect(x: nameLeft,
                                             y: isMiniView == .superMini ? 2 : self.detailDateLabel?.frame.maxY ?? SettingsData.fontSize + 8,
                                             width: self.spolerTextLabel?.frame.width ?? 0,
                                             height: self.spolerTextLabel?.frame.height ?? 0)
        
        if let messageView = self.messageView as? UILabel {
            let y: CGFloat
            if isMiniView == .superMini {
                y = 0
            } else if let spolerTextLabel = self.spolerTextLabel {
                y = spolerTextLabel.frame.maxY + 20
            } else {
                y = self.detailDateLabel?.frame.maxY ?? ((isMiniView != .normal ? 1 : 8) + SettingsData.fontSize)
            }
            messageView.frame = CGRect(x: nameLeft,
                                       y: y,
                                       width: messageView.frame.width,
                                       height: messageView.frame.height)
        } else if let messageView = self.messageView as? UITextView {
            let y: CGFloat
            if isMiniView == .superMini {
                y = -9
            } else if let spolerTextLabel = self.spolerTextLabel {
                y = spolerTextLabel.frame.maxY + 20
            } else {
                y = self.detailDateLabel?.frame.maxY ?? ((isMiniView != .normal ? -9 : 10) + SettingsData.fontSize)
            }
            messageView.frame = CGRect(x: nameLeft,
                                       y: y,
                                       width: messageView.frame.width,
                                       height: messageView.frame.height)
        }
        
        self.continueView?.frame = CGRect(x: screenBounds.width / 2 - 40 / 2,
                                          y: (self.messageView?.frame.maxY ?? 0) - 6,
                                          width: 40,
                                          height: 18)
        
        let imageHeight = isDetailMode ? (UIScreen.main.bounds.width - 80 + 10) : 90
        let imagesOffset = CGFloat(self.imageViews.count) * imageHeight
        self.boostView?.frame = CGRect(x: nameLeft - 12,
                                       y: (self.messageView?.frame.maxY ?? 0) + 8 + imagesOffset,
                                       width: screenBounds.width - 56,
                                       height: 20)
        
        if let showMoreButton = self.showMoreButton {
            showMoreButton.frame = CGRect(x: 100,
                                          y: self.spolerTextLabel?.frame.maxY ?? self.messageView?.frame.maxY ?? 20,
                                          width: screenBounds.width - 160,
                                          height: 20)
        }
        
        self.DMBarLeft?.frame = CGRect(x: 0, y: 0, width: 5, height: 500)
        
        self.DMBarRight?.frame = CGRect(x: screenBounds.width - 5, y: 0, width: 5, height: 500)
        
        var imageTop: CGFloat = (self.messageView?.frame.maxY ?? self.showMoreButton?.frame.maxY ?? 20) + 10
        for imageView in self.imageViews {
            if isDetailMode && SettingsData.isLoadPreviewImage, let image = imageView.image {
                imageView.contentMode = .scaleAspectFit
                var imageWidth: CGFloat = 0
                var imageHeight: CGFloat = isDetailMode ? UIScreen.main.bounds.width - 80 : 80
                let size = image.size
                let rate = imageHeight / max(1, size.height)
                imageWidth = size.width * rate
                if imageWidth > screenBounds.width - 60 {
                    imageWidth = screenBounds.width - 60
                    let newRate = imageWidth / max(1, size.width)
                    imageHeight = size.height * newRate
                }
                imageView.frame = CGRect(x: nameLeft,
                                         y: imageTop,
                                         width: imageWidth,
                                         height: imageHeight)
                imageTop = imageView.frame.maxY + 10
            } else {
                let imageWidth: CGFloat = screenBounds.width - 80
                let imageHeight: CGFloat = 80
                imageView.contentMode = .scaleAspectFill
                imageView.frame = CGRect(x: nameLeft,
                                         y: imageTop,
                                         width: imageWidth,
                                         height: imageHeight)
                imageTop = imageView.frame.maxY + 8
            }
        }
        
        if self.replyButton != nil {
            var top: CGFloat = self.boostView?.frame.maxY ?? self.imageViews.last?.frame.maxY ?? ((self.messageView?.frame.maxY ?? 0) + 8 + imagesOffset)
            
            if let cardView = self.cardView, cardView.alpha > 0 {
                cardView.frame.origin.y = top + 5
                
                top = cardView.frame.maxY
            }
            
            if let pollView = self.pollView {
                pollView.frame.origin.y = top + 5
                
                top = pollView.frame.maxY
            }
            
            if self.tableView?.type == .scheduled {
                self.replyButton?.frame = CGRect(x: -100, y: 0, width: 0, height: 0)
                self.boostButton?.frame = CGRect(x: -100, y: 0, width: 0, height: 0)
                self.favoriteButton?.frame = CGRect(x: -100, y: 0, width: 0, height: 0)
            } else {
                self.replyButton?.frame = CGRect(x: 50,
                                                 y: top,
                                                 width: 40,
                                                 height: 40)
                
                self.repliedLabel?.frame = CGRect(x: 85,
                                                  y: top + 10,
                                                  width: 20,
                                                  height: 20)
                
                self.boostButton?.frame = CGRect(x: 110,
                                                 y: top + 3,
                                                 width: 40,
                                                 height: 34)
                
                self.boostedLabel?.frame = CGRect(x: 145,
                                                  y: top + 10,
                                                  width: 20,
                                                  height: 20)
                
                self.favoriteButton?.frame = CGRect(x: 170,
                                                    y: top + 3,
                                                    width: 40,
                                                    height: 34)
                
                self.favoritedLabel?.frame = CGRect(x: 205,
                                                    y: top + 10,
                                                    width: 20,
                                                    height: 20)
            }
            
            self.detailButton?.frame = CGRect(x: 230,
                                              y: top,
                                              width: 40,
                                              height: 40)
            
            self.applicationLabel?.frame = CGRect(x: 50,
                                                  y: top - 5,
                                                  width: screenBounds.width - 52,
                                                  height: 20)
            
            top += 48
            for label in self.rebologerLabels {
                label.frame = CGRect(x: 50,
                                     y: top,
                                     width: screenBounds.width - 50,
                                     height: SettingsData.fontSize)
                
                top += SettingsData.fontSize + 4
            }
            
            for label in self.favoriterLabels {
                label.frame = CGRect(x: 50,
                                     y: top,
                                     width: screenBounds.width - 50,
                                     height: SettingsData.fontSize)
                
                top += SettingsData.fontSize + 4
            }
        } else {
            if let rightFavButton = self.rightFavButton {
                if isMiniView == .superMini {
                    rightFavButton.frame.origin.x = -100
                } else if isMiniView == .miniView {
                    rightFavButton.frame = CGRect(x: screenBounds.width - 30,
                                                  y: 16,
                                                  width: 32,
                                                  height: 36)
                } else {
                    rightFavButton.frame = CGRect(x: screenBounds.width - 32,
                                                  y: (self.messageView?.frame.midY ?? 40) - 18,
                                                  width: 32,
                                                  height: 36)
                }
            }
            
            if let cardView = self.cardView {
                let top = self.boostView?.frame.maxY ?? self.imageViews.last?.frame.maxY ?? ((self.messageView?.frame.maxY ?? 0) + 8 + imagesOffset)
                cardView.frame.origin.y = top + 5
            }
            
            if let pollView = self.pollView {
                var top = self.cardView?.frame.maxY
                top = top ?? self.boostView?.frame.maxY
                top = top ?? self.imageViews.last?.frame.maxY
                top = top ?? ((self.messageView?.frame.maxY ?? 0) + 8 + imagesOffset)
                pollView.frame.origin.y = top! + 5
            }
        }
    }
}
