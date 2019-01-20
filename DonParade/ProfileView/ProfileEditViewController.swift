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
        resignFirstResponder()
        
        sendBasic()
        
        if let iconUrl = self.iconUrl {
            sendImage(type: "avatar", imageUrl: iconUrl)
        }
        
        if let headerUrl = self.headerUrl {
            sendImage(type: "header", imageUrl: headerUrl)
        }
    }
    
    // 画像以外の情報を送信
    private func sendBasic() {
        guard let view = self.view as? ProfileEditView else { return }
        let url = URL(string: "https://\(SettingsData.hostName!)/api/v1/accounts/update_credentials")!
        
        let display_name = DecodeToot.encodeEmoji(attributedText: view.nameField.attributedText, textStorage: view.nameField.textStorage)
        let note = DecodeToot.encodeEmoji(attributedText: view.noteView.attributedText, textStorage: view.noteView.textStorage)
        
        let body: [String: Any] = [
            "display_name": display_name,
            "note": note,
            "locked": view.lockedSwitch.isOn ? 1 : 0
        ]
        
        /*
        for (index, data) in view.addTitles.enumerated() {
            body.updateValue(data.text ?? "", forKey: "fields_attributes[\(index)][name]")
        }
        for (index, data) in view.addFields.enumerated() {
            let text = DecodeToot.encodeEmoji(attributedText: data.attributedText, textStorage: data.textStorage)
            body.updateValue(text, forKey: "fields_attributes[\(index)][value]")
        }
        */
        
        try? MastodonRequest.patch(url: url, body: body) { (data, response, error) in
            if let response = response as? HTTPURLResponse {
                if response.statusCode != 200 {
                    Dialog.show(message: I18n.get("PROFILE_UPDATE_FAILED"))
                } else {
                    DispatchQueue.main.async {
                        self.closeAction()
                    }
                }
            }
        }
    }
    
    // 画像を送信
    private func sendImage(type: String, imageUrl: URL) {
        let url = URL(string: "https://\(SettingsData.hostName!)/api/v1/accounts/update_credentials")!
        
        ImageUpload.upload(httpMethod: "PATCH", imageUrl: imageUrl, uploadUrl: url, filePathKey: type) { (infoDict) in
        }
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
        MyImagePickerController.show(useMovie: false, callback: { [weak self] url in
            if let url = url {
                let fetchResult: PHFetchResult = PHAsset.fetchAssets(withALAssetURLs: [url], options: nil)
                if let asset = fetchResult.firstObject {
                    // iOS10以前
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
                        self?.addPNGImage(imageUrl: url, asset: asset, isIcon: isIcon)
                    } else {
                        self?.addNormalImage(imageUrl: url, asset: asset, isIcon: isIcon)
                    }
                } else {
                    guard let data = try? Data(contentsOf: url) else { return }
                    
                    let gifImage = UIImage(gifData: data)
                    if let imageCount = gifImage.imageCount, imageCount >= 2 {
                        self?.addImage(imageUrl: url, image: gifImage, isIcon: isIcon)
                    } else if let image = UIImage(contentsOfFile: url.path) {
                        self?.addImage(imageUrl: url, image: image, isIcon: isIcon)
                    }
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
        manager.requestImageData(for: asset, options: options) { [weak self] (data, string, orientation, infoDict) in
            guard let data = data else { return }
            
            let gifImage = UIImage(gifData: data)
            if let imageCount = gifImage.imageCount, imageCount >= 2 {
                self?.addImage(imageUrl: imageUrl, image: gifImage, isIcon: isIcon)
            } else {
                guard let image = UIImage(data: data) else { return }
                self?.addImage(imageUrl: imageUrl, image: image, isIcon: isIcon)
            }
        }
    }
    
    // 不透明な静止画
    private func addNormalImage(imageUrl: URL, asset: PHAsset, isIcon: Bool) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat // これを指定しないとプレビュー画像も呼ばれる
        manager.requestImage(for: asset, targetSize: CGSize(width: 500, height: 500), contentMode: .aspectFill, options: options) { [weak self] (image, info) in
            guard let image = image else { return }
            
            self?.addImage(imageUrl: imageUrl, image: image, isIcon: isIcon)
        }
    }
    
    private func addImage(imageUrl: URL, image: UIImage, isIcon: Bool) {
        guard let view = self.view as? ProfileEditView else { return }
        
        let imageView: UIImageView
        if imageUrl.absoluteString.lowercased().contains(".gif") {
            imageView = UIImageView(gifImage: image)
        } else {
            imageView = UIImageView(image: image)
        }
        imageView.contentMode = .scaleAspectFit
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
            self.removeFromParent()
            self.view.removeFromSuperview()
        })
    }
    
    // テキストビューの文字を絵文字にする
    func textViewDidChange(_ textView: UITextView) {
        if textView.inputView is EmojiKeyboard || textView.text.contains(" :") || (textView.returnKeyType == .done && textView.text.contains("\n")) {
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
