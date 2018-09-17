//
//  TimeLineViewModel.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/17.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 各種タイムラインやお気に入りなどのデータを保持し、テーブルビューのセルに表示する

import UIKit
import SafariServices

final class TimeLineViewModel: NSObject, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
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
            self.list = addList + self.list
            
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
        let (messageView, data, _) = getMessageViewAndData(indexPath: indexPath, callback: nil)
        
        if data.reblog_acct != nil {
            return max(55, messageView.frame.height + 28 + 20)
        } else {
            return max(55, messageView.frame.height + 28)
        }
    }
    
    // メッセージのビューとデータを返す
    private func getMessageViewAndData(indexPath: IndexPath, callback: (()->Void)?) -> (UIView, TimeLineView.ContentData, Bool) {
        let data = list[indexPath.row]
        
        // content解析
        let (attributedText, hasLink) = DecodeToot.decodeContent(content: data.content, emojis: data.emojis, callback: callback)
        
        // 行間を広げる
        let paragrahStyle = NSMutableParagraphStyle()
        paragrahStyle.minimumLineHeight = 24
        paragrahStyle.maximumLineHeight = 24
        attributedText.addAttributes([NSAttributedStringKey.paragraphStyle : paragrahStyle],
                                     range: NSMakeRange(0, attributedText.length))
        
        // プロパティ設定
        let messageView: UIView
        if hasLink {
            let msgView = UITextView()
            msgView.attributedText = attributedText
            msgView.font = UIFont.systemFont(ofSize: 14)
            msgView.backgroundColor = TimeLineViewCell.bgColor
            msgView.textContainer.lineBreakMode = .byCharWrapping
            msgView.isOpaque = true
            msgView.isScrollEnabled = false
            msgView.isEditable = false
            msgView.delegate = self // URLタップ用
            
            // URL以外の場所タップ用
            let tapGensture = UITapGestureRecognizer.init(target: self, action: #selector(tapTextViewAction(_:)))
            msgView.addGestureRecognizer(tapGensture)
            
            messageView = msgView
        } else {
            let msgView = UILabel()
            msgView.attributedText = attributedText
            msgView.font = UIFont.systemFont(ofSize: 14)
            msgView.numberOfLines = 0
            msgView.lineBreakMode = .byCharWrapping
            msgView.backgroundColor = TimeLineViewCell.bgColor
            msgView.isOpaque = true
            messageView = msgView
        }
        
        // ビューの高さを決める
        messageView.frame.size.width = UIScreen.main.bounds.width - 66
        messageView.sizeToFit()
        var isContinue = false
        if messageView.frame.size.height >= 180 - 28 {
            messageView.frame.size.height = 180 - 28
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
                    cell?.insertSubview(messageView, at: 2)
                }
            }
        })
        let account = accountList[data.accountId]
        
        cell = getCell(view: tableView, height: max(55, messageView.frame.height + 28))
        cell.id = data.content ?? ""
        id = data.content ?? ""
        cell.tableView = tableView
        cell.indexPath = indexPath
        
        ImageCache.image(urlStr: account?.avatar_static) { image in
            cell.iconView.image = image
        }
        
        cell.messageView = messageView
        cell.insertSubview(messageView, at: 2)
        
        cell.nameLabel.attributedText = DecodeToot.decodeName(name: account?.display_name ?? "", emojis: account?.emojis, callback: {
            if cell.id == id {
                cell.nameLabel.attributedText = DecodeToot.decodeName(name: account?.display_name ?? "", emojis: account?.emojis, callback: nil)
                cell?.setNeedsLayout()
            }
        })
        cell.nameLabel.sizeToFit()
        
        cell.idLabel.text = account?.acct
        cell.idLabel.sizeToFit()
        
        if let created_at = data.created_at {
            let date = DecodeToot.decodeTime(text: created_at)
            let diffTime = Int(Date().timeIntervalSince(date))
            if diffTime <= 0 {
                cell.dateLabel.text = I18n.get("DATETIME_NOW")
            }
            else if diffTime < 60 {
                cell.dateLabel.text = String(format: I18n.get("DATETIME_%D_SECS_AGO"), diffTime)
            }
            else if diffTime / 60 < 60 {
                cell.dateLabel.text = String(format: I18n.get("DATETIME_%D_MINS_AGO"), diffTime / 60)
            }
            else if diffTime / 3600 < 24 {
                cell.dateLabel.text = String(format: I18n.get("DATETIME_%D_HOURS_AGO"), diffTime / 3600)
            }
            else if diffTime / 86400 < 365 {
                cell.dateLabel.text = String(format: I18n.get("DATETIME_%D_DAYS_AGO"), diffTime / 86400)
            }
            else {
                cell.dateLabel.text = String(format: I18n.get("DATETIME_%D_YEARS_AGO"), diffTime / 86400 / 365)
            }
        }
        
        // 長すぎて省略している場合
        if isContinue {
            cell.continueView = UILabel()
            cell.continueView?.font = UIFont.systemFont(ofSize: 14)
            cell.continueView?.text = "🔻"
            cell.continueView?.textAlignment = .center
            cell.addSubview(cell.continueView!)
        }
        
        // ブーストの場合
        if let reblog_acct = data.reblog_acct {
            let account = accountList[reblog_acct]
            cell.boostView = UILabel()
            cell.boostView?.font = UIFont.systemFont(ofSize: 12)
            cell.boostView?.textColor = UIColor.darkGray
            cell.boostView?.text = String(format: I18n.get("BOOSTED_BY_%@"), account?.display_name ?? "")
            cell.addSubview(cell.boostView!)
        }
        
        return cell
    }
    
    // セルを使い回す
    private func getCell(view: UITableView, height: CGFloat) -> TimeLineViewCell {
        let reuseIdentifier = "TimeLineViewModel\(height)"
        let cell = view.dequeueReusableCell(withIdentifier: reuseIdentifier) as? TimeLineViewCell ?? TimeLineViewCell(reuseIdentifier: reuseIdentifier)
        
        cell.messageView?.removeFromSuperview()
        cell.continueView?.removeFromSuperview()
        cell.boostView?.removeFromSuperview()
        cell.iconView.image = nil
        
        return cell
    }
    
    // セル選択時の処理
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // トゥート詳細画面
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // UITextViewのリンクタップ時の処理
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        let controller = SFSafariViewController(url: URL)
        MainViewController.instance?.present(controller, animated: true)
        
        return false
    }
    
    // UITextViewのリンク以外タップ時の処理
    @objc func tapTextViewAction(_ gesture: UIGestureRecognizer) {
        guard let msgView = gesture.view else { return }
        guard let cell = msgView.superview as? TimeLineViewCell else { return }
        
        if let tableView = cell.tableView, let indexPath = cell.indexPath {
            // セル選択時の処理を実行
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
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
    var messageView: UIView?
    var continueView: UILabel?
    var boostView: UILabel?
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
        
        self.boostView?.frame = CGRect(x: 40,
                                       y: (self.messageView?.frame.maxY ?? 0) + 8,
                                       width: screenBounds.width - 56,
                                       height: 20)
    }
}
