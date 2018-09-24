//
//  ProfileViewCell.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/24.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 個人タイムラインの上に表示されるプロフィール欄
//  ここにプロフィールが表示され、フォローしたりブロックやミュートできる

import UIKit
import SafariServices

final class ProfileViewCell: UITableViewCell, UITextViewDelegate {
    private var id = ""
    private var relationshipData: AnalyzeJson.RelationshipData? = nil
    
    // ヘッダ画像
    let headerImageView = UIImageView()
    
    // メインの表示
    let iconView = UIImageView()
    let nameLabel = UILabel()
    let idLabel = UILabel()
    let noteLabel = UITextView()
    let dateLabel = UILabel()
    
    // 追加分の表示
    var serviceLabels: [UILabel] = []
    var urlLabels: [UITextView] = []
    
    // 数の表示
    let followingCountTitle = UILabel()
    let followingCountLabel = UILabel()
    let followerCountTitle = UILabel()
    let followerCountLabel = UILabel()
    let statusCountTitle = UILabel()
    let statusCountLabel = UILabel()
    
    // フォローしているか、フォローされているか、ミュート、ブロック状態の表示
    let relationshipLabel = UILabel()
    
    // アクションボタン
    //  フォローしたり、アンフォローしたり、ブロックしたり、ミュートしたり、リストに入れたり、ブラウザで開いたりする
    let actionButton = UIButton()
    
