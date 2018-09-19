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
    static func show(message: String, viewController: UIViewController? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        UIUtils.getFrontViewController()?.present(alert, animated: false, completion: nil)
    }
}
