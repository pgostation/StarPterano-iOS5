//
//  TootViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/19.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit

final class TootViewController: UIViewController, UITextViewDelegate {
    static var isShown = false // 現在表示中かどうか
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        TootViewController.isShown = true
        
        self.modalPresentationStyle = .overCurrentContext
    }
    
    deinit {
        TootViewController.isShown = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = TootView()
        self.view = view
        
        // メッセージフィールドのデリゲートを設定
        view.textField.delegate = self
        
        // ボタン
        view.closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        view.tootButton.addTarget(self, action: #selector(tootAction), for: .touchUpInside)
        
        // 入力バー部分のボタン
        view.imagesButton.addTarget(self, action: #selector(addImageAction), for: .touchUpInside)
        view.imagesCountButton.addTarget(self, action: #selector(showImagesAction), for: .touchUpInside)
        view.protectButton.addTarget(self, action: #selector(protectAction), for: .touchUpInside)
        view.cwButton.addTarget(self, action: #selector(cwAction), for: .touchUpInside)
        //view.saveButton.addTarget(self, action: #selector(saveAction), for: .touchUpInside)
        //view.idButton.addTarget(self, action: #selector(idAction), for: .touchUpInside)
        view.emojiButton.addTarget(self, action: #selector(emojiAction), for: .touchUpInside)
    }
    
    // トゥートする
    @objc func tootAction() {
        guard let view = self.view as? TootView else { return }
        
        guard let text = view.textField.text else { return }
        if text.count == 0 { return }
        
        guard let hostName = SettingsData.hostName else { return }
        
        let url = URL(string: "https://\(hostName)/api/v1/statuses")!
        try? MastodonRequest.post(url: url, body: ["status": text]) { (data, response, error) in
        }
        
        self.dismiss(animated: false, completion: nil)
    }
    
    // 添付画像を追加する
    @objc func addImageAction() {
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
    }
    
    // 下書きにする / 下書きを復帰する
    @objc func saveAction() {
    }
    
    // idを補完入力する
    @objc func idAction() {
    }
    
    // カスタム絵文字を入力する
    @objc func emojiAction() {
    }
    
    // 画面を閉じる
    @objc func closeAction() {
        self.view.removeFromSuperview()
        self.removeFromParentViewController()
        
        TootViewController.isShown = false
    }
    
    // テキストビューの高さを変化させる
    func textViewDidChange(_ textView: UITextView) {
        DispatchQueue.main.async {
            self.view.setNeedsLayout()
        }
    }
}
