//
//  NotificationTableCell.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/23.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 通知の内容を表示するセル

import UIKit

final class NotificationTableCell: UITableViewCell {
    var id = ""
    
    // 基本ビュー
    let lineLayer = CALayer()
    let iconView = UIImageView()
    let nameLabel = UILabel()
    let idLabel = UILabel()
    let dateLabel = UILabel()
    let notificationLabel = UILabel()
    var statusLabel = UITextView()
    
    //var followButton: UIButton?
    let replyButton = UIButton()
    let favoriteButton = UIButton()
    
    var accountId: String?
    var date: Date = Date()
    var timer: Timer?
    var accountData: AnalyzeJson.AccountData?
    
    var statusId: String?
    var visibility: String?
    var isFaved = false
    
    init(reuseIdentifier: String?) {
        super.init(style: UITableViewCell.CellStyle.default, reuseIdentifier: reuseIdentifier)
        
        // デフォルトのビューは不要
        self.textLabel?.removeFromSuperview()
        self.detailTextLabel?.removeFromSuperview()
        self.imageView?.removeFromSuperview()
        self.contentView.removeFromSuperview()
        
        self.addSubview(iconView)
        self.addSubview(nameLabel)
        self.addSubview(idLabel)
        self.addSubview(dateLabel)
        self.addSubview(notificationLabel)
        self.addSubview(statusLabel)
        self.addSubview(replyButton)
        self.addSubview(favoriteButton)
        self.layer.addSublayer(self.lineLayer)
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        // 固定プロパティは初期化時に設定
        self.clipsToBounds = true
        self.backgroundColor = ThemeColor.cellBgColor
        self.isOpaque = true
        self.selectionStyle = .none
        
        self.iconView.layer.cornerRadius = 5
        self.iconView.clipsToBounds = true
        
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
        
        self.notificationLabel.textColor = ThemeColor.idColor
        self.notificationLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
        self.notificationLabel.backgroundColor = ThemeColor.cellBgColor
        self.notificationLabel.isOpaque = true
        
        self.statusLabel.textColor = ThemeColor.idColor
        self.statusLabel.linkTextAttributes = [NSAttributedString.Key.foregroundColor: ThemeColor.linkTextColor]
        self.statusLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize - 2)
        self.statusLabel.backgroundColor = ThemeColor.toMentionBgColor
        self.statusLabel.isOpaque = true
        self.statusLabel.isScrollEnabled = false
        self.statusLabel.isEditable = false
        
        self.lineLayer.backgroundColor = ThemeColor.separatorColor.cgColor
        self.lineLayer.isOpaque = true
        
        self.replyButton.setTitle("↩︎", for: .normal)
        self.replyButton.setTitleColor(ThemeColor.detailButtonsColor, for: .normal)
        self.replyButton.addTarget(self, action: #selector(self.replyAction), for: .touchUpInside)
        
        self.favoriteButton.setTitle("★", for: .normal)
        self.favoriteButton.setTitleColor(ThemeColor.detailButtonsColor, for: .normal)
        self.favoriteButton.addTarget(self, action: #selector(self.favoriteAction), for: .touchUpInside)
        
        // タイマーで5秒ごとに時刻を更新
        if #available(iOS 10.0, *) {
            self.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { [weak self] timer in
                if self?.superview == nil {
                    return
                }
                
                self?.refreshDate()
            })
        }
        
