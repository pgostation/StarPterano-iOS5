//
//  EmojiKeyboard.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/21.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 絵文字入力用のカスタムキーボードを表示する

import UIKit
import SwiftyGif
import APNGKit

final class EmojiKeyboard: UIView {
    private let spaceButton = UIButton()
    private let returnButton = UIButton()
    private let deleteButton = UIButton()
    private let searchButton = UIButton()
    private let emojiScrollView = EmojiInputScrollView()
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIUtils.isIphoneX ? 320 : 250))
        
        self.addSubview(spaceButton)
        self.addSubview(returnButton)
        self.addSubview(deleteButton)
        self.addSubview(searchButton)
        self.addSubview(emojiScrollView)
        
        spaceButton.addTarget(self, action: #selector(spaceAction), for: .touchUpInside)
        returnButton.addTarget(self, action: #selector(returnAction), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteAction), for: .touchUpInside)
        searchButton.addTarget(self, action: #selector(searchAction), for: .touchUpInside)
        
        let pressDeleteGesture = UILongPressGestureRecognizer(target: self, action: #selector(pressDeleteAction(_:)))
        deleteButton.addGestureRecognizer(pressDeleteGesture)
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.backgroundColor = ThemeColor.cellBgColor
        
        spaceButton.setTitle(I18n.get("BUTTON_SPACEKEY"), for: .normal)
        spaceButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        spaceButton.titleLabel?.adjustsFontSizeToFitWidth = true
        spaceButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
        spaceButton.clipsToBounds = true
        spaceButton.layer.cornerRadius = 10
        
        returnButton.setTitle(I18n.get("BUTTON_RETURNKEY"), for: .normal)
        returnButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        returnButton.titleLabel?.adjustsFontSizeToFitWidth = true
        returnButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
        returnButton.clipsToBounds = true
        returnButton.layer.cornerRadius = 10
        
        deleteButton.setTitle(I18n.get("BUTTON_BACKKEY"), for: .normal)
        deleteButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        deleteButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
        deleteButton.clipsToBounds = true
        deleteButton.layer.cornerRadius = 10
        
        searchButton.setTitle("🔍", for: .normal)
        searchButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
        searchButton.clipsToBounds = true
        searchButton.layer.cornerRadius = 10
    }
    
    @objc func spaceAction() {
        guard let textView = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag) else { return }
        let textView2 = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag2)
        
        if textView2?.isFirstResponder == true {
            (textView2 as? UITextView)?.insertText(" ")
            return
        }
        (textView as? UITextView)?.insertText(" ")
    }
    
    @objc func returnAction() {
        guard let textView = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag) else { return }
        let textView2 = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag2)
        
        if textView2?.isFirstResponder == true {
            (textView2 as? UITextView)?.insertText("\n")
            return
        }
        (textView as? UITextView)?.insertText("\n")
    }
    
    @objc func deleteAction() {
        guard let textView = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag) else { return }
        let textView2 = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag2)
        
        if textView2?.isFirstResponder == true {
            (textView2 as? UITextView)?.deleteBackward()
            return
        }
        (textView as? UITextView)?.deleteBackward()
    }
    
    @objc func searchAction() {
        Dialog.showWithTextInput(message: I18n.get("DIALOG_SEARCH_EMOJI"), okName: "OK", cancelName: "Cancel", defaultText: nil, isAlphabet: true, callback: { textField, result in
            if !result {
                self.emojiScrollView.searchText = nil
            } else {
                self.emojiScrollView.searchText = textField.text
            }
            self.emojiScrollView.setNeedsLayout()
        })
    }
    
    // 削除押しっぱなし
    private var pressTimer: Timer?
    @objc func pressDeleteAction(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            if #available(iOS 10.0, *) {
                self.pressTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true, block: { (timer) in
                    self.deleteAction()
                })
            }
        }
        if gesture.state == .ended || gesture.state == .cancelled {
            self.pressTimer?.invalidate()
            self.pressTimer = nil
        }
    }
 
    override func layoutSubviews() {
        self.spaceButton.frame = CGRect(x: 10,
                                        y: 1,
                                        width: 80,
                                        height: 40)
        
        self.returnButton.frame = CGRect(x: 95,
                                         y: 1,
                                         width: 80,
                                         height: 40)
        
        self.deleteButton.frame = CGRect(x: 180,
                                         y: 1,
                                         width: 80,
                                         height: 40)
        
        self.searchButton.frame = CGRect(x: 265,
                                         y: 1,
                                         width: 40,
                                         height: 40)
        
        self.emojiScrollView.frame = CGRect(x: 0,
                                            y: 44,
                                            width: self.frame.width,
                                            height: self.frame.height - 44)
    }
}

