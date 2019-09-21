//
//  TootView.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/21.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit

final class TootView: UIView {
    // 下書き保存
    static var isTooted = false
    static var savedText: String?
    static var savedSpoilerText: String?
    static var savedImages: [URL] = []
    static var inReplyToId: String? = nil
    static var inReplyToContent: String? = nil
    static var scheduledDate: Date? = nil
    static var savedProtectMode: SettingsData.ProtectMode = .publicMode
    
    //----
    
    private var keyBoardHeight: CGFloat = 0
    var protectMode = SettingsData.protectMode
    
    // 閉じるボタン
    let closeButton = UIButton()
    
    // トゥート
    let spoilerTextField = NoAnimationTextView()
    let textField = NoAnimationTextView()
    let tootButton = UIButton()
    let textCountLabel = UILabel()
    let inReplyToLabel = UILabel()
    
    // 入力バー
    let inputBar = UIView()
    let imagesButton = UIButton()
    let imagesCountButton = UIButton()
    let protectButton = UIButton()
    let cwButton = UIButton()
    let optionButton = UIButton()
    let emojiButton = UIButton()
    
    // 画像チェック画面
    let imageCheckView = ImageCheckView()
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        
        if TootView.savedText != nil || TootView.savedSpoilerText != nil {
            // 絵文字データを取得
            let emojiCache = EmojiData.getEmojiCache(host: SettingsData.hostName ?? "", showHiddenEmoji: true)
            var emojis: [[String: Any]] = []
            for emoji in emojiCache.0 {
                let dict: [String: Any] = ["shortcode": emoji.short_code ?? "",
                                           "url": emoji.url ?? ""]
                emojis.append(dict)
            }
            
            // 下書きを復帰
            self.textField.attributedText = DecodeToot.decodeName(name: TootView.savedText, emojis: emojis, callback: nil)
            self.spoilerTextField.attributedText = DecodeToot.decodeName(name: TootView.savedSpoilerText, emojis: emojis, callback: nil)
            self.protectMode = TootView.savedProtectMode
        }
        self.imageCheckView.urls = TootView.savedImages
        
        // キーボードの高さを監視
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        self.backgroundColor = UIColor.clear
        self.isOpaque = false
        
        self.addSubview(closeButton)
        self.addSubview(tootButton)
        self.addSubview(textCountLabel)
        self.addSubview(inReplyToLabel)
        
        self.addSubview(spoilerTextField)
        self.addSubview(textField)
        
        self.addSubview(inputBar)
        inputBar.addSubview(imagesButton)
        inputBar.addSubview(imagesCountButton)
        inputBar.addSubview(protectButton)
        inputBar.addSubview(cwButton)
        inputBar.addSubview(optionButton)
        inputBar.addSubview(emojiButton)
        
        self.addSubview(imageCheckView)
        
        imageCheckView.isHidden = true
        spoilerTextField.isHidden = true
        
        refresh()
        
