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
    private let heightSlider = HeightSlider()
    private let emojiScrollView = EmojiInputScrollView()
    
    var intrinsicHeight: CGFloat = SettingsData.emojiKeyboardHeight {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: self.intrinsicHeight)
    }
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: SettingsData.emojiKeyboardHeight))
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(spaceButton)
        self.addSubview(returnButton)
        self.addSubview(deleteButton)
        self.addSubview(searchButton)
        self.addSubview(heightSlider)
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
        
        heightSlider.text = "≡"
        heightSlider.font = UIFont.systemFont(ofSize: 35)
        heightSlider.textColor = ThemeColor.mainButtonsTitleColor
        heightSlider.textAlignment = .center
        heightSlider.isUserInteractionEnabled = true
    }
    
    @objc func spaceAction() {
        guard let textView = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag) else { return }
        let textView2 = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag2)
        
        var spaceStr = " "
        let list = EmojiData.getEmojiCache(host: SettingsData.hostName!, showHiddenEmoji: false)
        for emoji in list.0 {
            if emoji.short_code == "space" {
                spaceStr = "\u{200b}:space:\u{200b}"
                break
            } else if emoji.short_code == "blank" {
                spaceStr = "\u{200b}:blank:\u{200b}"
                break
            }
        }
        
        if textView2?.isFirstResponder == true {
            (textView2 as? UITextView)?.insertText(spaceStr)
            return
        }
        
        (textView as? UITextView)?.insertText(spaceStr)
        (textView as? UITextField)?.insertText(spaceStr)
    }
    
    @objc func returnAction() {
        guard let textView = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag) else { return }
        let textView2 = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag2)
        
        if textView2?.isFirstResponder == true {
            (textView2 as? UITextView)?.insertText("\n")
            return
        }
        (textView as? UITextView)?.insertText("\n")
        (textView as? UITextField)?.insertText("\n")
    }
    
    @objc func deleteAction() {
        guard let textView = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag) else { return }
        let textView2 = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag2) as? UITextView
        
        if textView2?.isFirstResponder == true, let textView2 = textView2 {
            if EmojiKeyboard.getCarretBeforeChar(textView: textView2) == "\u{200b}" {
                textView2.deleteBackward()
            }
            textView2.deleteBackward()
            return
        }
        
        if let textView = textView as? UITextView {
            if EmojiKeyboard.getCarretBeforeChar(textView: textView) == "\u{200b}" {
                textView.deleteBackward()
            }
            textView.deleteBackward()
        } else if let textField = textView as? UITextField {
            textField.deleteBackward()
        }
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
    
    // キャレット直前の文字を返す
    static func getCarretBeforeChar(textView: UITextView) -> Character? {
        guard let currentRange = textView.selectedTextRange else {
            return nil
        }
        
        let currentPosition = currentRange.start
        guard let leftRange = textView.textRange(from: textView.beginningOfDocument, to: currentPosition), let leftText = textView.text(in: leftRange) else {
            return nil
        }
        
        return leftText.last
    }
 
    override func layoutSubviews() {
        self.spaceButton.frame = CGRect(x: 10,
                                        y: 1,
                                        width: 70,
                                        height: 40)
        
        self.returnButton.frame = CGRect(x: 85,
                                         y: 1,
                                         width: 70,
                                         height: 40)
        
        self.deleteButton.frame = CGRect(x: 160,
                                         y: 1,
                                         width: 70,
                                         height: 40)
        
        self.searchButton.frame = CGRect(x: 235,
                                         y: 1,
                                         width: 40,
                                         height: 40)
        
        self.heightSlider.frame = CGRect(x: self.frame.width - 35,
                                         y: 1,
                                         width: 35,
                                         height: 40)
        
        self.emojiScrollView.frame = CGRect(x: 0,
                                            y: 44,
                                            width: self.frame.width,
                                            height: self.frame.height - 44)
    }
}