        // アイコンのタップジェスチャー
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAccountAction))
        self.iconView.addGestureRecognizer(tapGesture)
        self.iconView.isUserInteractionEnabled = true
        
        if SettingsData.isNameTappable {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAccountAction))
            self.nameLabel.addGestureRecognizer(tapGesture)
            self.nameLabel.isUserInteractionEnabled = true
        }
        
        // アイコンの長押しジェスチャー
        let pressGesture = UILongPressGestureRecognizer(target: self, action: #selector(pressAccountAction(_:)))
        self.iconView.addGestureRecognizer(pressGesture)
    }
    
    // アイコンをタップした時の処理
    @objc func tapAccountAction() {
        if TootViewController.isShown {
            // トゥート画面表示中は移動せず、@IDを入力する
            pressAccountAction(nil)
            return
        }
        
        if let accountId = self.accountId {
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
            TootView.inReplyToId = self.statusId
            
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
            }
            
            // @IDを入力する
            DispatchQueue.main.asyncAfter(deadline: .now() + (TootViewController.isShown ? 0.0 : 0.2)) {
                if let vc = TootViewController.instance, let view = vc.view as? TootView {
                    view.textField.text = "@\(self.idLabel.text ?? "") "
                }
            }
        }
    }
    
    // お気に入りボタンをタップした時の処理
    @objc func favoriteAction() {
        self.favoriteButton.isHidden = true
        
        guard let hostName = SettingsData.hostName else { return }
        guard let id = self.statusId else { return }
        
        let url: URL
        if isFaved {
            url = URL(string: "https://\(hostName)/api/v1/statuses/\(id)/unfavourite")!
        } else {
            url = URL(string: "https://\(hostName)/api/v1/statuses/\(id)/favourite")!
        }
        
        try? MastodonRequest.post(url: url, body: [:]) { (data, response, error) in
            DispatchQueue.main.async {
                self.favoriteButton.isHidden = false
                
                if self.isFaved {
                    self.favoriteButton.setTitleColor(ThemeColor.detailButtonsColor, for: .normal)
                } else {
                    self.favoriteButton.setTitleColor(ThemeColor.detailButtonsHiliteColor, for: .normal)
                }
            }
        }
    }
    
    // 日時表示を更新
    func refreshDate() {
        if SettingsData.useAbsoluteTime {
            refreshDateAbsolute()
        } else {
            refreshDateRelated()
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
        let dateStr = NotificationTableCell.dateFormatter.string(from: self.date)
        let nowDateStr = NotificationTableCell.dateFormatter.string(from: Date())
        if diffTime / 3600 < 18 || (dateStr == nowDateStr && diffTime / 3600 <= 24) {
            self.dateLabel.text = NotificationTableCell.timeFormatter.string(from: self.date)
        }
        else if diffTime / 86400 < 365 {
            self.dateLabel.text = dateStr
        }
        else {
            self.dateLabel.text = NotificationTableCell.monthFormatter.string(from: self.date)
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
    
    override func layoutSubviews() {
        let screenBounds = UIScreen.main.bounds
        
        self.lineLayer.frame = CGRect(x: 0,
                                      y: 0,
                                      width: screenBounds.width,
                                      height: 1 / UIScreen.main.scale)
        
        self.iconView.frame = CGRect(x: 8,
                                     y: 10,
                                     width: SettingsData.iconSize,
                                     height: SettingsData.iconSize)
        
        let left = SettingsData.iconSize + 16
        self.nameLabel.frame = CGRect(x: left,
                                      y: 7,
                                      width: self.nameLabel.frame.width,
                                      height: SettingsData.fontSize + 1)
        
        let idWidth = screenBounds.width - (self.nameLabel.frame.width + left + 45 + 5)
        self.idLabel.frame = CGRect(x: left + self.nameLabel.frame.width + 5,
                                    y: 7,
                                    width: idWidth,
                                    height: SettingsData.fontSize)
        
        self.dateLabel.frame = CGRect(x: screenBounds.width - 50,
                                      y: 7,
                                      width: 45,
                                      height: SettingsData.fontSize)
        
        self.notificationLabel.frame = CGRect(x: left,
                                              y: 10 + SettingsData.fontSize,
                                              width: screenBounds.width - left,
                                              height: SettingsData.fontSize + 2)
        
        self.statusLabel.frame.size.width = screenBounds.width - left - 5
        self.statusLabel.sizeToFit()
        self.statusLabel.frame = CGRect(x: left,
                                        y: self.notificationLabel.frame.maxY + 6,
                                        width: self.statusLabel.frame.width,
                                        height: self.statusLabel.frame.height)
        
        self.replyButton.frame = CGRect(x: left + 10,
                                        y: self.statusLabel.frame.maxY + 8,
                                        width: 32,
                                        height: 32)
        
        self.favoriteButton.frame = CGRect(x: left + 100,
                                           y: self.statusLabel.frame.maxY + 8,
                                           width: 32,
                                           height: 32)
    }
}
