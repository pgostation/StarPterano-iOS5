//
//  MainView.swift
//  DonParade
//
//  Created by takayoshi on 2018/10/03.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit

final class MainView: UIView {
    // 左下
    let tlButton = WideTouchButton()
    let ltlButton = WideTouchButton()
    let ftlButton = WideTouchButton()
    let listButton = WideTouchButton()
    
    // 中央下
    let tootButton = UIButton()
    
    // 右下
    let searchButton = WideTouchButton()
    let notificationsButton = WideTouchButton()
    
    // 右上
    let accountButton = WideTouchButton()
    
    // 上側の一時メッセージ表示
    let notifyLabel = UILabel()
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        
        self.addSubview(tlButton)
        self.addSubview(ltlButton)
        self.addSubview(ftlButton)
        self.addSubview(listButton)
        self.addSubview(tootButton)
        self.addSubview(searchButton)
        self.addSubview(notificationsButton)
        self.addSubview(accountButton)
        self.addSubview(notifyLabel)
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func refreshColor() {
        setProperties()
    }
    
    private func setProperties() {
        self.backgroundColor = ThemeColor.viewBgColor
        
        tlButton.insets = UIEdgeInsetsMake(5, 5, 5, 5)
        tlButton.setTitle(I18n.get("BUTTON_TL"), for: .normal)
        tlButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        tlButton.titleLabel?.adjustsFontSizeToFitWidth = true
        tlButton.setTitleShadowColor(ThemeColor.viewBgColor, for: .normal)
        tlButton.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)
        tlButton.backgroundColor = ThemeColor.mainButtonsBgColor
        tlButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        tlButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        tlButton.layer.borderWidth = 1 / UIScreen.main.scale
        tlButton.clipsToBounds = true
        tlButton.layer.cornerRadius = 10
        tlButton.isExclusiveTouch = true
        if #available(iOS 11.0, *) {
            tlButton.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        }
        
        ltlButton.insets = UIEdgeInsetsMake(5, 5, 5, 5)
        ltlButton.setTitle(I18n.get("BUTTON_LTL"), for: .normal)
        ltlButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        ltlButton.titleLabel?.adjustsFontSizeToFitWidth = true
        ltlButton.setTitleShadowColor(ThemeColor.viewBgColor, for: .normal)
        ltlButton.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)
        ltlButton.backgroundColor = ThemeColor.mainButtonsBgColor
        ltlButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        ltlButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        ltlButton.layer.borderWidth = 1 / UIScreen.main.scale
        ltlButton.clipsToBounds = true
        ltlButton.layer.cornerRadius = 10
        ltlButton.isExclusiveTouch = true
        if #available(iOS 11.0, *) {
            ltlButton.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        }
        
        ftlButton.insets = UIEdgeInsetsMake(5, 5, 5, 5)
        ftlButton.setTitle(I18n.get("BUTTON_FTL"), for: .normal)
        ftlButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        ftlButton.titleLabel?.adjustsFontSizeToFitWidth = true
        ftlButton.setTitleShadowColor(ThemeColor.viewBgColor, for: .normal)
        ftlButton.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)
        ftlButton.backgroundColor = ThemeColor.mainButtonsBgColor
        ftlButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        ftlButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        ftlButton.layer.borderWidth = 1 / UIScreen.main.scale
        ftlButton.clipsToBounds = true
        ftlButton.layer.cornerRadius = 10
        ftlButton.isExclusiveTouch = true
        if #available(iOS 11.0, *) {
            ftlButton.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        }
        
        listButton.insets = UIEdgeInsetsMake(5, 5, 5, 5)
        listButton.setTitle(I18n.get("BUTTON_LIST"), for: .normal)
        listButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        listButton.titleLabel?.adjustsFontSizeToFitWidth = true
        listButton.setTitleShadowColor(ThemeColor.viewBgColor, for: .normal)
        listButton.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)
        listButton.backgroundColor = ThemeColor.mainButtonsBgColor
        listButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        listButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        listButton.layer.borderWidth = 1 / UIScreen.main.scale
        listButton.clipsToBounds = true
        listButton.layer.cornerRadius = 10
        listButton.isExclusiveTouch = true
        if #available(iOS 11.0, *) {
            listButton.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        }
        
        tootButton.setTitle(I18n.get("BUTTON_TOOT"), for: .normal)
        tootButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        tootButton.titleLabel?.adjustsFontSizeToFitWidth = true
        tootButton.setTitleShadowColor(ThemeColor.viewBgColor, for: .normal)
        tootButton.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)
        tootButton.backgroundColor = ThemeColor.mainButtonsBgColor
        tootButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        tootButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        tootButton.layer.borderWidth = 1 / UIScreen.main.scale
        tootButton.clipsToBounds = true
        tootButton.layer.cornerRadius = 35
        tootButton.isExclusiveTouch = true
        
        searchButton.insets = UIEdgeInsetsMake(5, 5, 5, 5)
        searchButton.setTitle(I18n.get("BUTTON_SEARCH"), for: .normal)
        searchButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        searchButton.titleLabel?.adjustsFontSizeToFitWidth = true
        searchButton.setTitleShadowColor(ThemeColor.viewBgColor, for: .normal)
        searchButton.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)
        searchButton.backgroundColor = ThemeColor.mainButtonsBgColor
        searchButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        searchButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        searchButton.layer.borderWidth = 1 / UIScreen.main.scale
        searchButton.clipsToBounds = true
        searchButton.layer.cornerRadius = 10
        searchButton.isExclusiveTouch = true
        if #available(iOS 11.0, *) {
            searchButton.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
        }
        
        notificationsButton.insets = UIEdgeInsetsMake(5, 5, 5, 5)
        notificationsButton.setTitle(I18n.get("BUTTON_NOTIFY"), for: .normal)
        notificationsButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        notificationsButton.titleLabel?.adjustsFontSizeToFitWidth = true
        notificationsButton.setTitleShadowColor(ThemeColor.viewBgColor, for: .normal)
        notificationsButton.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)
        notificationsButton.backgroundColor = ThemeColor.mainButtonsBgColor
        notificationsButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        notificationsButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        notificationsButton.layer.borderWidth = 1 / UIScreen.main.scale
        notificationsButton.clipsToBounds = true
        notificationsButton.layer.cornerRadius = 10
        notificationsButton.isExclusiveTouch = true
        if #available(iOS 11.0, *) {
            notificationsButton.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
        }
        
        accountButton.insets = UIEdgeInsetsMake(5, 5, 5, 5)
        accountButton.setTitle("", for: .normal)
        accountButton.backgroundColor = ThemeColor.mainButtonsBgColor
        accountButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        accountButton.clipsToBounds = true
        accountButton.layer.cornerRadius = 10
        accountButton.isExclusiveTouch = true
        
        notifyLabel.backgroundColor = ThemeColor.idColor.withAlphaComponent(0.8)
        notifyLabel.textColor = ThemeColor.viewBgColor
        notifyLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
        notifyLabel.textAlignment = .center
        notifyLabel.numberOfLines = 0
        notifyLabel.lineBreakMode = .byCharWrapping
        notifyLabel.layer.cornerRadius = 4
        notifyLabel.clipsToBounds = true
        notifyLabel.alpha = 0
    }
    
    override func layoutSubviews() {
        let screenBounds = UIScreen.main.bounds
        let bottomOffset: CGFloat = UIUtils.isIphoneX ? 50 : 0
        let bottomOffset2: CGFloat = SettingsData.showFTLButton ? 50 : 0
        let buttonWidth: CGFloat = 60
        let buttonHeight: CGFloat = 40
        
        if SettingsData.showListButton {
            listButton.frame = CGRect(x: -1,
                                      y: screenBounds.height - 150 - bottomOffset - bottomOffset2,
                                      width: buttonWidth,
                                      height: buttonHeight)
        } else {
            listButton.frame.origin.x = -100
        }
        
        tlButton.frame = CGRect(x: -1,
                                y: screenBounds.height - 100 - bottomOffset - bottomOffset2,
                                width: buttonWidth,
                                height: buttonHeight)
        
        ltlButton.frame = CGRect(x: -1,
                                 y: screenBounds.height - 50 - bottomOffset - bottomOffset2,
                                 width: buttonWidth,
                                 height: buttonHeight)
        
        if SettingsData.showFTLButton {
            ftlButton.frame = CGRect(x: -1,
                                     y: screenBounds.height - 0 - bottomOffset - bottomOffset2,
                                     width: buttonWidth,
                                     height: buttonHeight)
        } else {
            ftlButton.frame = CGRect(x: -1,
                                     y: screenBounds.height + 50,
                                     width: buttonWidth,
                                     height: buttonHeight)
        }
        
        tootButton.frame = CGRect(x: screenBounds.width / 2 - 70 / 2,
                                  y: screenBounds.height - 70 - bottomOffset,
                                  width: 70,
                                  height: 70)
        
        searchButton.frame = CGRect(x: screenBounds.width - buttonWidth + 1,
                                    y: screenBounds.height - 100 - bottomOffset,
                                    width: buttonWidth,
                                    height: buttonHeight)
        
        if TootViewController.isShown {
            notificationsButton.frame = CGRect(x: screenBounds.width - buttonWidth + 1,
                                               y: UIUtils.statusBarHeight() + 80,
                                               width: buttonWidth,
                                               height: buttonHeight)
        } else {
            notificationsButton.frame = CGRect(x: screenBounds.width - buttonWidth + 1,
                                               y: screenBounds.height - 50 - bottomOffset,
                                               width: buttonWidth,
                                               height: buttonHeight)
        }
        
        accountButton.frame = CGRect(x: screenBounds.width - SettingsData.iconSize - 10,
                                     y: UIUtils.statusBarHeight() + 10,
                                     width: SettingsData.iconSize,
                                     height: SettingsData.iconSize)
    }
}