    init(accountData: AnalyzeJson.AccountData?, isTemp: Bool) {
        super.init(style: .default, reuseIdentifier: nil)
        
        self.id = accountData?.id ?? ""
        
        if !isTemp {
            // フォロー関係かどうかを取得
            getRelationship()
        }
        
        // ヘッダ画像
        self.addSubview(headerImageView)
        
        // メインの表示
        self.addSubview(iconView)
        self.addSubview(nameLabel)
        self.addSubview(idLabel)
        self.addSubview(noteLabel)
        self.addSubview(dateLabel)
        
        // 数の表示
        self.addSubview(followingCountTitle)
        self.addSubview(followingCountLabel)
        self.addSubview(followerCountTitle)
        self.addSubview(followerCountLabel)
        self.addSubview(statusCountTitle)
        self.addSubview(statusCountLabel)
        
        // フォローしているか、フォローされているかの表示
        self.addSubview(relationshipLabel)
        self.addSubview(actionButton)
        
        setProperties(data: accountData)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties(data: AnalyzeJson.AccountData?) {
        self.backgroundColor = ThemeColor.viewBgColor
        self.selectionStyle = .none
        
        guard let data = data else { return }
        
        // ヘッダ画像
        headerImageView.image = ImageUtils.colorImage(color: ThemeColor.mainButtonsBgColor)
        headerImageView.contentMode = .scaleAspectFill
        headerImageView.clipsToBounds = true
        ImageCache.image(urlStr: data.header_static, isTemp: true, isSmall: false) { [weak self] image in
            if image.size.width <= 1 && image.size.height <= 1 { return }
            self?.headerImageView.image = image
            self?.setNeedsLayout()
            
            // 視差効果
            do {
                let min: CGFloat = -30.0
                let max: CGFloat = 30.0
                
                let xAxis = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
                xAxis.minimumRelativeValue = min
                xAxis.maximumRelativeValue = max
                
                let yAxis = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
                yAxis.minimumRelativeValue = min
                yAxis.maximumRelativeValue = max
                
                let group = UIMotionEffectGroup()
                group.motionEffects = [xAxis, yAxis]
                
                self?.headerImageView.addMotionEffect(group)
            }
        }
        
        // メインの表示
        ImageCache.image(urlStr: data.avatar_static, isTemp: false, isSmall: true) { [weak self] image in
            self?.iconView.image = image
        }
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 8
        
        nameLabel.attributedText = DecodeToot.decodeName(name: data.display_name, emojis: data.emojis) { }
        nameLabel.textColor = ThemeColor.nameColor
        nameLabel.shadowColor = ThemeColor.viewBgColor
        nameLabel.shadowOffset = CGSize(width: 0.6, height: 0.6)
        nameLabel.font = UIFont.boldSystemFont(ofSize: SettingsData.fontSize + 2)
        nameLabel.numberOfLines = 0
        nameLabel.lineBreakMode = .byCharWrapping
        
        idLabel.text = data.acct
        idLabel.textColor = ThemeColor.idColor
        idLabel.shadowColor = ThemeColor.viewBgColor
        idLabel.shadowOffset = CGSize(width: 0.5, height: 0.5)
        idLabel.font = UIFont.boldSystemFont(ofSize: SettingsData.fontSize)
        idLabel.adjustsFontSizeToFitWidth = true
        
        noteLabel.delegate = self
        noteLabel.attributedText = DecodeToot.decodeContent(content: data.note, emojis: data.emojis, callback: nil).0
        noteLabel.textColor = ThemeColor.idColor
        noteLabel.isSelectable = true
        noteLabel.isEditable = false
        noteLabel.isScrollEnabled = false
        noteLabel.backgroundColor = ThemeColor.viewBgColor.withAlphaComponent(0.2)
        noteLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
        
        if let created_at = data.created_at {
            let date = DecodeToot.decodeTime(text: created_at)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            dateLabel.text = "since " + dateFormatter.string(from: date)
        }
        dateLabel.textColor = ThemeColor.idColor
        dateLabel.shadowColor = ThemeColor.viewBgColor
        dateLabel.shadowOffset = CGSize(width: 0.5, height: 0.5)
        dateLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
        
        // 追加分の表示
        for field in data.fields ?? [] {
            let nameLabel = UILabel()
            nameLabel.text = field["name"] as? String
            nameLabel.textColor = ThemeColor.idColor
            nameLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
            nameLabel.numberOfLines = 0
            nameLabel.lineBreakMode = .byCharWrapping
            serviceLabels.append(nameLabel)
            self.addSubview(nameLabel)
            
            let valueLabel = UITextView()
            valueLabel.delegate = self
            valueLabel.attributedText = DecodeToot.decodeContent(content: field["value"] as? String, emojis: nil, callback: nil).0
            valueLabel.textColor = ThemeColor.idColor
            valueLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
            valueLabel.isSelectable = true
            valueLabel.isEditable = false
            valueLabel.isScrollEnabled = false
            urlLabels.append(valueLabel)
            self.addSubview(valueLabel)
        }
        
        // 数の表示
        followingCountTitle.text = "following"
        followingCountTitle.textColor = ThemeColor.dateColor
        followingCountTitle.font = UIFont.systemFont(ofSize: SettingsData.fontSize - 2)
        
        followingCountLabel.text = "\(data.following_count ?? 0)"
        followingCountLabel.textColor = ThemeColor.idColor
        followingCountLabel.font = UIFont.boldSystemFont(ofSize: SettingsData.fontSize)
        followingCountLabel.textAlignment = .center
        
        followerCountTitle.text = "followers"
        followerCountTitle.textColor = ThemeColor.dateColor
        followerCountTitle.font = UIFont.systemFont(ofSize: SettingsData.fontSize - 2)
        
        followerCountLabel.text = "\(data.followers_count ?? 0)"
        followerCountLabel.textColor = ThemeColor.idColor
        followerCountLabel.font = UIFont.boldSystemFont(ofSize: SettingsData.fontSize)
        followerCountLabel.textAlignment = .center
        
        statusCountTitle.text = "toots"
        statusCountTitle.textColor = ThemeColor.dateColor
        statusCountTitle.font = UIFont.systemFont(ofSize: SettingsData.fontSize - 2)
        
        statusCountLabel.text = "\(data.statuses_count ?? 0)"
        statusCountLabel.textColor = ThemeColor.idColor
        statusCountLabel.font = UIFont.boldSystemFont(ofSize: SettingsData.fontSize)
        statusCountLabel.textAlignment = .center
        
        // フォロー関連
        actionButton.setTitle("…", for: .normal)
        actionButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 32)
        actionButton.backgroundColor = ThemeColor.mainButtonsBgColor
        actionButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        actionButton.clipsToBounds = true
        actionButton.layer.cornerRadius = 10
        actionButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        actionButton.layer.borderWidth = 1
        actionButton.alpha = 0
        actionButton.addTarget(self, action: #selector(tapActionButton), for: .touchUpInside)
        
        relationshipLabel.textColor = ThemeColor.idColor
        relationshipLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize - 2)
        relationshipLabel.shadowColor = ThemeColor.viewBgColor
        relationshipLabel.shadowOffset = CGSize(width: 0.5, height: 0.5)
        relationshipLabel.numberOfLines = 0
        relationshipLabel.lineBreakMode = .byCharWrapping
    }
    
