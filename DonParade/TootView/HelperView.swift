//
//  HelperView.swift
//  DonParade
//
//  Created by takayoshi on 2019/02/09.
//  Copyright © 2019 pgostation. All rights reserved.
//

// アカウントID、カスタム絵文字、ハッシュタグの補完表示

import UIKit
import APNGKit

final class HelperViewManager {
    private static weak var instance: HelperView?
    
    enum HelperMode: String {
        case none = ""
        case emoji = ":"
        case account = "@"
        case hashtag = "#"
    }
    
    static func show(mode: HelperMode, textView: UITextView, location: Int) {
        let view = HelperView(mode: mode, textView: textView, location: location)
        instance?.closeAction()
        instance = view
        
        if let tootView = TootViewController.instance?.view as? TootView {
            tootView.inputBar.addSubview(view)
        }
    }
    
    static func change() {
        instance?.setLabels()
    }
    
    static func close() {
        instance?.removeFromSuperview()
    }
}

private class HelperView: UIView {
    private let closeButton = UIButton()
    private let scrollView = UIScrollView()
    private var tapViews: [TapView] = []
    private let mode: HelperViewManager.HelperMode
    private weak var textView: UITextView?
    private let location: Int
    
    init(mode: HelperViewManager.HelperMode, textView: UITextView, location: Int) {
        self.mode = mode
        self.textView = textView
        self.location = location
        
        super.init(frame: CGRect(x: 0,
                                 y: 0,
                                 width: UIScreen.main.bounds.width,
                                 height: 40))
        
        self.addSubview(scrollView)
        self.scrollView.addSubview(closeButton)
        
        closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.backgroundColor = ThemeColor.viewBgColor
        
        closeButton.backgroundColor = ThemeColor.viewBgColor
        closeButton.setTitle("×", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 32)
        closeButton.setTitleColor(ThemeColor.buttonBorderColor, for: .normal)
        
        setLabels()
    }
    
    func setLabels() {
        guard let textView = self.textView else { return }
        guard let selectedTextRange = textView.selectedTextRange else { return }
        let caretPosition = textView.offset(from: textView.beginningOfDocument, to: selectedTextRange.start)
        
        guard let viewText = textView.text else { return }
        let tmpText = String(viewText.prefix(caretPosition))
        let text = String(tmpText.suffix(max(0, tmpText.count - self.location - 1))).lowercased()
        
        switch self.mode {
        case .none:
            break
        case .account:
            setAccountLabels(text: text)
        case .emoji:
            setEmojiLabels(text: text)
        case .hashtag:
            setHashtagLabels(text: text)
        }
    }
    
    // アカウントIDのラベルを追加
    private func setAccountLabels(text: String) {
        removeLabels()
        self.tapViews = []
        
        var tmpList: [String] = []
        var list: [String] = []
        
        // 最近使った宛先アカウント
        tmpList += SettingsData.recentMentionList
        
        // フォローしているアカウント
        tmpList += SettingsData.followingList(accessToken: SettingsData.accessToken ?? "")
        
        // まずは前方一致するアカウントをリストアップ
        for data in tmpList {
            if list.count >= 20 { break }
            
            if text == "" || data.hasPrefix(text) {
                if list.contains(data) { continue }
                list.append(data)
            }
        }
        
        // 一部でも一致するアカウントをリストアップ
        for data in tmpList {
            if list.count >= 20 { break }
            
            if data.contains(text) {
                if list.contains(data) { continue }
                list.append(data)
            }
        }
        
        // リストアップしたアカウントから、タップラベルを追加する
        for data in list {
            let tapView = TapView(text: "@" + data + " ", trueText: data, textView: textView, location: location)
            
            tapView.label.text = "@" + data
            tapView.label.font = UIFont.systemFont(ofSize: 16)
            tapView.label.textColor = ThemeColor.messageColor
            
            self.tapViews.append(tapView)
        }
        
        addLabels()
    }
    
    // カスタム絵文字のラベルを追加
    private func setEmojiLabels(text: String) {
        removeLabels()
        self.tapViews = []
        
        var emojiList = EmojiData.getEmojiCache(host: SettingsData.hostName ?? "", showHiddenEmoji: true)
        var list: [EmojiData.EmojiStruct] = []
        
        // 最近使った絵文字を前に持ってくる
        for key in SettingsData.recentEmojiList.reversed() {
            for (index, emoji) in emojiList.0.enumerated() {
                if emoji.short_code == key {
                    emojiList.0.remove(at: index)
                    emojiList.0.insert(emoji, at: 0)
                    break
                }
            }
        }
        
        // 一致する絵文字20件をリストアップ
        for emoji in emojiList.0 {
            if list.count >= 20 { break }
            
            if text == "" || (emoji.short_code?.lowercased() ?? "").contains(text) {
                list.append(emoji)
            }
        }
        
        // リストアップした絵文字から、タップラベルを追加する
        for emoji in list {
            let tapView = TapView(text: "\u{200b}:" + (emoji.short_code ?? "") + ":\u{200b}", trueText: (emoji.short_code ?? ""),  textView: textView, location: location)
            ImageCache.image(urlStr: emoji.url, isTemp: true, isSmall: true) { image in
                tapView.iconView.image = image
            }
            
            if SettingsData.useAnimation {
                let urlStr = emoji.url
                if !NormalPNGFileList.isNormal(urlStr: urlStr) {
                    APNGImageCache.image(urlStr: urlStr) { image in
                        if image.frameCount <= 1 {
                            NormalPNGFileList.add(urlStr: urlStr)
                            return
                        }
                        // APNGのビューを貼り付ける
                        let imageView = APNGImageView(image: image)
                        if image.frameCount > 1 {
                            imageView.autoStartAnimation = true
                        }
                        let buttonSize: CGFloat = 32
                        imageView.frame = CGRect(x: 0,
                                                 y: 4,
                                                 width: buttonSize,
                                                 height: buttonSize)
                        tapView.iconView.addSubview(imageView)
                        tapView.iconView.image = nil
                    }
                }
            }
            
            tapView.label.text = emoji.short_code
            tapView.label.font = UIFont.systemFont(ofSize: 16)
            tapView.label.textColor = ThemeColor.messageColor
            
            self.tapViews.append(tapView)
        }
        
        addLabels()
    }
    
