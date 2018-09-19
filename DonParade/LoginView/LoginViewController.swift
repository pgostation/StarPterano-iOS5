//
//  LoginViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/15.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit

final class LoginViewController: MyViewController {
    override func loadView() {
        let loginView = LoginView()
        self.view = loginView
        
        loginView.authButton.addTarget(self, action: #selector(authAction(_:)), for: .touchUpInside)
        loginView.codeEnterButton.addTarget(self, action: #selector(codeEnterAction(_:)), for: .touchUpInside)
    }
    
    // マストドン認証
    private var responseJson: Dictionary<String, AnyObject>?
    @objc func authAction(_ sender: UIButton) {
        guard let view = sender.superview as? LoginView else { return }
        
        sender.backgroundColor = UIColor.darkGray
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            sender.backgroundColor = UIColor.lightGray
        }
        
        let hostName = (view.hostField.text ?? "").replacingOccurrences(of: "/ ", with: "")
        if hostName == "" {
            Dialog.show(message: I18n.get("ALERT_INPUT_DOMAIN"))
            return
        }
        
        guard let registerUrl = URL(string: "https://\(hostName)/api/v1/apps") else { return }
        
        let body: [String: String] = ["client_name": "DonParade",
                                      "redirect_uris": "urn:ietf:wg:oauth:2.0:oob",
                                      "scopes": "read write follow"]
        
        // クライアント認証POST
        try? MastodonRequest.firstPost(url: registerUrl, body: body) { (data, response, error) in
            if let data = data {
                do {
                    self.responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, AnyObject>
                    
                    DispatchQueue.main.async {
                        // Safariでログイン
                        self.login(hostName: hostName)
                        
                        // 認証コード入力フィールドを表示する
                        view.showInputCodeField()
                    }
                } catch {
                }
            } else if let error = error {
                print(error)
            }
        }
    }
    
    // Safariでのログイン
    private func login(hostName: String) {
        guard let clientId = responseJson?["client_id"] as? String else { return }
        var paramBase = ""
        paramBase += "client_id=\(clientId)&"
        paramBase += "response_type=code&"
        paramBase += "redirect_uri=urn:ietf:wg:oauth:2.0:oob&"
        paramBase += "scope=read write follow"
        
        let params = paramBase.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        let loginUrl = URL(string: "https://\(hostName)/oauth//authorize?\(params)")!
        
        LoginSafari.login(url: loginUrl, viewController: self)
    }
    
    // コード入力
    @objc func codeEnterAction(_ sender: UIButton) {
        guard let view = sender.superview as? LoginView else { return }
        
        if view.inputCodeField.text == nil || view.inputCodeField.text!.count < 10 {
            Dialog.show(message: I18n.get("ALERT_INPUT_CODE_FAILURE"))
            return
        }
        
        // アクセストークンを取得
        let tmpHostName = (view.hostField.text ?? "").replacingOccurrences(of: "/ ", with: "")
        let hostName = String(tmpHostName).lowercased()
        guard let registerUrl = URL(string: "https://\(hostName)/oauth/token") else { return }
        
        guard let clientId = responseJson?["client_id"] as? String else { return }
        guard let clientSecret = responseJson?["client_secret"] as? String else { return }
        guard let oauthCode = view.inputCodeField.text else { return }
        
        let body: [String: String] = ["grant_type" : "authorization_code",
                                      "redirect_uri" : "urn:ietf:wg:oauth:2.0:oob",
                                      "client_id": "\(clientId)",
                                      "client_secret": "\(clientSecret)",
                                      "code": "\(oauthCode)"]
        
        // クライアント認証POST
        try? MastodonRequest.firstPost(url: registerUrl, body: body) { (data, response, error) in
            if let data = data {
                do {
                    let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, AnyObject>
                    
                    SettingsData.hostName = hostName
                    SettingsData.accessToken = responseJson?["access_token"] as? String
                    
                    // メイン画面へ移動
                    DispatchQueue.main.async {
                        let mainViewController = MainViewController()
                        self.present(mainViewController, animated: false, completion: nil)
                    }
                } catch {
                }
            } else if let error = error {
                print(error)
            }
        }
    }
}

private final class LoginView: UIView {
    let hostField = UITextField()
    let authButton = UIButton()
    let inputCodeField = UITextField()
    let codeEnterButton = UIButton()
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        
        self.addSubview(hostField)
        self.addSubview(authButton)
        self.addSubview(inputCodeField)
        self.addSubview(codeEnterButton)
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.backgroundColor = UIColor.white
        
        hostField.placeholder = I18n.get("PLACEHOLDER_INPUT_DOMAIN")
        hostField.layer.borderColor = UIColor.gray.cgColor
        hostField.layer.borderWidth = 0.5
        hostField.keyboardType = .alphabet
        
        authButton.setTitle(I18n.get("BUTTON_MASTODON_OAUTH"), for: .normal)
        authButton.backgroundColor = UIColor.lightGray
        authButton.setTitleColor(UIColor.blue, for: .normal)
        
        inputCodeField.placeholder = I18n.get("PLACEHOLDER_INPUT_CODE")
        inputCodeField.layer.borderColor = UIColor.gray.cgColor
        inputCodeField.layer.borderWidth = 0.5
        inputCodeField.keyboardType = .alphabet
        
        codeEnterButton.setTitle(I18n.get("BUTTON_ENTER_CODE"), for: .normal)
        codeEnterButton.backgroundColor = UIColor.lightGray
        codeEnterButton.setTitleColor(UIColor.blue, for: .normal)
        
        inputCodeField.isHidden = true
        codeEnterButton.isHidden = true
    }
    
    override func layoutSubviews() {
        let screenBounds = UIScreen.main.bounds
        let fieldWidth: CGFloat = 240
        let fieldHeight: CGFloat = 40
        let buttonWidth: CGFloat = 150
        let buttonHeight: CGFloat = 50
        
        hostField.frame = CGRect(x: screenBounds.width / 2 - fieldWidth / 2,
                                 y: 100,
                                 width: fieldWidth,
                                 height: fieldHeight)
        
        authButton.frame = CGRect(x: screenBounds.width / 2 - buttonWidth / 2,
                                  y: 200,
                                  width: buttonWidth,
                                  height: buttonHeight)
        
        inputCodeField.frame = CGRect(x: screenBounds.width / 2 - fieldWidth / 2,
                                      y: 100,
                                      width: fieldWidth,
                                      height: fieldHeight)
        
        codeEnterButton.frame = CGRect(x: screenBounds.width / 2 - buttonWidth / 2,
                                       y: 200,
                                       width: buttonWidth,
                                       height: buttonHeight)
    }
    
    // 認証コード入力フィールドを表示する
    func showInputCodeField() {
        DispatchQueue.main.async {
            self.hostField.isHidden = true
            self.authButton.isHidden = true
            self.inputCodeField.isHidden = false
            self.codeEnterButton.isHidden = false
        }
    }
}