private final class EmojiInputScrollView: UIScrollView {
    private var (emojiList, categoryList) = EmojiInputScrollView.getEmojiData()
    private var recentEmojiButtons: [EmojiButton] = []
    private var emojiButtons: [EmojiButton] = []
    private var hiddenEmojiButtons: [EmojiButton] = []
    var searchText: String?
    private var separatorViews: [UILabel] = [UILabel()]
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        
        if self.emojiList.count > 0 {
            addEmojis()
        } else {
            // 絵文字データが取れるまでリトライする
            func retry(count: Int) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    (self.emojiList, self.categoryList) = EmojiInputScrollView.getEmojiData()
                    if self.emojiList.count > 0 {
                        self.addEmojis()
                        self.setNeedsLayout()
                    } else if count <= 5 {
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
    
    private static func getEmojiData() -> ([EmojiData.EmojiStruct], [String]?) {
        let data = EmojiData.getEmojiCache(host: SettingsData.hostName!, showHiddenEmoji: true)
        
        let list = data.0.sorted(by: EmojiInputScrollView.sortFunc)
        
        return (list, data.1)
    }
    
    private static func sortFunc(e1: EmojiData.EmojiStruct, e2: EmojiData.EmojiStruct) -> Bool {
        let str1 = (e1.category ?? "") + (e1.short_code?.lowercased() ?? "")
        let str2 = (e2.category ?? "") + (e2.short_code?.lowercased() ?? "")
        return (str1 < str2)
    }
    
    private func addEmojis() {
        var recentList: [EmojiData.EmojiStruct] = []
        for key in SettingsData.recentEmojiList {
            for emojiData in self.emojiList {
                if key == emojiData.short_code {
                    recentList.append(emojiData)
                    break
                }
            }
        }
        
        let list = recentList + self.emojiList
        
        // 絵文字ボタンの追加
        for (index, emoji) in list.enumerated() {
            let button = EmojiButton(key: emoji.short_code ?? "", category: emoji.category)
            
            // 静的イメージ
            ImageCache.image(urlStr: emoji.url, isTemp: false, isSmall: true, shortcode: emoji.short_code) { image in
                if button.viewWithTag(5555) == nil {
                    button.setImage(image, for: .normal)
                    button.imageView?.contentMode = .scaleAspectFit
                    button.contentHorizontalAlignment = .fill
                    button.contentVerticalAlignment = .fill
                }
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
                        imageView.tag = 5555
                        imageView.autoStartAnimation = true
                        let buttonSize: CGFloat = 24 + SettingsData.fontSize
                        imageView.frame = CGRect(x: 0,
                                                 y: 0,
                                                 width: buttonSize,
                                                 height: buttonSize)
                        button.addSubview(imageView)
                        button.setImage(nil, for: .normal)
                    }
                }
            }
            button.addTarget(self, action: #selector(tapButton(_:)), for: .touchUpInside)
            
            let pressGesture = UILongPressGestureRecognizer(target: self, action: #selector(pressButton(_:)))
            button.addGestureRecognizer(pressGesture)
            
            self.addSubview(button)
            
            if index < recentList.count {
                recentEmojiButtons.append(button)
            } else if emoji.visible_in_picker == 1 {
                emojiButtons.append(button)
            } else {
                hiddenEmojiButtons.append(button)
            }
        }
        
        // カテゴリラベルをカテゴリの数+1用意する
        for (index, category) in (self.categoryList ?? []).enumerated() {
            if self.separatorViews.count < index + 2 {
                self.separatorViews.append(UILabel())
            }
            
            let label = self.separatorViews[index + 1]
            label.text = category
        }
        
        // カテゴリラベルをビューに貼る
        for separatorView in self.separatorViews {
            if separatorView.superview != nil { continue }
            self.addSubview(separatorView)
            separatorView.backgroundColor = UIColor.gray.withAlphaComponent(0.4)
        }
    }
    
    // テキスト入力欄にテキストを追加
    @objc func tapButton(_ button: UIButton) {
        guard let button = button as? EmojiButton else { return }
        
        guard let textView = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag) else { return }
        let textView2 = UIUtils.getFrontViewController()?.view.viewWithTag(UIUtils.responderTag2)
        
        var emojis: [[String: Any]] = []
        
        for emoji in EmojiData.getEmojiCache(host: SettingsData.hostName ?? "", showHiddenEmoji: true).0 {
            let dict: [String: Any] = ["shortcode": emoji.short_code ?? "",
                                       "url": emoji.url ?? ""]
            emojis.append(dict)
        }
        
        if textView2?.isFirstResponder == true {
            if let textView2 = textView2 as? UITextView {
                let prefixStr: String
                if EmojiKeyboard.getCarretBeforeChar(textView: textView2) == "\u{200b}" {
                    prefixStr = ""
                } else {
                    prefixStr = "\u{200b}"
                }
                textView2.insertText("\(prefixStr):" + button.key + ":\u{200b}") // U+200bはゼロ幅のスペース
                
                // ダークモードでテキストが黒に戻ってしまう問題対策として、もう一度フォントを設定
                textView2.textColor = ThemeColor.messageColor
                textView2.font = UIFont.systemFont(ofSize: SettingsData.fontSize + 5)
            }
            return
        }
        
        if let textView = textView as? UITextView {
            let prefixStr: String
            if EmojiKeyboard.getCarretBeforeChar(textView: textView) == "\u{200b}" {
                prefixStr = ""
            } else {
                prefixStr = "\u{200b}"
            }
            textView.insertText("\(prefixStr):" + button.key + ":\u{200b}") // U+200bはゼロ幅のスペース
            
            // ダークモードでテキストが黒に戻ってしまう問題対策として、もう一度フォントを設定
            textView.textColor = ThemeColor.messageColor
            textView.font = UIFont.systemFont(ofSize: SettingsData.fontSize + 5)
        } else if let textField = textView as? UITextField {
            textField.insertText("\u{200b}:" + button.key + ":\u{200b}") // U+200bはゼロ幅のスペース
            textField.delegate?.textField?(textField, shouldChangeCharactersIn: NSRange(), replacementString: "") // 強制更新
        }
        
        addRecent(key: button.key)
    }
    
    // 絵文字情報を表示
    @objc func pressButton(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began, let button = gesture.view as? EmojiButton {
            Dialog.show(message: button.key)
        }
    }
    
    private final class EmojiButton: UIButton {
        let category: String?
        let key: String
        
        init(key: String, category: String?) {
            self.key = key
            self.category = category
            
            super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    override func layoutSubviews() {
        if let searchText = self.searchText, searchText != "" {
            let filteredEmojiButtons = getFilteredEmojiButtons(key: searchText)
            
            layoutEmojiButtons(recentEmojiButtons: nil, emojiButtons: filteredEmojiButtons)
            return
        }

        if self.categoryList == nil || self.categoryList!.count == 0 {
            layoutEmojiButtons(recentEmojiButtons: self.recentEmojiButtons, emojiButtons: self.emojiButtons)
        } else {
            layoutCategoryEmojiButtons(recentEmojiButtons: self.recentEmojiButtons, emojiButtons: self.emojiButtons)
        }
        
        for button in self.hiddenEmojiButtons {
            button.frame.origin.x = -100
        }
    }
    
    private func layoutEmojiButtons(recentEmojiButtons: [UIButton]?, emojiButtons: [UIButton]) {
        let buttonSize: CGFloat = 22 + SettingsData.fontSize
        let margin: CGFloat = 2
        let screenBounds = UIScreen.main.bounds
        let xCount = floor(screenBounds.width / (buttonSize + margin)) // ボタンの横に並ぶ数
        let yCount = ceil(CGFloat(recentEmojiButtons?.count ?? 0) / xCount) + ceil(CGFloat(emojiButtons.count) / xCount) // ボタンの縦に並ぶ数
        let recentYCount = ceil(CGFloat(recentEmojiButtons?.count ?? 0) / xCount)
        let offset: CGFloat = (recentEmojiButtons != nil) ? 12 : 0
        let viewHeight = (buttonSize + margin) * yCount + offset
        
        self.contentSize = CGSize(width: screenBounds.width, height: viewHeight)
        
        for separatorView in self.separatorViews {
            separatorView.frame = CGRect(x: 0,
                                         y: -100,
                                         width: 0,
                                         height: 0)
        }
        
        // 最近使った絵文字
        if let recentEmojiButtons = recentEmojiButtons, recentYCount > 0 {
            for y in 0..<Int(recentYCount) {
                for x in 0..<Int(xCount) {
                    let index = y * Int(xCount) + x
                    if index >= recentEmojiButtons.count { break }
                    let button = recentEmojiButtons[index]
                    button.frame = CGRect(x: CGFloat(x) * (buttonSize + margin),
                                          y: CGFloat(y) * (buttonSize + margin),
                                          width: buttonSize,
                                          height: buttonSize)
                }
            }
            
            self.separatorViews[0].frame = CGRect(x: 0,
                                                  y: recentYCount * (buttonSize + margin) + 2,
                                                  width: screenBounds.width,
                                                  height: 8)
        } else {
            self.separatorViews[0].frame = CGRect(x: 0,
                                                  y: -100,
                                                  width: 0,
                                                  height: 0)
        }
        
        // 通常の絵文字
        for y in 0..<Int(yCount) {
            for x in 0..<Int(xCount) {
                let index = y * Int(xCount) + x
                if index >= emojiButtons.count { break }
                let button = emojiButtons[index]
                button.frame = CGRect(x: CGFloat(x) * (buttonSize + margin),
                                      y: (CGFloat(y) + CGFloat(recentYCount)) * (buttonSize + margin) + offset,
                                      width: buttonSize,
                                      height: buttonSize)
            }
        }
    }
    
    private func layoutCategoryEmojiButtons(recentEmojiButtons: [UIButton]?, emojiButtons: [EmojiButton]) {
        let buttonSize: CGFloat = 22 + SettingsData.fontSize
        let margin: CGFloat = 2
        let screenBounds = UIScreen.main.bounds
        let xCount = floor(screenBounds.width / (buttonSize + margin)) // ボタンの横に並ぶ数
        let recentYCount = ceil(CGFloat(recentEmojiButtons?.count ?? 0) / xCount)
        var y: CGFloat = recentYCount * buttonSize
        
        // 最近使った絵文字
        if let recentEmojiButtons = recentEmojiButtons, recentYCount > 0 {
            for y in 0..<Int(recentYCount) {
                for x in 0..<Int(xCount) {
                    let index = y * Int(xCount) + x
                    if index >= recentEmojiButtons.count { break }
                    let button = recentEmojiButtons[index]
                    button.frame = CGRect(x: CGFloat(x) * (buttonSize + margin),
                                          y: CGFloat(y) * (buttonSize + margin),
                                          width: buttonSize,
                                          height: buttonSize)
                }
            }
        }

        self.separatorViews[0].frame = CGRect(x: 0,
                                              y: -100,
                                              width: 0,
                                              height: 0)

        // 一旦絵文字ボタンをすべて隠す
        for button in emojiButtons {
            button.frame = CGRect(x: -100,
                                  y: -100,
                                  width: 0,
                                  height: 0)
        }
        
        // カテゴリー絵文字
        for (index, category) in (self.categoryList ?? []).enumerated() {
            // カテゴリ表示ラベル
            self.separatorViews[index + 1].frame = CGRect(x: 0,
                                                          y: y + 1,
                                                          width: screenBounds.width,
                                                          height: 16)
            y += 18
            
            // 絵文字ボタン
            var x: CGFloat = 0
            for button in emojiButtons {
                if button.category != category { continue }
                if x >= CGFloat(xCount) * (buttonSize + margin) - 0.1 {
                    x = 0
                    y += buttonSize + margin
                }
                button.frame = CGRect(x: x,
                                      y: y,
                                      width: buttonSize,
                                      height: buttonSize)
                
                x += buttonSize + margin
            }
            y += buttonSize + margin
        }
        
        self.contentSize = CGSize(width: screenBounds.width, height: y)
    }
    
    private func getFilteredEmojiButtons(key: String) -> [UIButton] {
        var buttons: [UIButton] = []
        
        if key == "隠し" {
            for button in self.hiddenEmojiButtons {
                buttons.append(button)
            }
            for button in self.recentEmojiButtons {
                button.frame.origin.x = -100
            }
            for button in self.emojiButtons {
                button.frame.origin.x = -100
            }
            return buttons
        }
        
        for button in self.emojiButtons {
            if button.key.lowercased().contains(key.lowercased()) {
                buttons.append(button)
            } else {
                button.frame.origin.x = -100
            }
        }
        for button in self.recentEmojiButtons {
            button.frame.origin.x = -100
        }
        for button in self.hiddenEmojiButtons {
            button.frame.origin.x = -100
        }
        
        return buttons
    }
    
    // 最近使った絵文字に追加
    private func addRecent(key: String) {
        SettingsData.addRecentEmoji(key: key)
    }
}

private final class HeightSlider: UILabel {
    private var lastPoint: CGFloat = -1
    private weak var touch: UITouch? = nil
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.touch == nil, let touch = touches.first {
            self.touch = touch
            self.lastPoint = touch.location(in: nil).y
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = self.touch {
            let diff = touch.location(in: nil).y - self.lastPoint
            
            if let keyboard = self.superview as? EmojiKeyboard {
                let height = max(200, min(UIScreen.main.bounds.height - 150, keyboard.frame.size.height - diff))
                keyboard.frame.size.height = height
                keyboard.intrinsicHeight = height
                SettingsData.emojiKeyboardHeight = height
                keyboard.setNeedsLayout()
            }
            
            self.lastPoint = touch.location(in: nil).y
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 何もしない
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}
