//
//  UIUtils.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/15.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// UI関連の便利機能

import UIKit

final class UIUtils {
    static let responderTag: Int = 12345 // キー入力可能なビューを見つけるための任意の番号
    static let responderTag2: Int = 12346 // キー入力可能なビューを見つけるための任意の番号
    
    // iPhone Xのようなノッチ付き画面かどうか
    static var isIphoneX: Bool = {
        let size = UIScreen.main.bounds.size
        if size.width == 320 && size.height == 480 { // iPhone 3G-4
            return false
        }
        if size.width == 320 && size.height == 568 { // iPhone 5-SE
            return false
        }
        if size.width == 375 && size.height == 667 { // iPhone 6-8
            return false
        }
        if size.width == 414 && size.height == 736 { // iPhone 6Plus-8Plus
            return false
        }
        
        return true
    }()
    
    // ステータスバーの高さ
    static func statusBarHeight() -> CGFloat {
        return UIApplication.shared.statusBarFrame.height
    }
    
    // 最前面のViewControllerを取得
    static func getFrontViewController() -> UIViewController? {
        var viewController: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
        
        while let vc = viewController?.presentedViewController {
            if vc is MyViewController {
                viewController = vc
            } else {
                break
            }
        }
        
        return viewController
    }
    
    static func fullScreen() -> CGRect {
        if UIDevice.current.model.range(of: "iPad") != nil {
            let screenBounds = UIScreen.main.bounds
            return CGRect(x: 0,
                          y: UIUtils.statusBarHeight(),
                          width: screenBounds.width,
                          height: screenBounds.height - UIUtils.statusBarHeight())
        }
        return UIScreen.main.bounds
    }
}
