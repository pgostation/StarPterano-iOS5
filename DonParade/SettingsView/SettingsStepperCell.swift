//
//  SettingsStepperCell.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/21.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// + / - 付きのセル

import UIKit

class SettingsStepperCell: UITableViewCell {
    var callback: ((Double)->Void)?
    
    init(style: UITableViewCell.CellStyle, value: Double, minValue: Double, maxValue: Double, step: Double) {
        super.init(style: style, reuseIdentifier: nil)
        
        self.selectionStyle = .none
        self.backgroundColor = ThemeColor.viewBgColor
        self.textLabel?.textColor = ThemeColor.idColor
        self.detailTextLabel?.textColor = ThemeColor.idColor
        
        let stepper = UIStepper()
        stepper.value = value
        stepper.stepValue = step
        stepper.minimumValue = minValue
        stepper.maximumValue = maxValue
        stepper.addTarget(self, action: #selector(swChanged(_:)), for: .valueChanged)
        stepper.frame = CGRect(x: UIScreen.main.bounds.width - 105, y: 8, width: 91, height: 31)
        self.addSubview(stepper)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func swChanged(_ stepper: UIStepper) {
        self.callback?(stepper.value)
    }
}
