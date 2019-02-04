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
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        TootViewController.instance = self
        TootViewController.isShown = true
        
        _ = EmojiData.getEmojiCache(host: SettingsData.hostName!, showHiddenEmoji: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 通知ボタンの位置を上にずらす
            MainViewController.instance?.view.setNeedsLayout()
        }
    }
    
    deinit {
        TootViewController.isShown = false
        
        // 通知ボタンの位置を元に戻す
        MainViewController.instance?.view.setNeedsLayout()
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
        view.scheduledButton.addTarget(self, action: #selector(scheduleAction), for: .touchUpInside)
        view.emojiButton.addTarget(self, action: #selector(emojiAction), for: .touchUpInside)
        
        // 添付画像の復帰
        for url in view.imageCheckView.urls {
            view.imageCheckView.add(imageUrl: url)
        }
    }
    
    // トゥートする
    @objc func tootAction() {
        guard let view = self.view as? TootView else { return }
        
        // 通常テキスト
        guard let attributedText = view.textField.attributedText else { return }
        
        let text = DecodeToot.encodeEmoji(attributedText: attributedText, textStorage: NSTextStorage(attributedString: attributedText), isToot: true)
        
        // 保護テキスト
        let spoilerText: String?
        if view.spoilerTextField.isHidden {
            spoilerText = nil
        } else {
            spoilerText = DecodeToot.encodeEmoji(attributedText: view.spoilerTextField.attributedText, textStorage: NSTextStorage(attributedString: view.spoilerTextField.attributedText), isToot: true)
        }
        
        // 投稿するものがない
        if attributedText.length == 0 && spoilerText == nil && view.imageCheckView.urls.count == 0 { return }
        
        // 公開範囲
        let visibility = view.protectMode.rawValue
        let nsfw = (!view.spoilerTextField.isHidden) || view.imageCheckView.nsfwSw.isOn
        
        if view.imageCheckView.urls.count > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                // 画像をアップロードしてから投稿
                let group = DispatchGroup()
                
                var idList: [String] = []
                for url in view.imageCheckView.urls {
                    group.enter()
                    let lowUrlStr = url.absoluteString.lowercased()
                    if lowUrlStr.contains(".mp4") || lowUrlStr.contains(".m4v") || lowUrlStr.contains(".mov") {
                        // 動画
                        ImageUpload.upload(movieUrl: url, callback: { json in
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
                    } else {
                        // 静止画
                        ImageUpload.upload(httpMethod: "POST", imageUrl: url, count: view.imageCheckView.urls.count,  callback: { json in
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
                }
                
                // 画像を全てアップロードし終わったら投稿
                group.notify(queue: DispatchQueue.main) {
                    let addJson: [String: Any] = ["media_ids": idList]
                    self.toot(text: text, spoilerText: spoilerText, nsfw: nsfw, visibility: visibility, addJson: addJson)
                }
            }
        } else {
            // テキストだけなのですぐに投稿
            toot(text: text, spoilerText: spoilerText, nsfw: nsfw, visibility: visibility, addJson: [:])
        }
        
        closeAction()
    }
    
    private func toot(text: String, spoilerText: String?, nsfw: Bool, visibility: String, addJson: [String: Any]) {
        guard let hostName = SettingsData.hostName else { return }
        
        let url = URL(string: "https://\(hostName)/api/v1/statuses")!
        
        var bodyJson: [String: Any] = [
            "status": text,
            "visibility": visibility,
            ]
        if let spoilerText = spoilerText {
            bodyJson.updateValue(spoilerText, forKey: "spoiler_text")
        }
        if nsfw {
            bodyJson.updateValue(1, forKey: "sensitive")
        }
        if let inReplyToId = TootView.inReplyToId {
            bodyJson.updateValue(inReplyToId, forKey: "in_reply_to_id")
        }
        for data in addJson {
            bodyJson.updateValue(data.value, forKey: data.key)
        }
        if let scheduledDate = TootView.scheduledDate {
            let dateFormatter: DateFormatter = {
                let formatter = DateFormatter()
                let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
                formatter.locale = enUSPosixLocale
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
                return formatter
            }()
            let str = dateFormatter.string(from: scheduledDate)
            bodyJson.updateValue(str, forKey: "scheduled_at")
        }
        
        try? MastodonRequest.post(url: url, body: bodyJson) { (data, response, error) in
            if let error = error {
                Dialog.show(message: I18n.get("ALERT_SEND_TOOT_FAILURE") + "\n" + error.localizedDescription)
            } else {
                if let response = response as? HTTPURLResponse {
                    if response.statusCode == 200 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + (TootViewController.isShown ? 1 : 0) ) {
                            TootView.isTooted = true
                            TootView.savedText = nil
                            TootView.savedSpoilerText = nil
                            TootView.savedImages = []
                            TootView.inReplyToId = nil
                            TootView.scheduledDate = nil
                            if let view = self.view as? TootView {
                                view.tootButton.setTitle(I18n.get("BUTTON_TOOT"), for: .normal)
                            }
                        }
                    } else {
                        Dialog.show(message: I18n.get("ALERT_SEND_TOOT_FAILURE") + "\nHTTP status \(response.statusCode)")
                    }
                }
            }
        }
    }
    
    // 添付画像を追加する
    @objc func addImageAction() {
        guard let view = self.view as? TootView else { return }
        
        if view.imageCheckView.urls.count >= 4 {
            Dialog.show(message: I18n.get("ALERT_IMAGE_COUNT_MAX"))
            return
        }
        
        PHPhotoLibrary.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                DispatchQueue.main.async {
                    // 画像ピッカーを表示
                    MyImagePickerController.show(useMovie: true, callback: { url in
                        if let url = url {
                            view.imageCheckView.add(imageUrl: url)
                            for i in 1...3 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 * Double(i)) {
                                    view.refresh()
                                    view.setNeedsLayout()
                                }
                            }
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            view.textField.becomeFirstResponder()
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
        guard let view = self.view as? TootView else { return }
        
        view.imageCheckView.isHidden = false
        
        view.textField.resignFirstResponder()
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
    
    // スケジュール設定/解除/スケジュール投稿確認
    @objc func scheduleAction() {
        let rootVC = UIUtils.getFrontViewController()
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        // スケジュール設定
        alertController.addAction(UIAlertAction(
            title: I18n.get("ACTION_SET_SCHEDULE"),
            style: UIAlertAction.Style.default) { _ in
                SetScheduleViewController.show()
        })
        
        if TootView.scheduledDate != nil {
            // スケジュール解除
            alertController.addAction(UIAlertAction(
                title: I18n.get("ACTION_CLEAR_SCHEDULE"),
                style: UIAlertAction.Style.destructive) { _ in
                    TootView.scheduledDate = nil
                    if let view = self.view as? TootView {
                        view.tootButton.setTitle(I18n.get("BUTTON_TOOT"), for: .normal)
                    }
            })
        }
        
        // スケジュール投稿の確認
        alertController.addAction(UIAlertAction(
            title: I18n.get("ACTION_SHOW_SCHEDULE"),
            style: UIAlertAction.Style.default) { _ in
                if let view = self.view as? TootView {
                    view.textField.resignFirstResponder()
                    view.spoilerTextField.resignFirstResponder()
                }
                ShowMyAnyList.showScheduledList(rootVc: rootVC!)
        })
        
        // キャンセル
        alertController.addAction(UIAlertAction(
            title: I18n.get("BUTTON_CANCEL"),
            style: UIAlertAction.Style.cancel) { _ in
        })
        
        rootVC?.present(alertController, animated: true, completion: nil)
    }
    
    // カスタム絵文字キーボードを表示する
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
        self.removeFromParent()
        
        TootViewController.isShown = false
        
        // 通知ボタンの位置を元に戻す
        MainViewController.instance?.view.setNeedsLayout()
    }
    
    // テキストビューの高さを変化させる、絵文字にする
    func textViewDidChange(_ textView: UITextView) {
        if textView.inputView is EmojiKeyboard || textView.text.contains(" :"){
            var emojis: [[String: Any]] = []
            
            for emoji in EmojiData.getEmojiCache(host: SettingsData.hostName ?? "", showHiddenEmoji: true) {
                let dict: [String: Any] = ["shortcode": emoji.short_code ?? "",
                                           "url": emoji.url ?? ""]
                emojis.append(dict)
            }
            
            let encodedText = DecodeToot.encodeEmoji(attributedText: textView.attributedText, textStorage: textView.textStorage)
            if let textField = (self.view as? TootView)?.textField, textField.isFirstResponder {
                textField.attributedText = DecodeToot.decodeName(name: encodedText, emojis: emojis, callback: {
                    textField.attributedText = DecodeToot.decodeName(name: encodedText, emojis: emojis, callback: nil)
                    textField.textColor = ThemeColor.messageColor
                    textField.font = UIFont.systemFont(ofSize: SettingsData.fontSize + 5)
                })
            }
            else if let spoilerTextField = (self.view as? TootView)?.spoilerTextField, spoilerTextField.isFirstResponder {
                spoilerTextField.attributedText = DecodeToot.decodeName(name: encodedText, emojis: emojis, callback: {
                    spoilerTextField.attributedText = DecodeToot.decodeName(name: encodedText, emojis: emojis, callback: nil)
                    spoilerTextField.textColor = ThemeColor.messageColor
                    spoilerTextField.font = UIFont.systemFont(ofSize: SettingsData.fontSize + 5)
                })
            }
            textView.textColor = ThemeColor.messageColor
            textView.font = UIFont.systemFont(ofSize: SettingsData.fontSize + 5)
        }
        
        // テキストを全削除するとin_reply_toをクリアする
        if textView.text == nil || textView.text!.count == 0 {
            TootView.inReplyToId = nil
        }
        
        do {
            let text: String
            if let textField = (self.view as? TootView)?.textField, textField.isFirstResponder {
                text = DecodeToot.encodeEmoji(attributedText: textField.attributedText, textStorage: NSTextStorage(attributedString: textField.attributedText))
            } else {
                text = ""
            }
            
            let spoilerText: String
            if let spoilerTextField = (self.view as? TootView)?.spoilerTextField, spoilerTextField.isFirstResponder {
                spoilerText = DecodeToot.encodeEmoji(attributedText: spoilerTextField.attributedText, textStorage: NSTextStorage(attributedString: spoilerTextField.attributedText))
            } else {
                spoilerText = ""
            }
            
            let textCount = text.count + spoilerText.count
            
            if let textCountLabel = (self.view as? TootView)?.textCountLabel {
                textCountLabel.text = "\(textCount) / 500"
                
                if textCount > 500 {
                    textCountLabel.textColor = UIColor.red
                } else {
                    textCountLabel.textColor = ThemeColor.contrastColor
                }
            }
        }
        
        self.view.setNeedsLayout()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // 画像表示を隠す
        guard let view = self.view as? TootView else { return }
        
        view.imageCheckView.isHidden = true
        view.setNeedsLayout()
    }
}
