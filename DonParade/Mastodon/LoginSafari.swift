//
//  LoginSafari.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/15.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// SafariからOAuth認証する

import Foundation
import SafariServices

final class LoginSafari {
    static func login(url: URL, viewController: UIViewController) {
        if #available(iOS 11.0, *) {
            loginSafari11(url: url, viewController: viewController)
        } else {
            loginSafariNormal(url: url, viewController: viewController)
        }
    }
    
    static func loginSafariNormal(url: URL, viewController: UIViewController) {
        let safariVC = SFSafariViewController(url: url)
        viewController.present(safariVC, animated: true, completion: nil)
    }
    
    private static var authSession: Any?
    
    @available(iOS 11.0, *)
    static func loginSafari11(url: URL, viewController: UIViewController) {
        let authSession = SFAuthenticationSession(url: url, callbackURLScheme: nil, completionHandler: {callbackUrl, error in
            guard let callbackUrl = callbackUrl else {
                return
            }
            UIApplication.shared.open(callbackUrl, options: [:], completionHandler: nil)
        })
        self.authSession = authSession
        authSession.start()
    }
}