    // フォロー関係かどうかを取得
    private func getRelationship() {
        guard let hostName = SettingsData.hostName else { return }
        
        let url = URL(string: "https://\(hostName)/api/v1/accounts/relationships?id=\(self.id)")!
        
        try? MastodonRequest.get(url: url) { [weak self] (data, response, error) in
            if let data = data {
                do {
                    let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: Any]]
                    
                    if let responseJson = responseJson?.first {
                        self?.relationshipData = AnalyzeJson.analyzeRelationshipJson(json: responseJson)
                        
                        if let relationshipData = self?.relationshipData {
                            DispatchQueue.main.async {
                                var text = ""
                                
                                // フォロー関連
                                if relationshipData.following == 1 && relationshipData.followed_by == 1 {
                                    text += "相互フォロー\n"
                                }
                                else if relationshipData.following == 1 {
                                    text += "フォロー中\n"
                                }
                                else if relationshipData.followed_by == 1 {
                                    text += "フォローされています\n"
                                }
                                if relationshipData.requested == 1 {
                                    text += "フォローリクエストされています\n"
                                }
                                if relationshipData.endorsed == 1 {
                                    text += "承認済み\n"
                                }
                                
                                // ミュート
                                if relationshipData.muting == 1 {
                                    text += "ミュート中\n"
                                }
                                if relationshipData.muting_notifications == 1 {
                                    text += "通知ミュート中\n"
                                }
                                
                                // ブロック
                                if relationshipData.domain_blocking == 1 {
                                    text += "ドメインブロック中\n"
                                }
                                if relationshipData.blocking == 1 {
                                    text += "ブロック中\n"
                                }
                                
                                // 最後の改行を取り除く
                                if text.count > 0 {
                                    text = String(text.prefix(text.count - 1))
                                }
                                
                                self?.relationshipLabel.text = text
                                
                                self?.actionButton.alpha = 1
                                
                                self?.setNeedsLayout()
                            }
                        }
                    }
                } catch {
                }
            }
        }
    }
    
    @objc func tapActionButton() {
        
    }
    
    // UITextViewのリンクタップ時の処理
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        let controller = SFSafariViewController(url: URL)
        MainViewController.instance?.present(controller, animated: true)
        
        return false
    }
    
    override func layoutSubviews() {
        let screenBounds = UIScreen.main.bounds
        
        // メインの表示
        iconView.frame = CGRect(x: 5,
                                y: 5,
                                width: 70,
                                height: 70)
        
        nameLabel.frame.size.width = screenBounds.width - 80
        nameLabel.sizeToFit()
        nameLabel.frame = CGRect(x: 80,
                                 y: 20,
                                 width: nameLabel.frame.width,
                                 height: nameLabel.frame.height)
        
        idLabel.frame = CGRect(x: 80,
                               y: nameLabel.frame.maxY + 5,
                               width: screenBounds.width - 80,
                               height: 24)
        
        noteLabel.frame.size.width = screenBounds.width - 80
        noteLabel.sizeToFit()
        noteLabel.frame = CGRect(x: 80,
                                 y: idLabel.frame.maxY + 5,
                                 width: noteLabel.frame.width,
                                 height: noteLabel.frame.height)
        
        dateLabel.frame = CGRect(x: 80,
                                 y: noteLabel.frame.maxY + 5,
                                 width: screenBounds.width - 80,
                                 height: 24)
        
        // フォロー関係表示
        actionButton.frame = CGRect(x: 15,
                                    y: 80,
                                    width: 50,
                                    height: 50)
        
        relationshipLabel.frame.size.width = 75
        relationshipLabel.sizeToFit()
        relationshipLabel.frame = CGRect(x: 5,
                                         y: 135,
                                         width: relationshipLabel.frame.width,
                                         height: relationshipLabel.frame.height)
        
        // ヘッダ画像
        headerImageView.frame = CGRect(x: -5,
                                       y: 0,
                                       width: screenBounds.width + 10,
                                       height: max(160, relationshipLabel.frame.maxY, dateLabel.frame.maxY + 5))
        
        // 追加分の表示
        var top: CGFloat = headerImageView.frame.maxY
        for index in 0..<serviceLabels.count {
            let label = serviceLabels[index]
            let textView = urlLabels[index]
            
            label.frame.size.width = screenBounds.width * 0.4
            label.sizeToFit()
            label.frame = CGRect(x: 0,
                                 y: top,
                                 width: screenBounds.width * 0.4,
                                 height: label.frame.height)
            
            textView.frame.size.width = screenBounds.width * 0.6
            textView.sizeToFit()
            textView.frame = CGRect(x: screenBounds.width * 0.4,
                                    y: top,
                                    width: screenBounds.width * 0.6,
                                    height: textView.frame.height)
            
            let height = max(label.frame.height, textView.frame.height)
            label.frame.size.height = height
            textView.frame.size.height = height
            
            top = max(label.frame.maxY, textView.frame.maxY) + 4
        }
        
        // 数の表示
        statusCountTitle.frame = CGRect(x: 5,
                                        y: top,
                                        width: screenBounds.width / 3,
                                        height: SettingsData.fontSize)
        statusCountLabel.frame = CGRect(x: 0,
                                        y: top + SettingsData.fontSize,
                                        width: screenBounds.width / 3,
                                        height: SettingsData.fontSize)
        
        followingCountTitle.frame = CGRect(x: screenBounds.width / 3 + 5,
                                           y: top,
                                           width: screenBounds.width / 3,
                                           height: SettingsData.fontSize)
        followingCountLabel.frame = CGRect(x: screenBounds.width / 3,
                                           y: top + SettingsData.fontSize,
                                           width: screenBounds.width / 3,
                                           height: SettingsData.fontSize)
        
        followerCountTitle.frame = CGRect(x: screenBounds.width * 2 / 3 + 5,
                                          y: top,
                                          width: screenBounds.width / 3,
                                          height: SettingsData.fontSize)
        followerCountLabel.frame = CGRect(x: screenBounds.width * 2 / 3,
                                          y: top + SettingsData.fontSize,
                                          width: screenBounds.width / 3,
                                          height: SettingsData.fontSize)
        
        self.frame.size.height = top + SettingsData.fontSize * 2 + 8
    }
}
