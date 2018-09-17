//
//  TimeLineViewCell.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/17.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// トゥートの内容を表示するセル

import UIKit

final class TimeLineViewCell: UITableViewCell {
    static let bgColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
    var id = ""
    let lineLayer = CALayer()
    let iconView = UIImageView()
    let nameLabel = UILabel()
    let idLabel = UILabel()
    let dateLabel = UILabel()
    var messageView: UIView?
    var continueView: UILabel?
    var boostView: UILabel?
    var imageViews: [UIImageView]?
    weak var tableView: UITableView?
    var indexPath: IndexPath?
    
    // セルの初期化
    init(reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        
        // デフォルトのテキストァベルは不要
        self.textLabel?.removeFromSuperview()
        self.detailTextLabel?.removeFromSuperview()
        
        // 固定プロパティは初期化時に設定
        self.clipsToBounds = true
        self.backgroundColor = TimeLineViewCell.bgColor
        self.isOpaque = true
        
        self.iconView.layer.cornerRadius = 5
        self.iconView.clipsToBounds = true
        
        self.nameLabel.textColor = UIColor(red: 0.2, green: 0.3, blue: 1.0, alpha: 1)
        self.nameLabel.font = UIFont.boldSystemFont(ofSize: 14)
        self.nameLabel.backgroundColor = TimeLineViewCell.bgColor
        self.nameLabel.isOpaque = true
        
        self.idLabel.font = UIFont.systemFont(ofSize: 12)
        self.idLabel.backgroundColor = TimeLineViewCell.bgColor
        self.idLabel.isOpaque = true
        
        self.dateLabel.textColor = UIColor.darkGray
        self.dateLabel.font = UIFont.systemFont(ofSize: 12)
        self.dateLabel.textAlignment = .right
        self.dateLabel.backgroundColor = TimeLineViewCell.bgColor
        self.dateLabel.isOpaque = true
        
        self.lineLayer.backgroundColor = UIColor.lightGray.cgColor
        self.lineLayer.isOpaque = true
        
        // addする
        self.addSubview(self.iconView)
        self.addSubview(self.nameLabel)
        self.addSubview(self.idLabel)
        self.addSubview(self.dateLabel)
        self.layer.addSublayer(self.lineLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // セル内のレイアウト
    override func layoutSubviews() {
        let screenBounds = UIScreen.main.bounds
        
        self.lineLayer.frame = CGRect(x: 0,
                                      y: 0,
                                      width: screenBounds.width,
                                      height: 1 / UIScreen.main.scale)
        
        self.iconView.frame = CGRect(x: 8,
                                     y: 10,
                                     width: 36,
                                     height: 36)
        
        self.nameLabel.frame = CGRect(x: 50,
                                      y: 7,
                                      width: self.nameLabel.frame.width,
                                      height: 16)
        
        self.idLabel.frame = CGRect(x: 50 + self.nameLabel.frame.width + 5,
                                    y: 7,
                                    width: screenBounds.width - (self.nameLabel.frame.width + 50 + 5 + 50 + 5),
                                    height: 16)
        
        self.dateLabel.frame = CGRect(x: screenBounds.width - 50,
                                      y: 7,
                                      width: 45,
                                      height: 16)
        
        self.messageView?.frame = CGRect(x: 50,
                                         y: 19,
                                         width: self.messageView?.frame.width ?? 0,
                                         height: self.messageView?.frame.height ?? 0)
        
        self.continueView?.frame = CGRect(x: screenBounds.width / 2 - 40 / 2,
                                          y: (self.messageView?.frame.maxY ?? 0) - 6,
                                          width: 40,
                                          height: 18)
        
        let imagesOffset = CGFloat((self.imageViews?.count ?? 0) * 90)
        self.boostView?.frame = CGRect(x: 40,
                                       y: (self.messageView?.frame.maxY ?? 0) + 8 + imagesOffset,
                                       width: screenBounds.width - 56,
                                       height: 20)
        
        for (index, imageView) in (self.imageViews ?? []).enumerated() {
            var imageWidth: CGFloat = 0
            var imageHeight: CGFloat = 80
            if let image = imageView.image {
                let size = image.size
                let rate = 80 / size.height
                imageWidth = size.width * rate
                if imageWidth > screenBounds.width - 50 {
                    imageWidth = screenBounds.width - 50
                    let newRate = imageWidth / size.width
                    imageHeight = size.height * newRate
                }
            }
            imageView.frame = CGRect(x: 50,
                                     y: (self.messageView?.frame.maxY ?? 0) + 90 * CGFloat(index),
                                     width: imageWidth,
                                     height: imageHeight)
        }
    }
}
