//
//  ProfileEditView.swift
//  DonParade
//
//  Created by takayoshi on 2018/10/11.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit

final class ProfileEditView: UIScrollView {
    // ボタン
    let closeButton = UIButton()
    let saveButton = UIButton()
    let iconButton = UIButton()
    let headerButton = UIButton()
    let lockedSwitch = UISwitch()
    
    // ラベル
    let nameLabel = UILabel()
    let noteLabel = UILabel()
    let titlesLabel = UILabel()
    let fieldsLabel = UILabel()
    let lockedLabel = UILabel()
    
    // 入力フィールド
    let nameField = UITextView()
    let noteView = UITextView()
    let addTitles = [UITextField(), UITextField(), UITextField(), UITextField()]
    let addFields = [UITextView(), UITextView(), UITextView(), UITextView()]
    
    // 画像
    var iconView: UIImageView? = nil
    var headerView: UIImageView? = nil
    
    // 入力バー
    let inputBar = UIView()
    let emojiButton = UIButton()
    private var keyBoardHeight: CGFloat = 0
    
    init(accountData: AnalyzeJson.AccountData) {
        super.init(frame: UIScreen.main.bounds)
        
        self.addSubview(nameLabel)
        self.addSubview(noteLabel)
        self.addSubview(titlesLabel)
        self.addSubview(fieldsLabel)
        self.addSubview(lockedLabel)
        
        self.addSubview(closeButton)
        self.addSubview(saveButton)
        self.addSubview(nameField)
        self.addSubview(noteView)
        for title in addTitles {
            self.addSubview(title)
        }
        for field in addFields {
            self.addSubview(field)
        }
        self.addSubview(iconButton)
        self.addSubview(headerButton)
        self.addSubview(lockedSwitch)
        self.addSubview(inputBar)
        inputBar.addSubview(emojiButton)
        
        setProperties(accountData: accountData)
        
        // キーボードの高さを監視
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillShow(_:)),
            name: NSNotification.Name.UIKeyboardWillShow,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillHide(_:)),
            name: NSNotification.Name.UIKeyboardWillHide,
            object: nil
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties(accountData: AnalyzeJson.AccountData) {
        self.backgroundColor = ThemeColor.viewBgColor
        self.isUserInteractionEnabled = true
        
        // ラベル
        self.nameLabel.text = I18n.get("PROFILE_NAME")
        self.nameLabel.textColor = ThemeColor.dateColor
        self.nameLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize - 2)
        
        self.noteLabel.text = I18n.get("PROFILE_NOTE")
        self.noteLabel.textColor = ThemeColor.dateColor
        self.noteLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize - 2)
        
        self.titlesLabel.text = I18n.get("PROFILE_TITLES")
        self.titlesLabel.textColor = ThemeColor.dateColor
        self.titlesLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize - 2)
        
        self.fieldsLabel.text = I18n.get("PROFILE_FIELDS")
        self.fieldsLabel.textColor = ThemeColor.dateColor
        self.fieldsLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize - 2)
        
        self.lockedLabel.text = I18n.get("PROFILE_LOCKED")
        self.lockedLabel.textColor = ThemeColor.dateColor
        self.lockedLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
        
        // 名前
        self.nameField.attributedText = DecodeToot.decodeName(name: accountData.display_name, emojis: accountData.emojis, callback: {
            self.nameField.attributedText = DecodeToot.decodeName(name: accountData.display_name, emojis: accountData.emojis, callback: nil)
            self.nameField.textColor = ThemeColor.idColor
            self.nameField.font = UIFont.systemFont(ofSize: SettingsData.fontSize + 3)
        })
        self.nameField.textColor = ThemeColor.idColor
        self.nameField.backgroundColor = ThemeColor.cellBgColor
        self.nameField.layer.borderWidth = 1
        self.nameField.layer.borderColor = ThemeColor.dateColor.cgColor
        self.nameField.returnKeyType = .done
        self.nameField.font = UIFont.systemFont(ofSize: SettingsData.fontSize + 3)
        
        // ノート
        self.noteView.attributedText = DecodeToot.decodeContentFast(content: accountData.note, emojis: accountData.emojis, callback: {
            self.noteView.attributedText = DecodeToot.decodeContentFast(content: accountData.note, emojis: accountData.emojis, callback: nil).0
            self.noteView.textColor = ThemeColor.idColor
            self.noteView.font = UIFont.systemFont(ofSize: SettingsData.fontSize + 3)
        }).0
        self.noteView.linkTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: ThemeColor.linkTextColor]
        self.noteView.textColor = ThemeColor.idColor
        self.noteView.backgroundColor = ThemeColor.cellBgColor
        self.noteView.layer.borderWidth = 1
        self.noteView.layer.borderColor = ThemeColor.dateColor.cgColor
        self.noteView.returnKeyType = .default
        self.noteView.font = UIFont.systemFont(ofSize: SettingsData.fontSize + 3)
        
        // 追加フィールド
        for (index, title) in addTitles.enumerated() {
            if index < (accountData.fields ?? []).count {
                let data = accountData.fields![index]
                title.text = data["title"] as? String
            }
            title.borderStyle = .line
            title.textColor = ThemeColor.idColor
            title.backgroundColor = ThemeColor.cellBgColor
            title.layer.borderWidth = 1
            title.layer.borderColor = ThemeColor.dateColor.cgColor
            title.returnKeyType = .done
            title.font = UIFont.systemFont(ofSize: SettingsData.fontSize + 3)
        }
        for (index, field) in addFields.enumerated() {
            if index < (accountData.fields ?? []).count {
                let data = accountData.fields![index]
                let content = data["value"] as? String
                field.attributedText = DecodeToot.decodeContentFast(content: content, emojis: accountData.emojis, callback: {
                    field.attributedText = DecodeToot.decodeContentFast(content: content, emojis: accountData.emojis, callback: nil).0
                    field.textColor = ThemeColor.idColor
                    field.font = UIFont.systemFont(ofSize: SettingsData.fontSize + 3)
                }).0
            }
            field.textColor = ThemeColor.idColor
            field.backgroundColor = ThemeColor.cellBgColor
            field.layer.borderWidth = 1
            field.layer.borderColor = ThemeColor.dateColor.cgColor
            field.returnKeyType = .default
            field.font = UIFont.systemFont(ofSize: SettingsData.fontSize + 3)
        }
        
        // アイコン
        ImageCache.image(urlStr: accountData.avatar, isTemp: false, isSmall: false) { [weak self] (image) in
            guard let strongSelf = self else { return }
            
            if image.imageCount != nil {
                strongSelf.iconView = UIImageView(gifImage: image)
            } else {
                strongSelf.iconView = UIImageView(image: image)
            }
            strongSelf.iconView?.clipsToBounds = true
            strongSelf.iconView?.layer.cornerRadius = 8
            strongSelf.insertSubview(strongSelf.iconView!, at: 1)
            strongSelf.setNeedsLayout()
        }
        
        // ヘッダ画像
        ImageCache.image(urlStr: accountData.header, isTemp: false, isSmall: false) { [weak self] (image) in
            guard let strongSelf = self else { return }
            
            if image.imageCount != nil {
                strongSelf.headerView = UIImageView(gifImage: image)
            } else {
                strongSelf.headerView = UIImageView(image: image)
            }
            strongSelf.insertSubview(strongSelf.headerView!, at: 0)
            strongSelf.setNeedsLayout()
        }
        
        // アイコン変更ボタン
        iconButton.setTitle(I18n.get("BUTTON_CHANGE_ICON"), for: .normal)
        iconButton.titleLabel?.adjustsFontSizeToFitWidth = true
        iconButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        iconButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
        iconButton.layer.cornerRadius = 8
        iconButton.clipsToBounds = true
        
        // ヘッダー画像変更ボタン
        headerButton.setTitle(I18n.get("BUTTON_CHANGE_HEADER"), for: .normal)
        headerButton.titleLabel?.adjustsFontSizeToFitWidth = true
        headerButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        headerButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
        headerButton.layer.cornerRadius = 8
        headerButton.clipsToBounds = true
        
        // ロックスイッチ
        lockedSwitch.isOn = (accountData.locked == 1)
        
        // 閉じるボタン
        closeButton.setTitle(I18n.get("BUTTON_CLOSE"), for: .normal)
        closeButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        closeButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
        closeButton.layer.cornerRadius = 8
        closeButton.clipsToBounds = true
        
        // 保存ボタン
        saveButton.setTitle(I18n.get("BUTTON_SEND"), for: .normal)
        saveButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        saveButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
        saveButton.layer.cornerRadius = 8
        saveButton.clipsToBounds = true
        
        inputBar.backgroundColor = ThemeColor.cellBgColor
        
        emojiButton.setTitle("😀", for: .normal)
    }
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let curve = UIViewKeyframeAnimationOptions(rawValue: UInt(truncating: userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber))
            let duration = TimeInterval(truncating: userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber)
            if let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                self.keyBoardHeight = keyboardFrame.height
                UIView.animateKeyframes(withDuration: duration, delay: 0, options: [curve], animations: {
                    self.layoutSubviews()
                }, completion: nil)
            }
        }
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        self.keyBoardHeight = 0
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.layoutSubviews()
        }
    }
    
    override func layoutSubviews() {
        let screenBounds = UIScreen.main.bounds
        var top: CGFloat = 0
        
        closeButton.frame = CGRect(x: 10,
                                   y: UIUtils.statusBarHeight(),
                                   width: 80,
                                   height: 40)
        top = closeButton.frame.maxY
        
        saveButton.frame = CGRect(x: screenBounds.width - 90,
                                  y: UIUtils.statusBarHeight(),
                                  width: 80,
                                  height: 40)
        
        nameLabel.frame = CGRect(x: 10,
                                 y: top + 5,
                                 width: screenBounds.width - 20,
                                 height: SettingsData.fontSize)
        top = nameLabel.frame.maxY
        
        nameField.frame = CGRect(x: 10,
                                 y: top,
                                 width: screenBounds.width - 20,
                                 height: 30)
        top = nameField.frame.maxY
        
        noteLabel.frame = CGRect(x: 10,
                                 y: top + 5,
                                 width: screenBounds.width - 20,
                                 height: SettingsData.fontSize)
        top = noteLabel.frame.maxY
        
        noteView.frame = CGRect(x: 10,
                                y: top,
                                width: screenBounds.width - 20,
                                height: 120)
        top = noteView.frame.maxY
        
        titlesLabel.frame = CGRect(x: 1,
                                   y: top + 5,
                                   width: screenBounds.width - 20,
                                   height: SettingsData.fontSize)
        fieldsLabel.frame = CGRect(x: screenBounds.width * 0.4,
                                   y: top + 5,
                                   width: screenBounds.width - 20,
                                   height: SettingsData.fontSize)
        top = fieldsLabel.frame.maxY
        
        for (index, title) in addTitles.enumerated() {
            title.frame = CGRect(x: 1,
                                 y: top + CGFloat(index) * 60,
                                 width: screenBounds.width * 0.4 - 1,
                                 height: 60)
        }
        
        for (index, field) in addFields.enumerated() {
            field.frame = CGRect(x: screenBounds.width * 0.4,
                                 y: top + CGFloat(index) * 60,
                                 width: screenBounds.width * 0.6 - 1,
                                 height: 60)
        }
        top = addFields.last?.frame.maxY ?? top
        
        self.iconView?.frame = CGRect(x: 20,
                                      y: top + 10,
                                      width: 70,
                                      height: 70)
        
        self.iconButton.frame = CGRect(x: 5,
                                       y: top + 85,
                                       width: 100,
                                       height: 40)
        
        self.headerView?.frame = CGRect(x: 0,
                                        y: top + 5,
                                        width: screenBounds.width,
                                        height: screenBounds.width / 3)
        
        self.headerButton.frame = CGRect(x: screenBounds.width - 105,
                                         y: self.headerView?.frame.maxY ?? top,
                                         width: 100,
                                         height: 40)
        top = self.headerButton.frame.maxY
        
        self.lockedLabel.sizeToFit()
        self.lockedLabel.frame = CGRect(x: 5,
                                         y: top,
                                         width: self.lockedLabel.frame.width,
                                         height: 31)
        
        self.lockedSwitch.frame = CGRect(x: self.lockedLabel.frame.maxX + 5,
                                        y: top,
                                        width: 51,
                                        height: 31)
        top = self.lockedSwitch.frame.maxY
        
        if keyBoardHeight > 0 {
            self.inputBar.frame = CGRect(x: 0,
                                         y: screenBounds.height - keyBoardHeight - 40 + self.contentOffset.y,
                                         width: screenBounds.width,
                                         height: 40)
        } else {
            self.inputBar.frame = CGRect(x: 0,
                                         y: screenBounds.height + self.contentOffset.y,
                                         width: screenBounds.width,
                                         height: 40)
        }
        
        self.emojiButton.frame = CGRect(x: screenBounds.width - 50,
                                        y: 0,
                                        width: 40,
                                        height: 40)
        
        self.contentSize = CGSize(width: screenBounds.width,
                                  height: top + 5 + keyBoardHeight + 40)
    }
}