        self.layoutSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // 閉じる時に下書きに保存
        if !TootView.isTooted {
            TootView.savedText = DecodeToot.encodeEmoji(attributedText: self.textField.attributedText, textStorage: self.textField.textStorage)
            TootView.savedSpoilerText = DecodeToot.encodeEmoji(attributedText: self.spoilerTextField.attributedText, textStorage: self.spoilerTextField.textStorage)
            TootView.savedImages = self.imageCheckView.urls
            TootView.savedProtectMode = self.protectMode
        }
        TootView.isTooted = false
    }
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let curve = UIView.KeyframeAnimationOptions(rawValue: UInt(truncating: userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber))
            let duration = TimeInterval(truncating: userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber)
            if let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
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
    
    func refresh() {
        closeButton.setTitle(I18n.get("BUTTON_CLOSE"), for: .normal)
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        closeButton.backgroundColor = ThemeColor.mainButtonsBgColor
        closeButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        closeButton.setTitleShadowColor(ThemeColor.viewBgColor, for: .normal)
        closeButton.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)
        closeButton.clipsToBounds = true
        closeButton.layer.cornerRadius = 10
        closeButton.layer.borderColor = ThemeColor.mainButtonsTitleColor.cgColor
        closeButton.layer.borderWidth = 2 / UIScreen.main.scale
        
        if TootView.scheduledDate != nil {
            tootButton.setTitle(I18n.get("BUTTON_SCHEDULED_TOOT"), for: .normal)
        } else {
            tootButton.setTitle(I18n.get("BUTTON_TOOT"), for: .normal)
        }
        tootButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        tootButton.backgroundColor = ThemeColor.mainButtonsBgColor
        tootButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        tootButton.setTitleShadowColor(ThemeColor.viewBgColor, for: .normal)
        tootButton.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)
        tootButton.clipsToBounds = true
        tootButton.layer.cornerRadius = 10
        tootButton.layer.borderColor = ThemeColor.mainButtonsTitleColor.cgColor
        tootButton.layer.borderWidth = 2 / UIScreen.main.scale
        
        textCountLabel.textColor = ThemeColor.contrastColor
        textCountLabel.font = UIFont.systemFont(ofSize: 18)
        textCountLabel.backgroundColor = ThemeColor.viewBgColor.withAlphaComponent(0.3)
        textCountLabel.textAlignment = .center
        textCountLabel.adjustsFontSizeToFitWidth = true
        textCountLabel.clipsToBounds = true
        textCountLabel.layer.cornerRadius = 10
        
        inReplyToLabel.textColor = ThemeColor.contrastColor
        inReplyToLabel.font = UIFont.systemFont(ofSize: 18)
        inReplyToLabel.backgroundColor = ThemeColor.viewBgColor.withAlphaComponent(0.3)
        inReplyToLabel.textAlignment = .center
        inReplyToLabel.clipsToBounds = true
        inReplyToLabel.layer.cornerRadius = 10
        if TootView.inReplyToId != nil {
            inReplyToLabel.text = "↩︎"
        } else {
            inReplyToLabel.text = nil
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showInReplyToString))
        inReplyToLabel.addGestureRecognizer(tapGesture)
        inReplyToLabel.isUserInteractionEnabled = true
        
        spoilerTextField.backgroundColor = ThemeColor.cellBgColor
        spoilerTextField.textColor = ThemeColor.messageColor
        spoilerTextField.font = UIFont.systemFont(ofSize: SettingsData.fontSize + 2)
        spoilerTextField.isEditable = true
        spoilerTextField.layer.borderColor = ThemeColor.messageColor.cgColor
        spoilerTextField.layer.borderWidth = 1 / UIScreen.main.scale
        spoilerTextField.tag = UIUtils.responderTag2
        
        if imageCheckView.isHidden {
            DispatchQueue.main.async {
                self.textField.becomeFirstResponder()
            }
        }
        textField.backgroundColor = ThemeColor.cellBgColor
        textField.textColor = ThemeColor.messageColor
        textField.font = UIFont.systemFont(ofSize: SettingsData.fontSize + 2)
        textField.isEditable = true
        textField.layer.borderColor = ThemeColor.messageColor.cgColor
        textField.layer.borderWidth = 1 / UIScreen.main.scale
        textField.tag = UIUtils.responderTag
        
        inputBar.backgroundColor = ThemeColor.cellBgColor
        
        imagesButton.setTitle("🏞", for: .normal)
        
        if imageCheckView.urls.count == 0 {
            imagesCountButton.isHidden = true
        } else {
            imagesCountButton.isHidden = false
            imagesCountButton.setTitle("[\(imageCheckView.urls.count)]", for: .normal)
        }
        imagesCountButton.setTitleColor(ThemeColor.messageColor, for: .normal)
        
        switch self.protectMode {
        case .publicMode:
            protectButton.setTitle("🌐", for: .normal)
        case .unlisted:
            protectButton.setTitle("🔓", for: .normal)
        case .privateMode:
            protectButton.setTitle("🔐", for: .normal)
        case .direct:
            protectButton.setTitle("✉️", for: .normal)
        }
        
        cwButton.setTitle("CW", for: .normal)
        cwButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        
        optionButton.setTitle("…", for: .normal)
        optionButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        
        emojiButton.setTitle("😀", for: .normal)
    }
    
    @objc func showInReplyToString() {
        Dialog.show(message: TootView.inReplyToContent ?? "")
    }
    
    override func layoutSubviews() {
        let screenBounds = UIScreen.main.bounds
        
        closeButton.frame = CGRect(x: 10,
                                   y: 0,
                                   width: 80,
                                   height: 40)
        
        tootButton.frame = CGRect(x: screenBounds.width - 90,
                                  y: 0,
                                  width: 80,
                                  height: 40)
        
        if inReplyToLabel.text == nil {
            inReplyToLabel.frame = CGRect(x: 0,
                                          y: 0,
                                          width: 0,
                                          height: 0)
            
            textCountLabel.frame = CGRect(x: screenBounds.width / 2 - 120 / 2,
                                          y: 9,
                                          width: 120,
                                          height: 22)
        } else {
            inReplyToLabel.frame = CGRect(x: screenBounds.width / 2 - 140 / 2,
                                          y: 3,
                                          width: 30,
                                          height: 34)
            
            textCountLabel.frame = CGRect(x: screenBounds.width / 2 - 140 / 2 + 30,
                                          y: 9,
                                          width: 110,
                                          height: 22)
        }
        
        var top: CGFloat = 40
        if spoilerTextField.isHidden == false {
            spoilerTextField.sizeToFit()
            spoilerTextField.frame = CGRect(x: 1,
                                            y: 40,
                                            width: screenBounds.width - 2,
                                            height: min(max(25, spoilerTextField.frame.height), 80))
            top = spoilerTextField.frame.maxY + 2
        }
        
        textField.sizeToFit()
        textField.frame = CGRect(x: 1,
                                 y: top,
                                 width: screenBounds.width - 2,
                                 height: min(max(60, textField.frame.height), screenBounds.height - keyBoardHeight - UIUtils.statusBarHeight() - top - 40))
        
        inputBar.frame = CGRect(x: 0,
                                y: top + textField.frame.height,
                                width: screenBounds.width,
                                height: 40)
        
        let buttonWidthSum: CGFloat = 40 * 5 + (imagesCountButton.titleLabel?.text != nil ? 40 : 10)
        let margin: CGFloat = floor((screenBounds.width - buttonWidthSum) / 5)
        
        imagesButton.frame = CGRect(x: margin / 2,
                                    y: 0,
                                    width: 40,
                                    height: 40)
        
        imagesCountButton.frame = CGRect(x: imagesButton.frame.maxX,
                                         y: 0,
                                         width: imagesCountButton.titleLabel?.text != nil ? 40 : 10,
                                         height: 40)
        
        protectButton.frame = CGRect(x: imagesCountButton.frame.maxX + margin,
                                     y: 0,
                                     width: 40,
                                     height: 40)
        
        cwButton.frame = CGRect(x: protectButton.frame.maxX + margin,
                                y: 0,
                                width: 40,
                                height: 40)
        
        optionButton.frame = CGRect(x: cwButton.frame.maxX + margin,
                                    y: 0,
                                    width: 40,
                                    height: 40)
        
        if SettingsData.instanceVersion(hostName: SettingsData.hostName ?? "") >= 269.9 { // v2.7以上
            optionButton.isHidden = false
        } else {
            optionButton.isHidden = true
        }
        
        emojiButton.frame = CGRect(x: optionButton.frame.maxX + margin,
                                   y: 0,
                                   width: 40,
                                   height: 40)
        
        let viewHeight: CGFloat
        if imageCheckView.isHidden {
            viewHeight = textField.frame.maxY + 40
        } else {
            imageCheckView.layoutSubviews()
            imageCheckView.frame.origin.y = textField.frame.maxY + 40
            
            viewHeight = imageCheckView.frame.maxY
        }
        
        self.frame = CGRect(x: 0,
                            y: max(0, screenBounds.height - keyBoardHeight - viewHeight),
                            width: screenBounds.width,
                            height: viewHeight)
        
    }
}

final class NoAnimationTextView: UITextView {
    override func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        super.setContentOffset(contentOffset, animated: false)
    }
}
