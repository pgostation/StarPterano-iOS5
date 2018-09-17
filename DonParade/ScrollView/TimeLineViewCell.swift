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
    var date: Date
    var timer: Timer?
    
    // セルの初期化
    init(reuseIdentifier: String?) {
        self.date = Date()
        
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
        
        // タイマーで5秒ごとに時刻を更新
        if #available(iOS 10.0, *) {
            self.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { [weak self] timer in
                if self?.superview == nil {
                    return
                }
                
                self?.refreshDate()
            })
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 日時表示を更新
    func refreshDate() {
        let diffTime = Int(Date().timeIntervalSince(self.date))
        if diffTime <= 0 {
            self.dateLabel.text = I18n.get("DATETIME_NOW")
        }
        else if diffTime < 60 {
            self.dateLabel.text = String(format: I18n.get("DATETIME_%D_SECS_AGO"), diffTime)
        }
        else if diffTime / 60 < 60 {
            self.dateLabel.text = String(format: I18n.get("DATETIME_%D_MINS_AGO"), diffTime / 60)
        }
        else if diffTime / 3600 < 24 {
            self.dateLabel.text = String(format: I18n.get("DATETIME_%D_HOURS_AGO"), diffTime / 3600)
        }
        else if diffTime / 86400 < 365 {
            self.dateLabel.text = String(format: I18n.get("DATETIME_%D_DAYS_AGO"), diffTime / 86400)
        }
        else {
            self.dateLabel.text = String(format: I18n.get("DATETIME_%D_YEARS_AGO"), diffTime / 86400 / 365)
        }
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
