//
//  TimeLineViewModel.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/17.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 各種タイムラインやお気に入りなどのデータを保持し、テーブルビューのセルに表示する

import UIKit

final class TimeLineViewModel: NSObject, UITableViewDataSource, UITableViewDelegate {
    private var list: [TimeLineView.ContentData] = []
    private var accountList: [String: TimeLineView.AccountData] = [:]
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // トゥートの追加
    func change(tableView: UITableView, addList: [TimeLineView.ContentData], accountList: [String: TimeLineView.AccountData]) {
        DispatchQueue.main.async {
            self.list += addList
            
            self.accountList = accountList
            
            tableView.reloadData()
        }
    }
    
    // セルの数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    // セルのだいたいの高さ(スクロールバーの表示用)
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    // セルの正確な高さ
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // メッセージのビューを一度作り、高さを求める
        let (messageView, _, _) = getMessageViewAndData(indexPath: indexPath, callback: nil)
        
        return max(55, messageView.frame.height + 28)
    }
    
    // メッセージのビューとデータを返す
    private func getMessageViewAndData(indexPath: IndexPath, callback: (()->Void)?) -> (UILabel, TimeLineView.ContentData, Bool) {
        let data = list[indexPath.row]
        
        // content解析
        let attributedText = AnalyzeToot.analyzeContent(content: data.content, emojis: data.emojis, callback: callback)
        
        // 行間を広げる
        let paragrahStyle = NSMutableParagraphStyle()
        paragrahStyle.minimumLineHeight = 24
        paragrahStyle.maximumLineHeight = 24
        attributedText.addAttributes([NSAttributedStringKey.paragraphStyle : paragrahStyle],
                                     range: NSMakeRange(0, attributedText.length))
        
        // プロパティ設定
        let messageView = UILabel()
        messageView.attributedText = attributedText
        messageView.font = UIFont.systemFont(ofSize: 14)
        messageView.numberOfLines = 0
        messageView.lineBreakMode = .byCharWrapping
        messageView.backgroundColor = TimeLineViewCell.bgColor
        messageView.isOpaque = true
        
        // ビューの高さを決める
        messageView.frame.size.width = UIScreen.main.bounds.width - 66
        messageView.sizeToFit()
        var isContinue = false
        if messageView.frame.size.height >= 140 - 28 {
            messageView.frame.size.height = 140 - 28
            isContinue = true
        }
        
        return (messageView, data, isContinue)
    }
    
    // セルを返す
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row >= list.count { return getCell(view: tableView, height: 55) }
        
        var cell: TimeLineViewCell! = nil
        var id: String = ""
        
        let (messageView, data, isContinue) = getMessageViewAndData(indexPath: indexPath, callback: { [weak self] in
            if cell.id == id {
                if let (messageView, _, _) = self?.getMessageViewAndData(indexPath: indexPath, callback: nil) {
                    cell?.messageView?.removeFromSuperview()
                    cell?.messageView = messageView
                    cell?.insertSubview(messageView, at: 0)
                }
            }
        })
        let account = accountList[data.accountId]
        
        cell = getCell(view: tableView, height: max(55, messageView.frame.height + 28))
        cell.id = data.content ?? ""
        id = data.content ?? ""
        
        ImageCache.image(urlStr: account?.avatar_static) { image in
            cell.iconView.image = image
        }
        
        cell.messageView = messageView
        cell.insertSubview(messageView, at: 0)
        
        cell.nameLabel.attributedText = AnalyzeToot.analyzeName(name: account?.display_name ?? "", emojis: account?.emojis, callback: {
            if cell.id == id {
                cell.nameLabel.attributedText = AnalyzeToot.analyzeName(name: account?.display_name ?? "", emojis: account?.emojis, callback: nil)
                cell?.setNeedsLayout()
            }
        })
        cell.nameLabel.sizeToFit()
        
        cell.idLabel.text = account?.acct
        cell.idLabel.sizeToFit()
        
        cell.dateLabel.text = data.created_at
        
        if isContinue {
            cell.continueView = UILabel()
            cell.continueView?.font = UIFont.systemFont(ofSize: 14)
            cell.continueView?.text = "🔻"
            cell.continueView?.textAlignment = .center
            cell.addSubview(cell.continueView!)
        }
        
        return cell
    }
    
    // セルを使い回す
    private func getCell(view: UITableView, height: CGFloat) -> TimeLineViewCell {
        let reuseIdentifier = "TimeLineViewModel\(height)"
        let cell = view.dequeueReusableCell(withIdentifier: reuseIdentifier) as? TimeLineViewCell ?? TimeLineViewCell(reuseIdentifier: reuseIdentifier)
        
        cell.messageView?.removeFromSuperview()
        cell.continueView?.removeFromSuperview()
        cell.iconView.image = nil
        
        return cell
    }
}

final class TimeLineViewCell: UITableViewCell {
    static let bgColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
    var id = ""
    let lineLayer = CALayer()
    let iconView = UIImageView()
    let nameLabel = UILabel()
    let idLabel = UILabel()
    let dateLabel = UILabel()
    var messageView: UILabel?
    var continueView: UILabel?
    
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
                                    width: screenBounds.width - (self.nameLabel.frame.width + 50 + 5 + 60 + 5),
                                    height: 16)
        
        self.dateLabel.frame = CGRect(x: screenBounds.width - 60,
                                      y: 7,
                                      width: 60,
                                      height: 16)
        
        self.messageView?.frame = CGRect(x: 50,
                                         y: 19,
                                         width: self.messageView?.frame.width ?? 0,
                                         height: self.messageView?.frame.height ?? 0)
        
        self.continueView?.frame = CGRect(x: screenBounds.width / 2 - 40 / 2,
                                          y: (self.messageView?.frame.maxY ?? 0) - 6,
                                          width: 40,
                                          height: 18)
    }
}
