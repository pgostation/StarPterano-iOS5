//
//  TootViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/19.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit

final class TootViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = TootView()
        self.view = view
        
        view.closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        view.tootButton.addTarget(self, action: #selector(tootAction), for: .touchUpInside)
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
    
    // 画面を閉じる
    @objc func closeAction() {
        self.dismiss(animated: false, completion: nil)
    }
}

private final class TootView: UIView {
    // 閉じるボタン
    let closeButton = UIButton()
    
    // トゥート
    let textField = UITextView()
    let tootButton = UIButton()
    
    // 入力バー
    let inputBar = UIView()
    let imagesButton = UIButton()
    let protectButton = UIButton()
    let emojiButton = UIButton()
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        
        self.backgroundColor = UIColor.clear
        self.isOpaque = false
        
        self.addSubview(closeButton)
        
        self.addSubview(textField)
        self.addSubview(tootButton)
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.backgroundColor = UIColor.white
        
        closeButton.setTitle(I18n.get("BUTTON_CLOSE"), for: .normal)
        closeButton.backgroundColor = UIColor.lightGray
        closeButton.setTitleColor(UIColor.blue, for: .normal)
        
        tootButton.setTitle(I18n.get("BUTTON_TOOT"), for: .normal)
        tootButton.backgroundColor = UIColor.lightGray
        tootButton.setTitleColor(UIColor.blue, for: .normal)
        
        textField.becomeFirstResponder()
        textField.isEditable = true
        textField.layer.borderColor = UIColor.black.cgColor
        textField.layer.borderWidth = 1 / UIScreen.main.scale
    }
    
    override func layoutSubviews() {
        let screenBounds = UIScreen.main.bounds
        
        closeButton.frame = CGRect(x: 0,
                                   y: 50,
                                   width: 80,
                                   height: 40)
        
        tootButton.frame = CGRect(x: screenBounds.width - 100,
                                  y: 210,
                                  width: 80,
                                  height: 40)
        
        textField.frame = CGRect(x: 10,
                                 y: 100,
                                 width: screenBounds.width - 20,
                                 height: 100)
    }
}
