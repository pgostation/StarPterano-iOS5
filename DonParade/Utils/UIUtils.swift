//
//  UIUtils.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/15.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit

final class UIUtils {
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
}
