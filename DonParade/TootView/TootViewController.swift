//
//  TootViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/19.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit
import Photos

final class TootViewController: UIViewController, UITextViewDelegate {
    static var isShown = false // 現在表示中かどうか
    static weak var instance: TootViewController?
    static var inReplyToId: String? = nil
    static var imagesList: [URL] = []
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        TootViewController.instance = self
        TootViewController.isShown = true
        
        _ = EmojiData.getEmojiCache(host: SettingsData.hostName!)
    }
    
    deinit {
        TootViewController.isShown = false
        TootViewController.inReplyToId = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = TootView()
        self.view = view
        
        // メッセージフィールドのデリゲートを設定
        view.textField.delegate = self
        view.spoilerTextField.delegate = self
        
        // ボタン
        view.closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        view.tootButton.addTarget(self, action: #selector(tootAction), for: .touchUpInside)
        
        // 入力バー部分のボタン
        view.imagesButton.addTarget(self, action: #selector(addImageAction), for: .touchUpInside)
        view.imagesCountButton.addTarget(self, action: #selector(showImagesAction), for: .touchUpInside)
        view.protectButton.addTarget(self, action: #selector(protectAction), for: .touchUpInside)
        view.cwButton.addTarget(self, action: #selector(cwAction), for: .touchUpInside)
        //view.saveButton.addTarget(self, action: #selector(saveAction), for: .touchUpInside)
        view.emojiButton.addTarget(self, action: #selector(emojiAction), for: .touchUpInside)
    }
    
    // トゥートする
    @objc func tootAction() {
        guard let view = self.view as? TootView else { return }
        
        // 通常テキスト
        guard let attributedText = view.textField.attributedText else { return }
        if attributedText.length == 0 { return }
        
        let text = DecodeToot.encodeEmoji(attributedText: attributedText, textStorage: view.textField.textStorage)
        
        // 保護テキスト
        let spoilerText: String?
        if view.spoilerTextField.isHidden {
            spoilerText = nil
        } else {
            spoilerText = DecodeToot.encodeEmoji(attributedText: view.textField.attributedText, textStorage: view.spoilerTextField.textStorage)
        }
        
        // 公開範囲
        let visibility = view.protectMode.rawValue
        
        if TootViewController.imagesList.count > 0 {
            // 画像をアップロードしてから投稿
            let group = DispatchGroup()
            
            var idList: [String] = []
            for url in TootViewController.imagesList {
                group.enter()
                ImageUpload.upload(imageUrl: url, callback: { json in
                    if let json = json {
                        if let id = json["id"] as? String {
                            idList.append(id)
                        }
                        group.leave()
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            group.leave()
                        }
                    }
                })
            }
            TootViewController.imagesList = []
            
            // 画像を全てアップロードし終わったら投稿
            group.notify(queue: DispatchQueue.main) {
                let addJson: [String: Any] = ["media_ids": idList]
                self.toot(text: text, spoilerText: spoilerText, visibility: visibility, addJson: addJson)
            }
        } else {
            // テキストだけなのですぐに投稿
            toot(text: text, spoilerText: spoilerText, visibility: visibility, addJson: [:])
        }
        
        closeAction()
    }
    
    private func toot(text: String, spoilerText: String?, visibility: String, addJson: [String: Any]) {
        guard let hostName = SettingsData.hostName else { return }
        
        let url = URL(string: "https://\(hostName)/api/v1/statuses")!
        
        var bodyJson: [String: Any] = [
            "status": text,
            "visibility": visibility,
            ]
        if let spoilerText = spoilerText {
            bodyJson.updateValue(spoilerText, forKey: "spoiler_text")
        }
        if let inReplyToId = TootViewController.inReplyToId {
            bodyJson.updateValue(inReplyToId, forKey: "in_reply_to_id")
            TootViewController.inReplyToId = nil
        }
        for data in addJson {
            bodyJson.updateValue(data.value, forKey: data.key)
        }
        
        try? MastodonRequest.post(url: url, body: bodyJson) { (data, response, error) in
            if let error = error {
                Dialog.show(message: I18n.get("ALERT_SEND_TOOT_FAILURE") + "\n" + error.localizedDescription)
            }
        }
    }
    
    // 添付画像を追加する
    @objc func addImageAction() {
        PHPhotoLibrary.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                DispatchQueue.main.async {
                    // 画像ピッカーを表示
                    MyImagePickerController.show(callback: { url in
                        if let url = url {
                            TootViewController.imagesList.append(url)
                            if let view = self.view as? TootView {
                                view.refresh()
                            }
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            if let view = self.view as? TootView {
                                view.textField.becomeFirstResponder()
                            }
                        }
                    })
                }
            case .denied, .notDetermined, .restricted:
                DispatchQueue.main.async {
                    Dialog.show(message: "許可されていません")
                }
            }
        }
    }
    
    // 添付画像を確認、削除する
    @objc func showImagesAction() {
    }
    
    // 公開範囲を設定する
    @objc func protectAction() {
        SettingsSelectProtectMode.showActionSheet { (mode) in
            guard let view = self.view as? TootView else { return }
            
            view.protectMode = mode
            view.refresh()
        }
    }
    
    // センシティブなトゥートにする
    @objc func cwAction() {
        guard let view = self.view as? TootView else { return }
        
        view.spoilerTextField.isHidden = !view.spoilerTextField.isHidden
        view.setNeedsLayout()
        
        if view.spoilerTextField.isHidden {
            view.textField.becomeFirstResponder()
        } else {
            view.spoilerTextField.becomeFirstResponder()
        }
    }
    
    // 下書きにする / 下書きを復帰する
    @objc func saveAction() {
    }
    
    // カスタム絵文字を入力する
    @objc func emojiAction() {
        guard let view = self.view as? TootView else { return }
        
        if view.textField.inputView is EmojiKeyboard {
            // テキストフィールドのカスタムキーボードを解除
            view.textField.inputView = nil
            view.spoilerTextField.inputView = nil
            
            view.emojiButton.setTitle("😀", for: .normal)
        } else {
            let emojiView = EmojiKeyboard()
            
            // テキストフィールドのカスタムキーボードを変更
            view.textField.inputView = emojiView
            view.spoilerTextField.inputView = emojiView
            
            view.emojiButton.setTitle("🔠", for: .normal)
        }
        
        let firstResponder = view.spoilerTextField.isFirstResponder ? view.spoilerTextField : view.textField
        firstResponder.resignFirstResponder()
        firstResponder.becomeFirstResponder()
    }
    
    // 画面を閉じる
    @objc func closeAction() {
        self.view.removeFromSuperview()
        self.removeFromParentViewController()
        
        TootViewController.isShown = false
        TootViewController.inReplyToId = nil
    }
    
    // テキストビューの高さを変化させる
    func textViewDidChange(_ textView: UITextView) {
        if textView.inputView is EmojiKeyboard {
            var emojis: [[String: Any]] = []
            
            for emoji in EmojiData.getEmojiCache(host: SettingsData.hostName ?? "") {
                let dict: [String: Any] = ["shortcode": emoji.short_code ?? "",
                                           "static_url": emoji.static_url ?? ""]
                emojis.append(dict)
            }
            
            let encodedText = DecodeToot.encodeEmoji(attributedText: textView.attributedText, textStorage: textView.textStorage)
            textView.attributedText = DecodeToot.decodeName(name: encodedText, emojis: emojis, callback: nil)
            textView.textColor = ThemeColor.messageColor
            textView.font = UIFont.systemFont(ofSize: SettingsData.fontSize + 5)
        }
        
        // テキストを全削除するとin_reply_toをクリアする
        if textView.text == nil || textView.text!.count == 0 {
            TootViewController.inReplyToId = nil
        }
        
        DispatchQueue.main.async {
            self.view.setNeedsLayout()
        }
    }
}
