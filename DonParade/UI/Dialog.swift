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
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        UIUtils.getFrontViewController()?.present(alert, animated: false, completion: nil)
    }
    
    // 2ボタンのダイアログを表示
    static func show(message: String, viewController: UIViewController? = nil, okName: String, cancelName: String, callback: @escaping (Bool)->Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: okName, style: UIAlertActionStyle.default, handler: { _ in
            callback(true)
        }))
        
        alert.addAction(UIAlertAction(title: cancelName, style: UIAlertActionStyle.cancel, handler: { _ in
            callback(false)
        }))
        
        UIUtils.getFrontViewController()?.present(alert, animated: false, completion: nil)
    }
    
    // 入力欄付きのダイアログを表示
    private static var timer: Timer?
    private static var callback: ((UITextField, Bool)->Void)?
    private static var textField: UITextField?
    static func showWithTextInput(message: String, viewController: UIViewController? = nil, okName: String, cancelName: String, defaultText: String?, timerCallback: Bool = false, callback: @escaping (UITextField, Bool)->Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addTextField(configurationHandler: { textField in
            self.callback = callback
            self.textField = textField
            textField.text = defaultText
            
            alert.addAction(UIAlertAction(title: okName, style: UIAlertActionStyle.default, handler: { _ in
                self.timer?.invalidate()
                self.timer = nil
                self.callback = nil
                self.textField = nil
                callback(textField, true)
            }))
            
            alert.addAction(UIAlertAction(title: cancelName, style: UIAlertActionStyle.cancel, handler: { _ in
                self.timer?.invalidate()
                self.timer = nil
                self.callback = nil
                self.textField = nil
                callback(textField, false)
            }))
            
            UIUtils.getFrontViewController()?.present(alert, animated: false, completion: nil)
            
            if timerCallback {
                self.timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
            }
        })
    }
    
    @objc static func timerAction() {
        if self.timer == nil { return }
        
        self.callback?(self.textField!, true)
    }
}
