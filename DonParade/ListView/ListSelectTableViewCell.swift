//
//  ListSelectTableViewCell.swift
//  DonParade
//
//  Created by takayoshi on 2018/10/04.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit

final class ListSelectTableViewCell: UITableViewCell {
    var id = ""
    
    // 基本ビュー
    let lineLayer = CALayer()
    let nameLabel = UILabel()
    let editButton = UIButton()
    
    init(reuseIdentifier: String?) {
        super.init(style: UITableViewCellStyle.default, reuseIdentifier: reuseIdentifier)
        
        // デフォルトのビューは不要
        self.textLabel?.removeFromSuperview()
        self.detailTextLabel?.removeFromSuperview()
        self.imageView?.removeFromSuperview()
        self.contentView.removeFromSuperview()
        
        self.addSubview(nameLabel)
        self.addSubview(editButton)
        self.layer.addSublayer(self.lineLayer)
        
        editButton.addTarget(self, action: #selector(editButtonAction), for: .touchUpInside)
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        // 固定プロパティは初期化時に設定
        self.clipsToBounds = true
        self.backgroundColor = ThemeColor.cellBgColor
        self.isOpaque = true
        self.selectionStyle = .none
        
        self.nameLabel.textColor = ThemeColor.nameColor
        self.nameLabel.font = UIFont.boldSystemFont(ofSize: SettingsData.fontSize + 2)
        self.nameLabel.backgroundColor = ThemeColor.cellBgColor
        self.nameLabel.isOpaque = true
        
        self.editButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
        self.editButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        self.editButton.setTitle(I18n.get("BUTTON_EDIT"), for: .normal)
        self.editButton.backgroundColor = ThemeColor.mainButtonsBgColor
        self.editButton.layer.cornerRadius = 10
        self.editButton.clipsToBounds = true
        self.editButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        self.editButton.layer.borderWidth = 1
        
        self.lineLayer.backgroundColor = ThemeColor.separatorColor.cgColor
        self.lineLayer.isOpaque = true
    }
    
    // 編集
    @objc func editButtonAction() {
        let vc = ListEditViewController(name: self.nameLabel.text, id: self.id)
        if let rootVc = UIUtils.getFrontViewController() {
            rootVc.addChildViewController(vc)
            rootVc.view.addSubview(vc.view)
            
            vc.view.frame.origin.x = UIScreen.main.bounds.width
            UIView.animate(withDuration: 0.3) {
                vc.view.frame.origin.x = 0
            }
        }
    }
    
    override func layoutSubviews() {
        let screenBounds = UIScreen.main.bounds
        
        self.lineLayer.frame = CGRect(x: 0,
                                      y: 52 - 1 / UIScreen.main.scale,
                                      width: screenBounds.width,
                                      height: 1 / UIScreen.main.scale)
        
        self.nameLabel.frame = CGRect(x: 20,
                                      y: 26 - SettingsData.fontSize / 2,
                                      width: screenBounds.width - 100,
                                      height: SettingsData.fontSize + 1)
        
        self.editButton.frame = CGRect(x: screenBounds.width - 80,
                                             y: 8,
                                             width: 60,
                                             height: 36)
        
    }
}
