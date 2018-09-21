//
//  TootView.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/21.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit

final class TootView: UIView {
    private var keyBoardHeight: CGFloat = 0
    var protectMode = SettingsData.protectMode
    
    // 閉じるボタン
    let closeButton = UIButton()
    
    // トゥート
    let textField = UITextView()
    let tootButton = UIButton()
    
    // 入力バー
    let inputBar = UIView()
    let imagesButton = UIButton()
    let imagesCountButton = UIButton()
    let protectButton = UIButton()
    let cwButton = UIButton()
    //let saveButton = UIButton()
    let emojiButton = UIButton()
    //let idButton = UIButton()
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        
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
        
        self.backgroundColor = UIColor.clear
        self.isOpaque = false
        
        self.addSubview(closeButton)
        self.addSubview(tootButton)
        
        self.addSubview(textField)
        
        self.addSubview(inputBar)
        inputBar.addSubview(imagesButton)
        inputBar.addSubview(imagesCountButton)
        inputBar.addSubview(protectButton)
        inputBar.addSubview(cwButton)
        //inputBar.addSubview(saveButton)
        inputBar.addSubview(emojiButton)
        //inputBar.addSubview(idButton)
        
        refresh()
        
        self.layoutSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    func refresh() {
        closeButton.setTitle(I18n.get("BUTTON_CLOSE"), for: .normal)
        closeButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
        closeButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        closeButton.clipsToBounds = true
        closeButton.layer.cornerRadius = 12
        
        tootButton.setTitle(I18n.get("BUTTON_TOOT"), for: .normal)
        tootButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
        tootButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        tootButton.clipsToBounds = true
        tootButton.layer.cornerRadius = 12
        
        DispatchQueue.main.async {
            self.textField.becomeFirstResponder()
        }
        textField.backgroundColor = ThemeColor.cellBgColor.withAlphaComponent(0.9)
        textField.textColor = ThemeColor.messageColor
        textField.font = UIFont.systemFont(ofSize: SettingsData.fontSize + 3)
        textField.isEditable = true
        textField.layer.borderColor = ThemeColor.messageColor.cgColor
        textField.layer.borderWidth = 1 / UIScreen.main.scale
        
        inputBar.backgroundColor = ThemeColor.cellBgColor
        
        imagesButton.setTitle("🏞", for: .normal)
        
        imagesCountButton.setTitle(nil, for: .normal)
        imagesCountButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        
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
        
        //saveButton.setTitle("📄", for: .normal)
        
        emojiButton.setTitle("😀", for: .normal)
        
        //idButton.setTitle("@", for: .normal)
        //idButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
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
        
        textField.sizeToFit()
        textField.frame = CGRect(x: 1,
                                 y: 40,
                                 width: screenBounds.width - 2,
                                 height: max(20, textField.frame.height))
        
        inputBar.frame = CGRect(x: 0,
                                y: 40 + textField.frame.height,
                                width: screenBounds.width,
                                height: 40)
        
        let buttonWidthSum: CGFloat = 40 * 4 + (imagesCountButton.titleLabel?.text != nil ? 40 : 10)
        let margin: CGFloat = floor((screenBounds.width - buttonWidthSum) / 4)
        
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
        
        emojiButton.frame = CGRect(x: cwButton.frame.maxX + margin,
                                   y: 0,
                                   width: 40,
                                   height: 40)
        
        let viewHeight = 80 + textField.frame.height
        self.frame = CGRect(x: 0,
                            y: screenBounds.height - keyBoardHeight - viewHeight,
                            width: screenBounds.width,
                            height: viewHeight)
        
    }
}
