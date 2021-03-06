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
    static var contrastColor = UIColor.white
    static var cellBgColor = UIColor.white
    static var separatorColor = UIColor.white
    
    // トゥートの文字の色
    static var messageColor = UIColor.white
    static var nameColor = UIColor.white
    static var idColor = UIColor.white
    static var dateColor = UIColor.white
    static var linkTextColor = UIColor.blue
    
    // 各種ボタンの色
    static var detailButtonsColor = UIColor.white
    static var detailButtonsHiliteColor = UIColor.white
    static var mainButtonsBgColor = UIColor.white
    static var mainButtonsTitleColor = UIColor.white
    static var buttonBorderColor = UIColor.white
    static var opaqueButtonsBgColor = UIColor.white
    
    // セル選択色
    static var selectedBgColor = UIColor(red: 0.78, green: 1.0, blue: 0.78, alpha: 1)
    static var mentionedMeBgColor = UIColor(red: 0.82, green: 0.98, blue: 0.82, alpha: 1)
    static var sameAccountBgColor = UIColor(red: 0.86, green: 0.96, blue: 0.86, alpha: 1)
    static var mentionedBgColor = UIColor(red: 1.0, green: 0.93, blue: 0.82, alpha: 1)
    static var mentionedSameBgColor = UIColor(red: 0.94, green: 0.91, blue: 0.86, alpha: 1)
    static var toMentionBgColor = UIColor(red: 0.85, green: 0.90, blue: 1.00, alpha: 1)
    
    // DM、プライベート警告バー
    static var directBar = UIColor.white
    static var privateBar = UIColor.white
    static var unlistedBar = UIColor.white
    
    static func change() {
        if SettingsData.isDarkMode {
            // ダークモード
            viewBgColor = UIColor.black
            contrastColor = UIColor.white
            cellBgColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
            separatorColor = UIColor.darkGray
            
            messageColor = UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1)
            nameColor = UIColor(red: 0.5, green: 0.8, blue: 0.3, alpha: 1)
            idColor = UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1)
            dateColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
            linkTextColor = UIColor(red: 0.3, green: 0.5, blue: 1, alpha: 1)
            
            detailButtonsColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
            detailButtonsHiliteColor = UIColor(red: 0.5, green: 1.0, blue: 0.6, alpha: 1)
            mainButtonsBgColor = UIColor(red: 0.20, green: 0.25, blue: 0.0, alpha: 0.4)
            mainButtonsTitleColor = UIColor(red: 0.7, green: 1.0, blue: 0.1, alpha: 1)
            buttonBorderColor = UIColor(red: 0.7, green: 1.0, blue: 0.1, alpha: 0.8)
            opaqueButtonsBgColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
            
            selectedBgColor = UIColor(red: 0.20, green: 0.25, blue: 0.00, alpha: 1)
            mentionedMeBgColor = UIColor(red: 0.16, green: 0.20, blue: 0.03, alpha: 1)
            sameAccountBgColor = UIColor(red: 0.12, green: 0.16, blue: 0.06, alpha: 1)
            mentionedBgColor = UIColor(red: 0.3, green: 0.20, blue: 0.12, alpha: 1)
            mentionedSameBgColor = UIColor(red: 0.24, green: 0.20, blue: 0.16, alpha: 1)
            toMentionBgColor = UIColor(red: 0.15, green: 0.20, blue: 0.30, alpha: 1)
            
            directBar = UIColor(red: 0.6, green: 0, blue: 0, alpha: 1)
            privateBar = UIColor(red: 0.4, green: 0.4, blue: 0, alpha: 1)
            unlistedBar = UIColor(red: 0.0, green: 0.2, blue: 0.6, alpha: 1)
            
            if SettingsData.color == "blue" {
                nameColor = UIColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1)
                
                detailButtonsHiliteColor = UIColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 1)
                mainButtonsBgColor = UIColor(red: 0.0, green: 0.20, blue: 0.25, alpha: 0.4)
                mainButtonsTitleColor = UIColor(red: 0.1, green: 0.7, blue: 1.0, alpha: 1)
                buttonBorderColor = UIColor(red: 0.1, green: 0.7, blue: 1.0, alpha: 0.8)
                
                selectedBgColor = UIColor(red: 0.00, green: 0.15, blue: 0.38, alpha: 1)
                mentionedMeBgColor = UIColor(red: 0.03, green: 0.16, blue: 0.20, alpha: 1)
                sameAccountBgColor = UIColor(red: 0.06, green: 0.12, blue: 0.20, alpha: 1)
                mentionedBgColor = UIColor(red: 0.12, green: 0.25, blue: 0.16, alpha: 1)
                mentionedSameBgColor = UIColor(red: 0.05, green: 0.20, blue: 0.10, alpha: 1)
                toMentionBgColor = UIColor(red: 0.30, green: 0.15, blue: 0.20, alpha: 1)
            } else if SettingsData.color == "orange" {
                nameColor = UIColor(red: 0.8, green: 0.6, blue: 0.3, alpha: 1)
                
                detailButtonsHiliteColor = UIColor(red: 1.0, green: 0.8, blue: 0.5, alpha: 1)
                mainButtonsBgColor = UIColor(red: 0.25, green: 0.20, blue: 0.00, alpha: 0.4)
                mainButtonsTitleColor = UIColor(red: 1.0, green: 0.7, blue: 0.1, alpha: 1)
                buttonBorderColor = UIColor(red: 1.0, green: 0.7, blue: 0.1, alpha: 0.8)
                
                selectedBgColor = UIColor(red: 0.30, green: 0.16, blue: 0.10, alpha: 1)
                mentionedMeBgColor = UIColor(red: 0.20, green: 0.03, blue: 0.16, alpha: 1)
                sameAccountBgColor = UIColor(red: 0.22, green: 0.12, blue: 0.06, alpha: 1)
                mentionedBgColor = UIColor(red: 0.12, green: 0.20, blue: 0.30, alpha: 1)
                mentionedSameBgColor = UIColor(red: 0.12, green: 0.16, blue: 0.24, alpha: 1)
                toMentionBgColor = UIColor(red: 0.12, green: 0.25, blue: 0.15, alpha: 1)
            } else if SettingsData.color == "monochrome" {
                nameColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
                
                detailButtonsHiliteColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
                mainButtonsBgColor = UIColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 0.4)
                mainButtonsTitleColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
                buttonBorderColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.8)
                
                selectedBgColor = UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1)
                mentionedMeBgColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
                sameAccountBgColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1)
                mentionedBgColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
                mentionedSameBgColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1)
                toMentionBgColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
            }
        } else {
            // 通常モード
            viewBgColor = UIColor.white
            contrastColor = UIColor.black
            cellBgColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
            separatorColor = UIColor.lightGray
            
            messageColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
            nameColor = UIColor(red: 0.3, green: 0.7, blue: 0.1, alpha: 1)
            idColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
            dateColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
            linkTextColor = UIColor.blue
            
            detailButtonsColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
            detailButtonsHiliteColor = UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1)
            mainButtonsBgColor = UIColor(red: 0.88, green: 1.0, blue: 0.68, alpha: 0.4)
            mainButtonsTitleColor = UIColor(red: 0.2, green: 0.4, blue: 0.0, alpha: 1)
            buttonBorderColor = UIColor(red: 0.2, green: 0.4, blue: 0.0, alpha: 0.8)
            opaqueButtonsBgColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1)
            
            selectedBgColor = UIColor(red: 0.88, green: 1.0, blue: 0.68, alpha: 1)
            mentionedMeBgColor = UIColor(red: 0.90, green: 0.98, blue: 0.75, alpha: 1)
            sameAccountBgColor = UIColor(red: 0.92, green: 0.96, blue: 0.82, alpha: 1)
            mentionedBgColor = UIColor(red: 1.0, green: 0.93, blue: 0.82, alpha: 1)
            mentionedSameBgColor = UIColor(red: 0.94, green: 0.91, blue: 0.86, alpha: 1)
            toMentionBgColor = UIColor(red: 0.85, green: 0.90, blue: 1.00, alpha: 1)
            
            directBar = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
            privateBar = UIColor(red: 1, green: 1, blue: 0, alpha: 1)
            unlistedBar = UIColor(red: 0, green: 0.7, blue: 0.9, alpha: 1)
            
            if SettingsData.color == "blue" {
                nameColor = UIColor(red: 0.1, green: 0.3, blue: 0.7, alpha: 1)
                
                detailButtonsHiliteColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1)
                mainButtonsBgColor = UIColor(red: 0.68, green: 0.88, blue: 1.0, alpha: 0.4)
                mainButtonsTitleColor = UIColor(red: 0.0, green: 0.2, blue: 0.4, alpha: 1)
                buttonBorderColor = UIColor(red: 0.0, green: 0.2, blue: 0.4, alpha: 0.8)
                
                selectedBgColor = UIColor(red: 0.68, green: 0.88, blue: 1.0, alpha: 1)
                mentionedMeBgColor = UIColor(red: 0.75, green: 0.90, blue: 0.98, alpha: 1)
                sameAccountBgColor = UIColor(red: 0.82, green: 0.92, blue: 0.96, alpha: 1)
                mentionedBgColor = UIColor(red: 0.82, green: 1.0, blue: 0.91, alpha: 1)
                mentionedSameBgColor = UIColor(red: 0.86, green: 0.94, blue: 0.88, alpha: 1)
                toMentionBgColor = UIColor(red: 1.0, green: 0.85, blue: 0.90, alpha: 1)
            } else if SettingsData.color == "orange" {
                nameColor = UIColor(red: 0.8, green: 0.5, blue: 0.0, alpha: 1)
                
                detailButtonsHiliteColor = UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1)
                mainButtonsBgColor = UIColor(red: 1.00, green: 0.92, blue: 0.68, alpha: 0.4)
                mainButtonsTitleColor = UIColor(red: 0.4, green: 0.3, blue: 0.0, alpha: 1)
                buttonBorderColor = UIColor(red: 0.8, green: 0.5, blue: 0.0, alpha: 0.8)
                
                selectedBgColor = UIColor(red: 1.0, green: 0.86, blue: 0.68, alpha: 1)
                mentionedMeBgColor = UIColor(red: 0.98, green: 0.88, blue: 0.75, alpha: 1)
                sameAccountBgColor = UIColor(red: 0.96, green: 0.90, blue: 0.82, alpha: 1)
                mentionedBgColor = UIColor(red: 0.85, green: 1.0, blue: 0.91, alpha: 1)
                mentionedSameBgColor = UIColor(red: 0.86, green: 0.94, blue: 0.88, alpha: 1)
                toMentionBgColor = UIColor(red: 0.80, green: 0.85, blue: 0.99, alpha: 1)
            } else if SettingsData.color == "monochrome" {
                nameColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
                
                detailButtonsHiliteColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
                mainButtonsBgColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.4)
                mainButtonsTitleColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
                buttonBorderColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.8)
                
                selectedBgColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
                mentionedMeBgColor = UIColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 1)
                sameAccountBgColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
                mentionedBgColor = UIColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 1)
                mentionedSameBgColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
                toMentionBgColor = UIColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 1)
            }
        }
        
        if !SettingsData.useColoring {
            selectedBgColor = cellBgColor
            mentionedMeBgColor = cellBgColor
            sameAccountBgColor = cellBgColor
            mentionedBgColor = cellBgColor
            mentionedSameBgColor = cellBgColor
            toMentionBgColor = cellBgColor
        }
    }
}
