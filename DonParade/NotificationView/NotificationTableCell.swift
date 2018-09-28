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
    var statusLabel = UILabel()
    
    var followButton: UIButton?
    
    var accountId: String?
    var date: Date = Date()
    var timer: Timer?
    var accountData: AnalyzeJson.AccountData?
    
    init(reuseIdentifier: String?) {
        super.init(style: UITableViewCellStyle.default, reuseIdentifier: reuseIdentifier)
        
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
        self.statusLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize - 2)
        self.statusLabel.backgroundColor = ThemeColor.toMentionBgColor
        self.statusLabel.numberOfLines = 0
        self.statusLabel.lineBreakMode = .byCharWrapping
        self.statusLabel.isOpaque = true
        
        self.lineLayer.backgroundColor = ThemeColor.separatorColor.cgColor
        self.lineLayer.isOpaque = true
        
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
            MainViewController.instance?.addChildViewController(accountTimeLineViewController)
            MainViewController.instance?.view.addSubview(accountTimeLineViewController.view)
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
    
    override func layoutSubviews() {
        let screenBounds = UIScreen.main.bounds
        
        self.lineLayer.frame = CGRect(x: 0,
                                      y: 0,
                                      width: screenBounds.width,
                                      height: 1 / UIScreen.main.scale)
        
        self.iconView.frame = CGRect(x: 8,
                                     y: 10,
                                     width: 36,
                                     height: 36)
        
        self.nameLabel.frame = CGRect(x: 50,
                                      y: 7,
                                      width: self.nameLabel.frame.width,
                                      height: SettingsData.fontSize + 1)
        
        let idWidth = screenBounds.width - (self.nameLabel.frame.width + 50 + 45 + 5)
        self.idLabel.frame = CGRect(x: 50 + self.nameLabel.frame.width + 5,
                                    y: 7,
                                    width: idWidth,
                                    height: SettingsData.fontSize)
        
        self.dateLabel.frame = CGRect(x: screenBounds.width - 50,
                                      y: 7,
                                      width: 45,
                                      height: SettingsData.fontSize)
        
        self.notificationLabel.frame = CGRect(x: 50,
                                              y: 10 + SettingsData.fontSize,
                                              width: screenBounds.width - 50,
                                              height: SettingsData.fontSize + 2)
        
        self.statusLabel.frame.size.width = screenBounds.width - 55
        self.statusLabel.sizeToFit()
        self.statusLabel.frame = CGRect(x: 50,
                                        y: self.notificationLabel.frame.maxY + 6,
                                        width: self.statusLabel.frame.width,
                                        height: self.statusLabel.frame.height)
    }
}