    // ハッシュタグのラベルを追加
    private func setHashtagLabels(text: String) {
        removeLabels()
        self.tapViews = []
        
        var tmpList: [String] = []
        var list: [String] = []
        
        // 最近使ったハッシュタグ
        tmpList += SettingsData.recentHashtagList
        
        // 最近TLで見たハッシュタグ
        tmpList += HashtagCache.recentHashtagList
        
        // まずは前方一致するハッシュタグをリストアップ
        for data in tmpList {
            if list.count >= 20 { break }
            
            if text == "" || data.hasPrefix(text) {
                if list.contains(data) { continue }
                list.append(data)
            }
        }
        
        // 一部でも一致するハッシュタグをリストアップ
        for data in tmpList {
            if list.count >= 20 { break }
            
            if data.contains(text) {
                if list.contains(data) { continue }
                list.append(data)
            }
        }
        
        // リストアップしたハッシュタグから、タップラベルを追加する
        for data in list {
            let tapView = TapView(text: "#" + data + " ", trueText: data, textView: textView, location: location)
            
            tapView.label.text = "#" + data
            tapView.label.font = UIFont.systemFont(ofSize: 16)
            tapView.label.textColor = ThemeColor.messageColor
            
            self.tapViews.append(tapView)
        }
        
        addLabels()
    }
    
    private func removeLabels() {
        for tapView in self.tapViews {
            tapView.removeFromSuperview()
        }
    }
    
    private func addLabels() {
        for tapView in self.tapViews {
            self.scrollView.addSubview(tapView)
        }
        
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        self.scrollView.frame = CGRect(x: 0,
                                       y: 0,
                                       width: UIScreen.main.bounds.width,
                                       height: 40)
        
        self.closeButton.frame = CGRect(x: 0,
                                        y: 2,
                                        width: 36,
                                        height: 36)

        var left = self.closeButton.frame.maxX + 5
        
        for tapView in self.tapViews {
            if tapView.label.text?.hasPrefix("@") == true || tapView.label.text?.hasPrefix("#") == true {
                tapView.label.sizeToFit()
                tapView.label.frame = CGRect(x: 0, y: 4, width: tapView.label.frame.width, height: 32)
            } else {
                tapView.iconView.frame = CGRect(x: 0, y: 4, width: 32, height: 32)
                
                tapView.label.sizeToFit()
                tapView.label.frame = CGRect(x: 32, y: 4, width: tapView.label.frame.width, height: 32)
            }
            
            tapView.frame = CGRect(x: left, y: 0, width: tapView.label.frame.maxX, height: 40)
            
            left = tapView.frame.maxX + 5
        }
        
        self.scrollView.contentSize = CGSize(width: left, height: 40)
    }
    
    @objc func closeAction() {
        self.removeFromSuperview()
    }
}

private class TapView: UIButton {
    let iconView = UIImageView()
    let label = UILabel()
    private let text: String
    private let trueText: String
    private weak var textView: UITextView?
    private let location: Int
    
    init(text: String, trueText: String, textView: UITextView?, location: Int) {
        self.text = text
        self.trueText = trueText
        self.textView = textView
        self.location = location
        
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        
        self.addSubview(iconView)
        self.addSubview(label)
        
        self.addTarget(self, action: #selector(tapAction), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tapAction() {
        guard let textView = self.textView else { return }
        guard let selectedTextRange = textView.selectedTextRange else { return }
        let caretPosition = textView.offset(from: textView.beginningOfDocument, to: selectedTextRange.start)
        
        // この方法では入力済みの絵文字が消えてしまう
        //guard let viewText = textView.text else { return }
        // textView.text = viewText.prefix(location) + self.text + viewText.suffix(viewText.count - caretPosition)
        
        for _ in 0..<max(0, caretPosition - location) {
            textView.deleteBackward()
        }
        textView.insertText(self.text)
        
        if self.text.prefix(1) == "\u{200b}" {
            SettingsData.addRecentEmoji(key: trueText)
        }
        else if self.text.prefix(1) == "#" {
            SettingsData.addRecentHashtag(key: trueText)
        }
        else if self.text.prefix(1) == "@" {
            SettingsData.addRecentMention(key: trueText)
        }
        
        (self.superview?.superview as? HelperView)?.closeAction()
    }
}
