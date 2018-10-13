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
        
        // タイマーで5秒ごとに時刻を更新
        if #available(iOS 10.0, *) {
            self.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { [weak self] timer in
                if self?.superview == nil {
                    return
                }
                
                self?.refreshDate()
            })
        }
        
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
        while let apngView = self.messageView?.viewWithTag(5555) as? APNGImageView {
            apngView.stopAnimating()
            apngView.removeFromSuperview()
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
        }
        self.iconView?.removeFromSuperview()
        self.iconView?.image = nil
        
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
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
            
            // トゥート画面を開いていなければ開く
            if !TootViewController.isShown {
                MainViewController.instance?.tootAction(nil)
                
                // 公開範囲を低い方に合わせる
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    // 公開範囲設定を変更
                    if let visibility = self.visibility {
                        guard let view = TootViewController.instance?.view as? TootView else { return }
                        
                        let mode = self.lowerVisibility(m1: SettingsData.ProtectMode(rawValue: visibility),
                                                   m2: SettingsData.protectMode)
                        view.protectMode = mode
                        view.refresh()
                    }
                }
            }
            
            // @IDを入力する
            DispatchQueue.main.asyncAfter(deadline: .now() + (TootViewController.isShown ? 0.0 : 0.2)) {
                if let vc = TootViewController.instance, let view = vc.view as? TootView {
                    view.textField.text = "@\(self.idLabel.text ?? "") "
                }
            }
        }
    }
    
    // 低い方の公開範囲を返す
    private func lowerVisibility(m1: SettingsData.ProtectMode?, m2: SettingsData.ProtectMode) -> SettingsData.ProtectMode {
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
        self.favoriteButton?.isHidden = true
        
        tableView?.favoriteAction(id: self.reblog_id ?? self.id, isFaved: self.isFaved)
    }
    
    // 「・・・」ボタンをタップした時の処理
    @objc func detailAction() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        // 選択解除
        alertController.addAction(UIAlertAction(
            title: I18n.get("ACTION_DESELECT"),
            style: UIAlertActionStyle.default,
            handler: { _ in
                self.tableView?.model.clearSelection()
                self.tableView?.reloadData()
        }))
        
        if self.accountId == SettingsData.accountNumberID(accessToken: SettingsData.accessToken ?? "") {
            // トゥートを削除
            alertController.addAction(UIAlertAction(
                title: I18n.get("ACTION_DELETE_TOOT"),
                style: UIAlertActionStyle.destructive,
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
            style: UIAlertActionStyle.destructive,
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
            style: UIAlertActionStyle.default,
            handler: { _ in
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
        }))
        
        // Safariで開く
        alertController.addAction(UIAlertAction(
            title: I18n.get("ACTION_OPEN_WITH_SAFARI"),
            style: UIAlertActionStyle.default,
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
        
        // キャンセル
        alertController.addAction(UIAlertAction(
            title: I18n.get("BUTTON_CANCEL"),
            style: UIAlertActionStyle.cancel,
            handler: { _ in
        }))
        
        UIUtils.getFrontViewController()?.present(alertController, animated: true, completion: nil)
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
            self.showMoreButton?.setTitle(I18n.get("BUTTON_SHOW_MORE"), for: .normal)
            return
        }
        
        self.messageView?.isHidden = false
        for imageView in self.imageViews {
            imageView.isHidden = false
        }
        
        self.showMoreButton?.setTitle(I18n.get("BUTTON_HIDE_REDO"), for: .normal)
        
        if !TimeLineViewCell.showMoreList.contains(self.id) && self.id != "" {
            TimeLineViewCell.showMoreList.append(self.id)
        }
    }
    
    // 画像をタップ
    @objc func imageTapAction(_ gesture: UITapGestureRecognizer) {
        for (index, imageView) in self.imageViews.enumerated() {
            if imageView == gesture.view {
                if imageTypes[index] == "unknown" {
                    // 分からんので内臓ブラウザで開く
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
        
        self.dateLabel.frame = CGRect(x: screenBounds.width - 50,
                                      y: isMiniView != .normal ? 3 : 6,
                                      width: 45,
                                      height: SettingsData.fontSize)
        
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
                y = self.detailDateLabel?.frame.maxY ?? ((isMiniView != .normal ? 1 : 5) + SettingsData.fontSize)
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
                y = self.detailDateLabel?.frame.maxY ?? ((isMiniView != .normal ? -9 : 5) + SettingsData.fontSize)
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
        
        self.DMBarLeft?.frame = CGRect(x: 0, y: 0, width: 5, height: 300)
        
        self.DMBarRight?.frame = CGRect(x: screenBounds.width - 5, y: 0, width: 5, height: 300)
        
        for (index, imageView) in self.imageViews.enumerated() {
            if isDetailMode && SettingsData.isLoadPreviewImage {
                imageView.contentMode = .scaleAspectFit
                var imageWidth: CGFloat = 0
                var imageHeight: CGFloat = isDetailMode ? UIScreen.main.bounds.width - 80 : 80
                if let image = imageView.image {
                    let size = image.size
                    let rate = imageHeight / size.height
                    imageWidth = size.width * rate
                    if imageWidth > screenBounds.width - 60 {
                        imageWidth = screenBounds.width - 60
                        let newRate = imageWidth / size.width
                        imageHeight = size.height * newRate
                    }
                    imageView.frame = CGRect(x: nameLeft,
                                             y: (self.messageView?.frame.maxY ?? 0) + (imageHeight + 10) * CGFloat(index) + 8,
                                             width: imageWidth,
                                             height: imageHeight)
                }
            } else {
                let imageWidth: CGFloat = screenBounds.width - 80
                let imageHeight: CGFloat = 80
                imageView.contentMode = .scaleAspectFill
                imageView.frame = CGRect(x: nameLeft,
                                         y: (self.messageView?.frame.maxY ?? 0) + (imageHeight + 10) * CGFloat(index) + 8,
                                         width: imageWidth,
                                         height: imageHeight)
            }
        }
        
        if self.replyButton != nil {
            var top: CGFloat = self.boostView?.frame.maxY ?? self.imageViews.last?.frame.maxY ?? ((self.messageView?.frame.maxY ?? 0) + 8 + imagesOffset)
            
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
            
            self.detailButton?.frame = CGRect(x: 230,
                                              y: top,
                                              width: 40,
                                              height: 40)
            
            let applicationLabelWidth = max(100, screenBounds.width - 250)
            self.applicationLabel?.frame = CGRect(x: screenBounds.width - applicationLabelWidth,
                                                  y: top - 5,
                                                  width: applicationLabelWidth,
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
        }
    }
}
