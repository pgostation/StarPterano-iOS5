//
//  Dialog.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/15.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// いつでもどこでもダイアログを表示する

import UIKit

final class Dialog {
    // OKボタンだけのダイアログを表示
    static func show(message: String, viewController: UIViewController? = nil) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                show(message: message, viewController: viewController)
            }
            return
        }
        
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        
        UIUtils.getFrontViewController()?.present(alert, animated: false, completion: nil)
    }
    
    // 2ボタンのダイアログを表示
    static func show(message: String, viewController: UIViewController? = nil, okName: String, cancelName: String, callback: @escaping (Bool)->Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: okName, style: UIAlertAction.Style.default, handler: { _ in
            callback(true)
        }))
        
        alert.addAction(UIAlertAction(title: cancelName, style: UIAlertAction.Style.cancel, handler: { _ in
            callback(false)
        }))
        
        UIUtils.getFrontViewController()?.present(alert, animated: false, completion: nil)
    }
    
    // 入力欄付きのダイアログを表示
    static func showWithTextInput(message: String, viewController: UIViewController? = nil, okName: String, cancelName: String, defaultText: String?, isAlphabet: Bool = false, callback: @escaping (UITextField, Bool)->Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertController.Style.alert)
        
        alert.addTextField(configurationHandler: { textField in
            textField.text = defaultText
            if isAlphabet {
                textField.keyboardType = .alphabet
            }
            
            alert.addAction(UIAlertAction(title: okName, style: UIAlertAction.Style.default, handler: { _ in
                callback(textField, true)
            }))
            
            alert.addAction(UIAlertAction(title: cancelName, style: UIAlertAction.Style.cancel, handler: { _ in
                callback(textField, false)
            }))
            
            UIUtils.getFrontViewController()?.present(alert, animated: false, completion: nil)
        })
    }
}
