//
//  ListEditTableViewCell.swift
//  DonParade
//
//  Created by takayoshi on 2018/10/04.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit

final class ListEditTableViewCell: UITableViewCell {
    var listId = ""
    var id = ""
    
    // 基本ビュー
    let lineLayer = CALayer()
    let iconView = UIImageView()
    let nameLabel = UILabel()
    let idLabel = UILabel()
    let addButton = UIButton()
    let removeButton = UIButton()
    
    init(reuseIdentifier: String?) {
        super.init(style: UITableViewCell.CellStyle.default, reuseIdentifier: reuseIdentifier)
        
        // デフォルトのビューは不要
        self.textLabel?.removeFromSuperview()
        self.detailTextLabel?.removeFromSuperview()
        self.imageView?.removeFromSuperview()
        self.contentView.removeFromSuperview()
        
        self.addSubview(iconView)
        self.addSubview(nameLabel)
        self.addSubview(idLabel)
        self.addSubview(removeButton)
        self.addSubview(addButton)
        self.layer.addSublayer(self.lineLayer)
        
        removeButton.addTarget(self, action: #selector(removeButtonAction), for: .touchUpInside)
        addButton.addTarget(self, action: #selector(addButtonAction), for: .touchUpInside)
        
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
        
        self.idLabel.textColor = ThemeColor.idColor
        self.idLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
        self.idLabel.backgroundColor = ThemeColor.cellBgColor
        self.idLabel.isOpaque = true
        
        self.removeButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
        self.removeButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        self.removeButton.setTitle("-", for: .normal)
        self.removeButton.backgroundColor = ThemeColor.mainButtonsBgColor
        self.removeButton.layer.cornerRadius = 10
        self.removeButton.clipsToBounds = true
        self.removeButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        self.removeButton.layer.borderWidth = 1
        
        self.addButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
        self.addButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        self.addButton.setTitle("+", for: .normal)
        self.addButton.backgroundColor = ThemeColor.mainButtonsBgColor
        self.addButton.layer.cornerRadius = 10
        self.addButton.clipsToBounds = true
        self.addButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        self.addButton.layer.borderWidth = 1
        
        self.lineLayer.backgroundColor = ThemeColor.separatorColor.cgColor
        self.lineLayer.isOpaque = true
    }
    
    // 追加
    @objc func addButtonAction() {
        self.addButton.isHidden = true
        
        guard let hostName = SettingsData.hostName else { return }
        
        let url = URL(string: "https://\(hostName)/api/v1/lists/\(self.listId)/accounts")!
        
        try? MastodonRequest.post(url: url, body: ["account_ids": ["\(self.id)"]]) { (data, response, error) in
        }
    }
    
    // 削除
    @objc func removeButtonAction() {
        Dialog.show(message: I18n.get("DIALOG_REMOVE_FROM_LIST"),
                    okName: I18n.get("BUTTON_REMOVE"),
                    cancelName: I18n.get("BUTTON_CANCEL")) { (result) in
                        if result {
                            self.removeButton.isHidden = true
                            
                            guard let hostName = SettingsData.hostName else { return }
                            
                            let url = URL(string: "https://\(hostName)/api/v1/lists/\(self.listId)/accounts")!
                            
                            try? MastodonRequest.delete(url: url, body: ["account_ids": ["\(self.id)"]]) { (data, response, error) in
                            }
                        }
        }
        
    }
    
    override func layoutSubviews() {
        let screenBounds = UIScreen.main.bounds
        
        self.lineLayer.frame = CGRect(x: 0,
                                      y: 52 - 1 / UIScreen.main.scale,
                                      width: screenBounds.width,
                                      height: 1 / UIScreen.main.scale)
        
        self.iconView.frame = CGRect(x: (52 - SettingsData.iconSize) / 2,
                                     y: (52 - SettingsData.iconSize) / 2,
                                     width: SettingsData.iconSize,
                                     height: SettingsData.iconSize)
        
        self.nameLabel.frame = CGRect(x: 52,
                                      y: max(0, 26 - SettingsData.fontSize),
                                      width: screenBounds.width - 52 - 60,
                                      height: SettingsData.fontSize + 2)
        
        self.idLabel.frame = CGRect(x: 52,
                                    y: 26 + ((26 - SettingsData.fontSize) / 2),
                                    width: screenBounds.width - 52 - 60,
                                    height: SettingsData.fontSize)
        
        self.removeButton.frame = CGRect(x: screenBounds.width - 60,
                                         y: 6,
                                         width: 40,
                                         height: 40)
        
        self.addButton.frame = CGRect(x: screenBounds.width - 60,
                                      y: 6,
                                      width: 40,
                                      height: 40)
        
    }
}
