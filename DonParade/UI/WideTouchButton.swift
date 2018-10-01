//
//  WideTouchButton.swift
//  DonParade
//
//  Created by takayoshi on 2018/10/01.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit

final class WideTouchButton: UIButton {
    var insets = UIEdgeInsetsMake(0, 0, 0, 0)
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var rect = bounds
        rect.origin.x -= insets.left
        rect.origin.y -= insets.top
        rect.size.width += insets.left + insets.right
        rect.size.height += insets.top + insets.bottom
        
        // 拡大したViewサイズがタップ領域に含まれているかどうかを返します
        return rect.contains(point)
    }
}

final class WideTouchImageView: UIImageView {
    var insets = UIEdgeInsetsMake(0, 0, 0, 0)
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var rect = bounds
        rect.origin.x -= insets.left
        rect.origin.y -= insets.top
        rect.size.width += insets.left + insets.right
        rect.size.height += insets.top + insets.bottom
        
        // 拡大したViewサイズがタップ領域に含まれているかどうかを返します
        return rect.contains(point)
    }
}
