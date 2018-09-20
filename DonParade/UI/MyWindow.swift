//
//  MyWindow.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/20.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 現在画面にタッチしているかどうかを調べるための、自前のUIWindow

import UIKit

final class MyWindow: UIWindow {
    var allTouches = Set<UITouch>()
    
    override func sendEvent(_ event: UIEvent) {
        if event.type == .touches {
            if let allTouches = event.allTouches {
                for touch in allTouches {
                    switch touch.phase {
                    case .began:
                        self.allTouches.insert(touch)
                    case .ended, .cancelled:
                        self.allTouches.remove(touch)
                    default:
                        break
                    }
                }
            }
        }
        
        super.sendEvent(event)
        
        allTouches.filter { $0.phase == .ended || $0.phase == .cancelled }.forEach { allTouches.remove($0) }
    }
}
