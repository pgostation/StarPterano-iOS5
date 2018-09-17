//
//  SettingsViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/16.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit

final class SettingsViewController: MyViewController {
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor.lightGray
        
        let view = SettingsView()
        self.view.addSubview(view)
        
        let closeButton = UIButton()
        closeButton.setTitle(I18n.get("BUTTON_CLOSE"), for: .normal)
        closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        closeButton.frame = CGRect(x: 10,
                                   y: UIUtils.statusBarHeight() + 3,
                                   width: 60,
                                   height: 44)
        self.view.addSubview(closeButton)
    }
    
    @objc func closeAction() {
        self.dismiss(animated: true, completion: nil)
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
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
