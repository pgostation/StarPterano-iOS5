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
    private let emojiScrollView = EmojiInputScrollView()
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIUtils.isIphoneX ? 300 : 240))
        
        self.addSubview(spaceButton)
        self.addSubview(returnButton)
        self.addSubview(deleteButton)
        self.addSubview(emojiScrollView)
        
        spaceButton.addTarget(self, action: #selector(spaceAction), for: .touchUpInside)
        returnButton.addTarget(self, action: #selector(returnAction), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteAction), for: .touchUpInside)
        
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
    }
    
    @objc func spaceAction() {
        guard let textView = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag) else { return }
        guard let textView2 = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag2) else { return }
        
        if textView2.isFirstResponder {
            (textView2 as? UITextView)?.insertText(" ")
            return
        }
        (textView as? UITextView)?.insertText(" ")
    }
    
    @objc func returnAction() {
        guard let textView = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag) else { return }
        guard let textView2 = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag2) else { return }
        
        if textView2.isFirstResponder {
            (textView2 as? UITextView)?.insertText("\n")
            return
        }
        (textView as? UITextView)?.insertText("\n")
    }
    
    @objc func deleteAction() {
        guard let textView = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag) else { return }
        guard let textView2 = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag2) else { return }
        
        if textView2.isFirstResponder {
            (textView2 as? UITextView)?.deleteBackward()
            return
        }
        (textView as? UITextView)?.deleteBackward()
    }
    
    override func layoutSubviews() {
        self.spaceButton.frame = CGRect(x: 10,
                                        y: 1,
                                        width: 80,
                                        height: 40)
        
        self.returnButton.frame = CGRect(x: 100,
                                         y: 1,
                                         width: 80,
                                         height: 40)
        
        self.deleteButton.frame = CGRect(x: 190,
                                         y: 1,
                                         width: 80,
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
    private let gifManager = SwiftyGifManager(memoryLimit: 20)
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        
        if self.emojiList.count > 0 {
            addEmojis()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.addEmojis()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addEmojis() {
        // 絵文字ボタンの追加
        for emoji in self.emojiList {
            let button = EmojiButton(key: emoji.short_code ?? "")
            if SettingsData.useAnimation && emoji.url?.hasSuffix(".png") == true {
                // 上からAPNGのビューを貼り付ける
                APNGCache.image(urlStr: emoji.url) { image in
                    let imageView = APNGImageView(image: image)
                    imageView.autoStartAnimation = true
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
                    if emoji.url?.hasSuffix(".gif") == true {
                        // 上からGIFアニメーションのビューを貼り付ける
                        let imageView = UIImageView(gifImage: image, manager: self.gifManager, loopCount: SettingsData.useAnimation ? -1 : 0)
                        let buttonSize: CGFloat = 24 + SettingsData.fontSize
                        imageView.frame = CGRect(x: 0,
                                                 y: 0,
                                                 width: buttonSize,
                                                 height: buttonSize)
                        button.addSubview(imageView)
                    } else {
                        button.setImage(image, for: .normal)
                    }
                }
            }
            button.addTarget(self, action: #selector(tapButton(_:)), for: .touchUpInside)
            
            self.addSubview(button)
            
            emojiButtons.append(button)
        }
    }
    
    // テキスト入力欄にテキストを追加
    @objc func tapButton(_ button: UIButton) {
        guard let button = button as? EmojiButton else { return }
        
        guard let textView = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag) else { return }
        guard let textView2 = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag2) else { return }
        
        if textView2.isFirstResponder {
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
        let buttonSize: CGFloat = 24 + SettingsData.fontSize
        let margin: CGFloat = 2
        let screenBounds = UIScreen.main.bounds
        let xCount = floor(screenBounds.width / (buttonSize + margin)) // ボタンの横に並ぶ数
        let yCount = ceil(CGFloat(self.emojiList.count) / xCount) // ボタンの縦に並ぶ数
        let viewHeight = (buttonSize + margin) * yCount
        
        self.contentSize = CGSize(width: screenBounds.width, height: viewHeight)
        
        for y in 0..<Int(yCount) {
            for x in 0..<Int(xCount) {
                let index = y * Int(xCount) + x
                if index >= self.emojiList.count { break }
                let button = self.emojiButtons[index]
                button.frame = CGRect(x: CGFloat(x) * (buttonSize + margin),
                                      y: CGFloat(y) * (buttonSize + margin),
                                      width: buttonSize,
                                      height: buttonSize)
            }
        }
    }
}
