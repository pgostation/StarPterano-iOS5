//
//  LoginViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/15.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit

final class LoginViewController: MyViewController {
    static weak var instance: LoginViewController?
    
    override func loadView() {
        LoginViewController.instance = self
        
        let loginView = LoginView()
        self.view = loginView
        
        loginView.authButton.addTarget(Login.self, action: #selector(Login.authAction(_:)), for: .touchUpInside)
        loginView.codeEnterButton.addTarget(Login.self, action: #selector(Login.codeEnterAction(_:)), for: .touchUpInside)
    }
}

final class LoginView: UIView {
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
        
        authButton.setTitle(I18n.get("BUTTON_MASTODON_OAUTH"), for: .normal)
        authButton.backgroundColor = UIColor.lightGray
        authButton.setTitleColor(UIColor.blue, for: .normal)
        
        inputCodeField.placeholder = I18n.get("PLACEHOLDER_INPUT_CODE")
        inputCodeField.layer.borderColor = UIColor.gray.cgColor
        inputCodeField.layer.borderWidth = 0.5
        
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
        hostField.isHidden = true
        authButton.isHidden = true
        inputCodeField.isHidden = false
        codeEnterButton.isHidden = false
    }
}

final class Login {
    private static var responseJson: Dictionary<String, AnyObject>?
    
    // マストドン認証
    @objc static func authAction(_ sender: UIButton) {
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
                                      "scopes": "write"]
        
        // クライアント認証POST
        do {
            try MastodonPost.post(url: registerUrl, body: body) { (data, response, error) in
                if let data = data {
                    do {
                        self.responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, AnyObject>
                        
                        print("#### responseJson=\(String(describing: self.responseJson))")
                        // Safariでログイン
                        self.login(hostName: hostName)
                        
                        // 認証コード入力フィールドを表示する
                        view.showInputCodeField()
                    } catch {
                    }
                } else if let error = error {
                    print(error)
                }
            }
        } catch {
        }
    }
    
    // Safariでのログイン
    private static func login(hostName: String) {
        let clientId = responseJson?["client_id"] as? String
        var paramBase = ""
        paramBase += "client_id=\(clientId ?? "")&"
        paramBase += "response_type=code&"
        paramBase += "redirect_uri=urn:ietf:wg:oauth:2.0:oob&"
        paramBase += "scope=write"
        
        let params = paramBase.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        print("##### params = \(params)")
        
        let loginUrl = URL(string: "https://\(hostName)/oauth//authorize?\(params)")!
        
        if let vc = LoginViewController.instance {
            LoginSafari.login(url: loginUrl, viewController: vc)
        }
    }
    
    // コード入力
    @objc static func codeEnterAction(_ sender: UIButton) {
        guard let view = sender.superview as? LoginView else { return }
        
        if view.inputCodeField.text == nil || view.inputCodeField.text!.count < 10 {
            Dialog.show(message: I18n.get("ALERT_INPUT_CODE_FAILURE"))
            return
        }
        
        SettingsData.oauthCode = view.inputCodeField.text
        
        // メイン画面へ移動
        let mainViewController = MainViewController()
        LoginViewController.instance?.present(mainViewController, animated: false, completion: nil)
    }
}
