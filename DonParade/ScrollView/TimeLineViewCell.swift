//
//  TimeLineViewCell.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/17.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// トゥートの内容を表示するセル

import UIKit

final class TimeLineViewCell: UITableViewCell {
    var id = "" // トゥートのID
    
    // 基本ビュー
    let lineLayer = CALayer()
    let iconView = UIImageView()
    let nameLabel = UILabel()
    let idLabel = UILabel()
    let dateLabel = UILabel()
    var messageView: UIView?
    
    //追加ビュー
    var continueView: UILabel? // 長すぎるトゥートで、続きがあることを表示
    var boostView: UILabel? // 誰がboostしたかを表示
    var imageViews: [UIImageView]? // 添付画像を表示
    var showMoreButton: UIButton? // もっと見る
    var spolerTextLabel: UILabel?
    var detailDateLabel: UILabel?
    
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
    
    weak var tableView: TimeLineView?
    var indexPath: IndexPath?
    var date: Date
    var timer: Timer?
    var accountId: String?
    var contentData: String = ""
    var urlStr: String = ""
    var mensionsList: [AnalyzeJson.MensionData]?
    var isMiniView = SettingsData.MiniView.normal
    var imageUrls: [String] = []
    var previewUrls: [String] = []
    
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
        
        self.lineLayer.backgroundColor = ThemeColor.separatorColor.cgColor
        self.lineLayer.isOpaque = true
        
        // addする
        self.addSubview(self.iconView)
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
        