private final class EmojiInputScrollView: UIScrollView {
    private var emojiList = EmojiData.getEmojiCache(host: SettingsData.hostName!, showHiddenEmoji: false)
    private var emojiButtons: [EmojiButton] = []
    var searchText: String?
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        
        if self.emojiList.count > 0 {
            addEmojis()
        } else {
            // 絵文字データが取れるまでリトライする
            func retry(count: Int) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if self.emojiList.count > 0 {
                        self.addEmojis()
                        self.setNeedsLayout()
                    } else if count <= 3 {
                        retry(count: count + 1)
                    }
                }
            }
            
            retry(count: 0)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        while let apngView = self.viewWithTag(5555) as? APNGImageView {
            apngView.stopAnimating()
            apngView.removeFromSuperview()
        }
    }
    
    private func addEmojis() {
        // 絵文字ボタンの追加
        for emoji in self.emojiList {
            let button = EmojiButton(key: emoji.short_code ?? "")
            if SettingsData.useAnimation && emoji.url?.hasSuffix(".png") == true {
                APNGImageCache.image(urlStr: emoji.url) { image in
                    // APNGのビューを貼り付ける
                    let imageView = APNGImageView(image: image)
                    imageView.tag = 5555
                    if image.frameCount > 1 {
                        imageView.autoStartAnimation = true
                    }
                    let buttonSize: CGFloat = 24 + SettingsData.fontSize
                    imageView.frame = CGRect(x: 0,
                                             y: 0,
                                             width: buttonSize,
                                             height: buttonSize)
                    button.addSubview(imageView)
                }
            } else {
                // APNG以外
                ImageCache.image(urlStr: emoji.url, isTemp: false, isSmall: true, shortcode: emoji.short_code) { image in
                    button.setImage(image, for: .normal)
                }
            }
            button.addTarget(self, action: #selector(tapButton(_:)), for: .touchUpInside)
            
            let pressGesture = UILongPressGestureRecognizer(target: self, action: #selector(pressButton(_:)))
            button.addGestureRecognizer(pressGesture)
            
            self.addSubview(button)
            
            emojiButtons.append(button)
        }
    }
    
    // テキスト入力欄にテキストを追加
    @objc func tapButton(_ button: UIButton) {
        guard let button = button as? EmojiButton else { return }
        
        guard let textView = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag) else { return }
        let textView2 = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag2)
        
        var emojis: [[String: Any]] = []
        
        for emoji in EmojiData.getEmojiCache(host: SettingsData.hostName ?? "", showHiddenEmoji: true) {
            let dict: [String: Any] = ["shortcode": emoji.short_code ?? "",
                                       "url": emoji.url ?? ""]
            emojis.append(dict)
        }
        
        if textView2?.isFirstResponder == true {
            if let textView2 = textView2 as? UITextView {
                textView2.insertText(" :" + button.key + ": ")
                
                // ダークモードでテキストが黒に戻ってしまう問題対策として、もう一度フォントを設定
                textView2.textColor = ThemeColor.messageColor
                textView2.font = UIFont.systemFont(ofSize: SettingsData.fontSize + 5)
            }
            return
        }
        
        if let textView = textView as? UITextView {
            textView.insertText(" :" + button.key + ": ")
            
            // ダークモードでテキストが黒に戻ってしまう問題対策として、もう一度フォントを設定
            textView.textColor = ThemeColor.messageColor
            textView.font = UIFont.systemFont(ofSize: SettingsData.fontSize + 5)
        }
    }
    
    // 絵文字情報を表示
    @objc func pressButton(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began, let button = gesture.view as? EmojiButton {
            Dialog.show(message: button.key)
        }
    }
    
    private final class EmojiButton: UIButton {
        let key: String
        
        init(key: String) {
            self.key = key
            
            super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    override func layoutSubviews() {
        if let searchText = self.searchText {
            let filteredEmojiButtons = getFilteredEmojiButtons(key: searchText)
            
            layoutEmojiButtons(emojiButtons: filteredEmojiButtons)
            return
        }
        
        layoutEmojiButtons(emojiButtons: self.emojiButtons)
    }
    
    private func layoutEmojiButtons(emojiButtons: [UIButton]) {
        let buttonSize: CGFloat = 22 + SettingsData.fontSize
        let margin: CGFloat = 2
        let screenBounds = UIScreen.main.bounds
        let xCount = floor(screenBounds.width / (buttonSize + margin)) // ボタンの横に並ぶ数
        let yCount = ceil(CGFloat(emojiButtons.count) / xCount) // ボタンの縦に並ぶ数
        let viewHeight = (buttonSize + margin) * yCount
        
        self.contentSize = CGSize(width: screenBounds.width, height: viewHeight)
        
        for y in 0..<Int(yCount) {
            for x in 0..<Int(xCount) {
                let index = y * Int(xCount) + x
                if index >= emojiButtons.count { break }
                let button = emojiButtons[index]
                button.frame = CGRect(x: CGFloat(x) * (buttonSize + margin),
                                      y: CGFloat(y) * (buttonSize + margin),
                                      width: buttonSize,
                                      height: buttonSize)
            }
        }
    }
    
    private func getFilteredEmojiButtons(key: String) -> [UIButton] {
        var buttons: [UIButton] = []
        
        for button in self.emojiButtons {
            if button.key.contains(key) {
                buttons.append(button)
            } else {
                button.frame.origin.x = -100
            }
        }
        
        return buttons
    }
}
