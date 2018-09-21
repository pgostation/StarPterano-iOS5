//
//  ThemeColor.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/21.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 文字色などを保持

import UIKit

final class ThemeColor {
    // 基本の背景色
    static var viewBgColor = UIColor.white
    static var cellBgColor = UIColor.white
    static var separatorColor = UIColor.white
    
    // トゥートの文字の色
    static var messageColor = UIColor.white
    static var nameColor = UIColor.white
    static var idColor = UIColor.white
    static var dateColor = UIColor.white
    
    // 各種ボタンの色
    static var detailButtonsColor = UIColor.white
    static var detailButtonsHiliteColor = UIColor.white
    static var mainButtonsBgColor = UIColor.white
    static var mainButtonsTitleColor = UIColor.white
    static var buttonBorderColor = UIColor.white
    static var opaqueButtonsBgColor = UIColor.white
    
    // セル選択色
    static var selectedBgColor = UIColor(red: 0.78, green: 1.0, blue: 0.78, alpha: 1)
    static var sameAccountBgColor = UIColor(red: 0.86, green: 0.96, blue: 0.86, alpha: 1)
    static var mentionedBgColor = UIColor(red: 1.0, green: 0.93, blue: 0.82, alpha: 1)
    static var mentionedSameBgColor = UIColor(red: 0.94, green: 0.91, blue: 0.86, alpha: 1)
    static var toMentionBgColor = UIColor(red: 0.85, green: 0.90, blue: 1.00, alpha: 1)
    
    static func change() {
        if SettingsData.isDarkMode {
            // ダークモード
            viewBgColor = UIColor.black
            cellBgColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
            separatorColor = UIColor.darkGray
            
            messageColor = UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1)
            nameColor = UIColor(red: 0.4, green: 0.7, blue: 0.4, alpha: 1)
            idColor = UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1)
            dateColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
            
            detailButtonsColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
            detailButtonsHiliteColor = UIColor(red: 0.5, green: 1.0, blue: 0.6, alpha: 1)
            mainButtonsBgColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.4)
            mainButtonsTitleColor = UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 1)
            buttonBorderColor = UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 0.8)
            opaqueButtonsBgColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
            
            selectedBgColor = UIColor(red: 0.00, green: 0.25, blue: 0.00, alpha: 1)
            sameAccountBgColor = UIColor(red: 0.06, green: 0.16, blue: 0.06, alpha: 1)
            mentionedBgColor = UIColor(red: 0.3, green: 0.33, blue: 0.12, alpha: 1)
            mentionedSameBgColor = UIColor(red: 0.24, green: 0.21, blue: 0.16, alpha: 1)
            toMentionBgColor = UIColor(red: 0.15, green: 0.20, blue: 0.30, alpha: 1)
        } else {
            // 通常モード
            viewBgColor = UIColor.white
            cellBgColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
            separatorColor = UIColor.lightGray
            
            messageColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
            nameColor = UIColor(red: 0.3, green: 0.7, blue: 0.1, alpha: 1)
            idColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
            dateColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
            
            detailButtonsColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
            detailButtonsHiliteColor = UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1)
            mainButtonsBgColor = UIColor(red: 0.6, green: 1.0, blue: 0.0, alpha: 0.4)
            mainButtonsTitleColor = UIColor(red: 0.2, green: 0.4, blue: 0.0, alpha: 1)
            buttonBorderColor = UIColor(red: 0.2, green: 0.4, blue: 0.0, alpha: 0.8)
            opaqueButtonsBgColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1)
            
            selectedBgColor = UIColor(red: 0.88, green: 1.0, blue: 0.78, alpha: 1)
            sameAccountBgColor = UIColor(red: 0.92, green: 0.96, blue: 0.86, alpha: 1)
            mentionedBgColor = UIColor(red: 1.0, green: 0.93, blue: 0.82, alpha: 1)
            mentionedSameBgColor = UIColor(red: 0.94, green: 0.91, blue: 0.86, alpha: 1)
            toMentionBgColor = UIColor(red: 0.85, green: 0.90, blue: 1.00, alpha: 1)
        }
    }
}