        // アイコンのタップジェスチャー
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAccountAction))
        self.iconView.addGestureRecognizer(tapGesture)
        self.iconView.isUserInteractionEnabled = true
        
        // アイコンの長押しジェスチャー
        let pressGesture = UILongPressGestureRecognizer(target: self, action: #selector(pressAccountAction(_:)))
        self.iconView.addGestureRecognizer(pressGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // アイコンをタップした時の処理
    @objc func tapAccountAction() {
        if TootViewController.isShown { return } // トゥート画面表示中は移動しない
        
        if let accountId = self.accountId {
            let accountTimeLineViewController = TimeLineViewController(type: TimeLineViewController.TimeLineType.user, option: accountId)
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
    @objc func pressAccountAction(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state != .began { return }
        
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
            TootViewController.inReplyToId = self.id
            
            // トゥート画面を開いていなければ開く
            if !TootViewController.isShown {
                MainViewController.instance?.tootAction(nil)
            }
            
            // @IDを入力する
            DispatchQueue.main.asyncAfter(deadline: .now() + (TootViewController.isShown ? 0.0 : 0.2)) {
                if let vc = TootViewController.instance, let view = vc.view as? TootView {
                    view.textField.text = "@\(self.idLabel.text ?? "") "
                }
            }
        }
    }
    
    // ブーストボタンをタップした時の処理
    @objc func boostAction() {
        self.boostButton?.isHidden = true
        
        tableView?.boostAction(id: self.id, isBoosted: self.isBoosted)
    }
    
    // お気に入りボタンをタップした時の処理
    @objc func favoriteAction() {
        self.favoriteButton?.isHidden = true
        
        tableView?.favoriteAction(id: self.id, isFaved: self.isFaved)
    }
    
    // 「・・・」ボタンをタップした時の処理
    @objc func detailAction() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        if self.accountId == SettingsData.accountNumberID(accessToken: SettingsData.accessToken ?? "") {
            // トゥートを削除
            alertController.addAction(UIAlertAction(
                title: I18n.get("ACTION_DELETE_TOOT"),
                style: UIAlertActionStyle.default,
                handler: { _ in
                    guard let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/statuses/\(self.id)") else { return }
                    try? MastodonRequest.delete(url: url, completionHandler: { (data, response, error) in
                        if let error = error {
                            Dialog.show(message: I18n.get("ALERT_DELETE_TOOT_FAILURE") + "\n " + error.localizedDescription)
                        }
                    })
            }))
        }
        
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
        
        // 生データを表示
        alertController.addAction(UIAlertAction(
            title: "生データを表示",
            style: UIAlertActionStyle.default,
            handler: { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    Dialog.show(message: self.contentData)
                }
        }))
        
        // キャンセル
        alertController.addAction(UIAlertAction(
            title: I18n.get("BUTTON_CANCEL"),
            style: UIAlertActionStyle.cancel,
            handler: { _ in
        }))
        
        UIUtils.getFrontViewController()?.present(alertController, animated: true, completion: nil)
    }
    
    // もっと見る
    @objc func showMoreAction() {
        self.messageView?.isHidden = false
        for imageView in self.imageViews ?? [] {
            imageView.isHidden = false
        }
        
        self.showMoreButton?.removeFromSuperview()
    }
    
    // 画像をタップ
    @objc func imageTapAction(_ gesture: UITapGestureRecognizer) {
        for (index, imageView) in (self.imageViews ?? []).enumerated() {
            if imageView == gesture.view {
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
        
        self.lineLayer.frame = CGRect(x: 0,
                                      y: 0,
                                      width: screenBounds.width,
                                      height: 1 / UIScreen.main.scale)
        
        self.iconView.frame = CGRect(x: isMiniView != .normal ? 4 : 8,
                                     y: isMiniView == .superMini ? -6 : (isMiniView != .normal ? 6 : 10),
                                     width: isMiniView != .normal ? 32 : 36,
                                     height: isMiniView != .normal ? 32 : 36)
        
        self.nameLabel.frame = CGRect(x: isMiniView != .normal ? 42 : 50,
                                      y: isMiniView != .normal ? 3 : 7,
                                      width: self.nameLabel.frame.width,
                                      height: SettingsData.fontSize + 1)
        
        let idWidth: CGFloat
        if self.detailDateLabel != nil {
            idWidth = screenBounds.width - (self.nameLabel.frame.width + (isMiniView != .normal ? 42 : 50))
        } else {
            idWidth = screenBounds.width - (self.nameLabel.frame.width + (isMiniView != .normal ? 42 : 50) + 45 + 5)
        }
        self.idLabel.frame = CGRect(x: (isMiniView != .normal ? 42 : 50) + self.nameLabel.frame.width + 5,
                                    y: isMiniView != .normal ? 3 : 7,
                                    width: idWidth,
                                    height: SettingsData.fontSize)
        
        self.dateLabel.frame = CGRect(x: screenBounds.width - 50,
                                      y: isMiniView != .normal ? 3 : 7,
                                      width: 45,
                                      height: SettingsData.fontSize)
        
        self.detailDateLabel?.frame = CGRect(x: 50,
                                             y: 22,
                                             width: screenBounds.width - 55,
                                             height: 18)
        
        self.spolerTextLabel?.frame = CGRect(x: 50,
                                             y: self.detailDateLabel?.frame.maxY ?? 19,
                                             width: self.spolerTextLabel?.frame.width ?? 0,
                                             height: self.spolerTextLabel?.frame.height ?? 0)
        
        self.messageView?.frame = CGRect(x: isMiniView != .normal ? 42 : 50,
                                         y: isMiniView == .superMini ? 0 : self.detailDateLabel?.frame.maxY ?? self.spolerTextLabel?.frame.maxY ?? ((isMiniView != .normal ? 1 : 5) + SettingsData.fontSize),
                                         width: self.messageView?.frame.width ?? 0,
                                         height: self.messageView?.frame.height ?? 0)
        
        self.continueView?.frame = CGRect(x: screenBounds.width / 2 - 40 / 2,
                                          y: (self.messageView?.frame.maxY ?? 0) - 6,
                                          width: 40,
                                          height: 18)
        
        let imagesOffset = CGFloat((self.imageViews?.count ?? 0) * 90)
        self.boostView?.frame = CGRect(x: 40,
                                       y: (self.messageView?.frame.maxY ?? 0) + 8 + imagesOffset,
                                       width: screenBounds.width - 56,
                                       height: 20)
        
        self.showMoreButton?.frame = CGRect(x: 50,
                                            y: self.spolerTextLabel?.frame.maxY ?? 20,
                                            width: screenBounds.width - 66,
                                            height: 20)
        
        for (index, imageView) in (self.imageViews ?? []).enumerated() {
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
            }
            imageView.frame = CGRect(x: 50,
                                     y: (self.messageView?.frame.maxY ?? 0) + (imageHeight + 10) * CGFloat(index) + 8,
                                     width: imageWidth,
                                     height: imageHeight)
        }
        
        if self.replyButton != nil {
            let top: CGFloat = self.boostView?.frame.maxY ?? self.imageViews?.last?.frame.maxY ?? ((self.messageView?.frame.maxY ?? 0) + 8 + imagesOffset)
            
            self.replyButton?.frame = CGRect(x: 50,
                                             y: top,
                                             width: 40,
                                             height: 40)
            
            self.repliedLabel?.frame = CGRect(x: 85,
                                              y: top + 10,
                                              width: 20,
                                              height: 20)
            
            self.boostButton?.frame = CGRect(x: 110,
                                             y: top,
                                             width: 40,
                                             height: 40)
            
            self.boostedLabel?.frame = CGRect(x: 145,
                                              y: top + 10,
                                              width: 20,
                                              height: 20)
            
            self.favoriteButton?.frame = CGRect(x: 170,
                                                y: top,
                                                width: 40,
                                                height: 40)
            
            self.favoritedLabel?.frame = CGRect(x: 205,
                                                y: top + 10,
                                                width: 20,
                                                height: 20)
            
            self.detailButton?.frame = CGRect(x: 230,
                                              y: top,
                                              width: 40,
                                              height: 40)
            
            let applicationLabelWidth = max(80, screenBounds.width - 270)
            self.applicationLabel?.frame = CGRect(x: screenBounds.width - applicationLabelWidth,
                                                  y: top - 5,
                                                  width: applicationLabelWidth,
                                                  height: 20)
        }
    }
}
