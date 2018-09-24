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

final class ProfileViewCell: UITableViewCell {
    // ヘッダ画像
    let headerImageView = UIImageView()
    
    // メインの表示
    let iconView = UIImageView()
    let nameLabel = UILabel()
    let idLabel = UILabel()
    let noteLabel = UILabel()
    let dateLabel = UILabel()
    let urlLabel = UILabel()
    
    // 追加分の表示
    var serviceLabels: [UILabel] = []
    var urlLabels: [UILabel] = []
    
    // 数の表示
    let followingCountTitle = UILabel()
    let followingCountLabel = UILabel()
    let followerCountTitle = UILabel()
    let followerCountLabel = UILabel()
    let statusCountTitle = UILabel()
    let statusCountLabel = UILabel()
    
    // フォローしているか、フォローされているかの表示
    let isFollowingLabel = UILabel()
    let isFollowedLabel = UILabel()
    
    // アクションボタン
    //  フォローしたり、アンフォローしたり、ブロックしたり、ミュートしたり、リストに入れたり、ブラウザで開いたりする
    let actionButton = UIButton()
    
    init(accountData: AnalyzeJson.AccountData?) {
        super.init(style: .default, reuseIdentifier: nil)
        
        // ヘッダ画像
        self.addSubview(headerImageView)
        
        // メインの表示
        self.addSubview(iconView)
        self.addSubview(nameLabel)
        self.addSubview(idLabel)
        self.addSubview(noteLabel)
        self.addSubview(dateLabel)
        self.addSubview(urlLabel)
        
        // 数の表示
        self.addSubview(followingCountTitle)
        self.addSubview(followingCountLabel)
        self.addSubview(followerCountTitle)
        self.addSubview(followerCountLabel)
        self.addSubview(statusCountTitle)
        self.addSubview(statusCountLabel)
        
        // フォローしているか、フォローされているかの表示
        self.addSubview(isFollowingLabel)
        self.addSubview(isFollowedLabel)
        
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
        ImageCache.image(urlStr: data.header_static, isTemp: true, isSmall: false) { [weak self] image in
            self?.headerImageView.image = image
            self?.setNeedsLayout()
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
        
        noteLabel.attributedText = DecodeToot.decodeContent(content: data.note, emojis: data.emojis, callback: nil).0
        noteLabel.textColor = ThemeColor.idColor
        noteLabel.shadowColor = ThemeColor.viewBgColor
        noteLabel.shadowOffset = CGSize(width: 0.5, height: 0.5)
        noteLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
        noteLabel.numberOfLines = 0
        noteLabel.lineBreakMode = .byCharWrapping
        
        dateLabel.text = data.created_at
        dateLabel.textColor = ThemeColor.idColor
        dateLabel.shadowColor = ThemeColor.viewBgColor
        dateLabel.shadowOffset = CGSize(width: 0.5, height: 0.5)
        dateLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
        
        urlLabel.text = data.url
        urlLabel.textColor = ThemeColor.idColor
        urlLabel.shadowColor = ThemeColor.viewBgColor
        urlLabel.shadowOffset = CGSize(width: 0.5, height: 0.5)
        urlLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
        urlLabel.numberOfLines = 0
        urlLabel.lineBreakMode = .byCharWrapping
        
        // 追加分の表示
        for field in data.fields ?? [] {
            let nameLabel = UILabel()
            nameLabel.text = field["name"] as? String
            nameLabel.textColor = ThemeColor.idColor
            nameLabel.shadowColor = ThemeColor.viewBgColor
            nameLabel.shadowOffset = CGSize(width: 0.5, height: 0.5)
            nameLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
            nameLabel.numberOfLines = 0
            nameLabel.lineBreakMode = .byCharWrapping
            serviceLabels.append(nameLabel)
            self.addSubview(nameLabel)
            
            let valueLabel = UILabel()
            valueLabel.attributedText = DecodeToot.decodeContent(content: field["value"] as? String, emojis: nil, callback: nil).0
            valueLabel.textColor = ThemeColor.idColor
            valueLabel.shadowColor = ThemeColor.viewBgColor
            valueLabel.shadowOffset = CGSize(width: 0.5, height: 0.5)
            valueLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
            valueLabel.numberOfLines = 0
            valueLabel.lineBreakMode = .byCharWrapping
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
        
        urlLabel.frame.size.width = screenBounds.width - 80
        urlLabel.sizeToFit()
        urlLabel.frame = CGRect(x: 80,
                                y: noteLabel.frame.maxY + 5,
                                width: urlLabel.frame.width,
                                height: urlLabel.frame.height)
        
        dateLabel.frame = CGRect(x: 80,
                                 y: urlLabel.frame.maxY + 5,
                                 width: screenBounds.width - 80,
                                 height: 24)
        
        // ヘッダ画像
        headerImageView.contentMode = .scaleAspectFill
        headerImageView.frame = CGRect(x: 0,
                                       y: 0,
                                       width: screenBounds.width,
                                       height: dateLabel.frame.maxY + 5)
        
        // 追加分の表示
        var top: CGFloat = headerImageView.frame.maxY
        for label in serviceLabels {
            label.frame = CGRect(x: 0,
                                     y: top,
                                     width: screenBounds.width / 2,
                                     height: SettingsData.fontSize * 2)
            top += SettingsData.fontSize * 2
        }
        
        top = headerImageView.frame.maxY
        for label in urlLabels {
            label.frame = CGRect(x: screenBounds.width / 2,
                                 y: top,
                                 width: screenBounds.width / 2,
                                 height: SettingsData.fontSize * 2)
            top += SettingsData.fontSize * 2
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
        
        self.frame.size.height = top + SettingsData.fontSize * 2 + 4
    }
}
