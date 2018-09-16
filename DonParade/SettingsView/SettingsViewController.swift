//
//  SettingsViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/16.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit

final class SettingsViewController: MyViewController {
    
}

private final class SettingsView: UITableView {
    let model = SettingsModel()
    
    init() {
        super.init(frame: UIScreen.main.bounds, style: UITableViewStyle.grouped)
        
        self.delegate = model
        self.dataSource = model
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
