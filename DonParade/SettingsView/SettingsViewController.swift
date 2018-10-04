//
//  SettingsViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/16.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit

final class SettingsViewController: MyViewController {
    static weak var instance: SettingsViewController?
    
    override func viewDidLoad() {
        SettingsViewController.instance = self
        
        self.view.backgroundColor = ThemeColor.selectedBgColor
        
        self.modalTransitionStyle = .crossDissolve
        
        let view = SettingsView()
        self.view.addSubview(view)
        
        let closeButton = UIButton()
        closeButton.setTitle(I18n.get("BUTTON_CLOSE"), for: .normal)
        closeButton.setTitleColor(ThemeColor.messageColor, for: .normal)
        closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        closeButton.frame = CGRect(x: 10,
                                   y: UIUtils.statusBarHeight() + 3,
                                   width: 60,
                                   height: 44)
        self.view.addSubview(closeButton)
        
        // 右スワイプで閉じる
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(closeAction))
        swipeGesture.direction = .right
        self.view?.addGestureRecognizer(swipeGesture)
    }
    
    @objc func closeAction() {
        self.dismiss(animated: true, completion: {
            /*// 一度メイン画面も閉じる
            MainViewController.instance?.dismiss(animated: false, completion: nil)
            
            // 改めてメイン画面を開く
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let mainViewController = MainViewController()
                UIUtils.getFrontViewController()?.present(mainViewController, animated: false, completion: nil)
            }*/
        })
        
    }
}

private final class SettingsView: UITableView {
    let model = SettingsModel()
    
    init() {
        let screenBounds = UIScreen.main.bounds
        let frame = CGRect(x: 0,
                           y: UIUtils.statusBarHeight() + 50,
                           width: screenBounds.width,
                           height: screenBounds.height - UIUtils.statusBarHeight() - 50)
        super.init(frame: frame,
                   style: UITableViewStyle.grouped)
        
        self.delegate = model
        self.dataSource = model
        
        self.backgroundColor = ThemeColor.cellBgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
