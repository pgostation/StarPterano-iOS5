//
//  ProfileEditViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/10/11.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// プロフィール編集画面

import UIKit
import Photos

final class ProfileEditViewController: MyViewController, UITextViewDelegate {
    private let accountData: AnalyzeJson.AccountData
    private var iconUrl: URL? = nil
    private var headerUrl: URL? = nil
    
    init(accountData: AnalyzeJson.AccountData) {
        self.accountData = accountData
        
        super.init(nibName: nil, bundle: nil)
        
        self.modalPresentationStyle = .overCurrentContext
        
        _ = EmojiData.getEmojiCache(host: SettingsData.hostName!, showHiddenEmoji: true)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = ProfileEditView(accountData: accountData)
        self.view = view
        
        // メッセージフィールドのデリゲートを設定
        view.nameField.delegate = self
        view.noteView.delegate = self
        for field in view.addFields {
            field.delegate = self
        }
        
        // ボタン
        view.closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        view.saveButton.addTarget(self, action: #selector(sendAction), for: .touchUpInside)
        view.iconButton.addTarget(self, action: #selector(iconAction), for: .touchUpInside)
        view.headerButton.addTarget(self, action: #selector(headerAction), for: .touchUpInside)
        view.emojiButton.addTarget(self, action: #selector(emojiAction), for: .touchUpInside)
        
        // 関係ないとこタップしたキーボード隠す
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        view.addGestureRecognizer(tapGesture)
        
        // アニメーション
        self.view.frame = CGRect(x: UIScreen.main.bounds.width,
                                 y: 0,
                                 width: UIScreen.main.bounds.width,
                                 height: UIScreen.main.bounds.height)
        UIView.animate(withDuration: 0.3) {
            self.view.frame = CGRect(x: 0,
                                     y: 0,
                                     width: UIScreen.main.bounds.width,
                                     height: UIScreen.main.bounds.height)
        }
    }
    
    // 送信ボタンの処理
    @objc func sendAction() {
        
    }
    
    // アイコン画像選択ボタンの処理
    @objc func iconAction() {
        selectImage(isIcon: true)
    }
    
    // ヘッダ画像選択ボタンの処理
    @objc func headerAction() {
        selectImage(isIcon: false)
    }
    
    private func selectImage(isIcon: Bool) {
        // 画像ピッカーを表示
        MyImagePickerController.show(useMovie: false, callback: { url in
            if let url = url {
                let fetchResult: PHFetchResult = PHAsset.fetchAssets(withALAssetURLs: [url], options: nil)
                guard let asset = fetchResult.firstObject else { return }
                
                var isGIForPNG = false
                let resources = PHAssetResource.assetResources(for: asset)
                for resource in resources {
                    if resource.uniformTypeIdentifier == "com.compuserve.gif" {
                        isGIForPNG = true
                    }
                    if resource.uniformTypeIdentifier == "public.png" {
                        isGIForPNG = true
                    }
                }
                
                if isGIForPNG {
                    self.addPNGImage(imageUrl: url, asset: asset, isIcon: isIcon)
                } else {
                    self.addNormalImage(imageUrl: url, asset: asset, isIcon: isIcon)
                }
            }
        })
    }
    
    // GIFかPNGの場合
    private func addPNGImage(imageUrl: URL, asset: PHAsset, isIcon: Bool) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat // これを指定しないとプレビュー画像も呼ばれる
        options.version = .original
        manager.requestImageData(for: asset, options: options) { (data, string, orientation, infoDict) in
            guard let data = data else { return }
            guard let view = self.view as? ProfileEditView else { return }
            
            let imageView: UIImageView
            if imageUrl.absoluteString.lowercased().contains(".gif") {
                let image = UIImage(gifData: data)
                imageView = UIImageView(gifImage: image)
                imageView.contentMode = .scaleAspectFit
            } else {
                let image = UIImage(data: data)
                imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFit
            }
            
            if isIcon {
                self.iconUrl = imageUrl
                view.iconView?.removeFromSuperview()
                view.iconView = imageView
                view.insertSubview(imageView, at: 1)
                view.setNeedsLayout()
            } else {
                self.headerUrl = imageUrl
                view.headerView?.removeFromSuperview()
                view.headerView = imageView
                view.insertSubview(imageView, at: 0)
                view.setNeedsLayout()
            }
        }
    }
    
    // 不透明な静止画
    private func addNormalImage(imageUrl: URL, asset: PHAsset, isIcon: Bool) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat // これを指定しないとプレビュー画像も呼ばれる
        manager.requestImage(for: asset, targetSize: CGSize(width: 500, height: 500), contentMode: .aspectFill, options: options) { (image, info) in
            guard let image = image else { return }
            guard let view = self.view as? ProfileEditView else { return }
            
            let imageView = UIImageView()
            imageView.image = image
            imageView.contentMode = .scaleAspectFit
            
            if isIcon {
                self.iconUrl = imageUrl
                view.iconView?.removeFromSuperview()
                view.iconView = imageView
                view.insertSubview(imageView, at: 1)
                view.setNeedsLayout()
            } else {
                self.headerUrl = imageUrl
                view.headerView?.removeFromSuperview()
                view.headerView = imageView
                view.insertSubview(imageView, at: 0)
                view.setNeedsLayout()
            }
        }
    }
    
    // 絵文字ボタンの処理
    @objc func emojiAction() {
        guard let view = self.view as? ProfileEditView else { return }
        
        if view.nameField.inputView is EmojiKeyboard {
            // テキストフィールドのカスタムキーボードを解除
            view.nameField.inputView = nil
            view.noteView.inputView = nil
            for field in view.addFields {
                field.inputView = nil
            }
            
            view.emojiButton.setTitle("😀", for: .normal)
        } else {
            let emojiView = EmojiKeyboard()
            
            // テキストフィールドのカスタムキーボードを変更
            view.nameField.inputView = emojiView
            view.noteView.inputView = emojiView
            for field in view.addFields {
                field.inputView = emojiView
            }
            
            view.emojiButton.setTitle("🔠", for: .normal)
        }
        
        var firstResponder: UITextView? = nil
        if view.nameField.isFirstResponder {
            firstResponder = view.nameField
        } else if view.noteView.isFirstResponder {
            firstResponder = view.noteView
        } else {
            for field in view.addFields {
                if field.isFirstResponder {
                    firstResponder = field
                }
            }
        }
        firstResponder?.resignFirstResponder()
        firstResponder?.becomeFirstResponder()
    }
    
    // キーボードを隠す
    @objc func tapAction() {
        guard let view = self.view as? ProfileEditView else { return }
        
        var firstResponder: UIView? = nil
        if view.nameField.isFirstResponder {
            firstResponder = view.nameField
        } else if view.noteView.isFirstResponder {
            firstResponder = view.noteView
        } else {
            for field in view.addTitles {
                if field.isFirstResponder {
                    firstResponder = field
                }
            }
            for field in view.addFields {
                if field.isFirstResponder {
                    firstResponder = field
                }
            }
        }
        
        firstResponder?.resignFirstResponder()
    }
    
    // 閉じる処理
    @objc func closeAction() {
        UIView.animate(withDuration: 0.3, animations: {
            self.view.frame = CGRect(x: UIScreen.main.bounds.width,
                                     y: 0,
                                     width: UIScreen.main.bounds.width,
                                     height: UIScreen.main.bounds.height)
        }, completion: { _ in
            self.removeFromParentViewController()
            self.view.removeFromSuperview()
        })
    }
    
    // テキストビューの文字を絵文字にする
    func textViewDidChange(_ textView: UITextView) {
        if textView.inputView is EmojiKeyboard || textView.text.contains(":") || textView.text.contains("\n") {
            var emojis: [[String: Any]] = []
            
            for emoji in EmojiData.getEmojiCache(host: SettingsData.hostName ?? "", showHiddenEmoji: true) {
                let dict: [String: Any] = ["shortcode": emoji.short_code ?? "",
                                           "url": emoji.url ?? ""]
                emojis.append(dict)
            }
            
            var encodedText = DecodeToot.encodeEmoji(attributedText: textView.attributedText, textStorage: textView.textStorage)
            if textView.returnKeyType == .done {
                encodedText = encodedText.replacingOccurrences(of: "\n", with: "")
            }
            textView.attributedText = DecodeToot.decodeName(name: encodedText, emojis: emojis, callback: {
                textView.attributedText = DecodeToot.decodeName(name: encodedText, emojis: emojis, callback: nil)
                textView.textColor = ThemeColor.messageColor
                textView.font = UIFont.systemFont(ofSize: SettingsData.fontSize + 3)
            })
            textView.textColor = ThemeColor.messageColor
            textView.font = UIFont.systemFont(ofSize: SettingsData.fontSize + 3)
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        guard let view = self.view as? ProfileEditView else { return }
        
        // 目的のTextViewにのみタグをつける
        view.nameField.tag = 0
        view.noteView.tag = 0
        for field in view.addFields {
            field.tag = 0
        }
        
        var firstResponder: UITextView? = nil
        if view.nameField.isFirstResponder {
            firstResponder = view.nameField
        } else if view.noteView.isFirstResponder {
            firstResponder = view.noteView
        } else {
            for field in view.addFields {
                if field.isFirstResponder {
                    firstResponder = field
                }
            }
        }
        firstResponder?.tag = UIUtils.responderTag
    }
}
