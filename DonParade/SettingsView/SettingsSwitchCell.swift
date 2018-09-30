//
//  SettingsSwitchCell.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/21.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// スイッチ付きのセル

import UIKit

class SettingsSwitchCell: UITableViewCell {
    var callback: ((Bool)->Void)?
    
    init(style: UITableViewCellStyle, isOn: Bool) {
        super.init(style: style, reuseIdentifier: nil)
        
        self.selectionStyle = .none
        self.backgroundColor = ThemeColor.viewBgColor
        self.textLabel?.textColor = ThemeColor.idColor
        self.detailTextLabel?.textColor = ThemeColor.idColor
        
        let sw = UISwitch()
        sw.isOn = isOn
        sw.addTarget(self, action: #selector(swChanged(_:)), for: .valueChanged)
        sw.frame = CGRect(x: UIScreen.main.bounds.width - 70, y: 8, width: 51, height: 31)
        self.addSubview(sw)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func swChanged(_ sw: UISwitch) {
        self.callback?(sw.isOn)
    }
}
