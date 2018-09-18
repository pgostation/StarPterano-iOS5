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
    private var list: [AnalyzeJson.ContentData] = []
    private var accountList: [String: AnalyzeJson.AccountData] = [:]
    private var showGrowlCell = true // 過去遡り用セルを表示するかどうか
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 一番新しいトゥートのID
    func getFirstTootId() -> String? {
        return list.first?.id
    }
    
    // トゥートの追加
    func change(tableView: UITableView, addList: [AnalyzeJson.ContentData], accountList: [String: AnalyzeJson.AccountData]) {
        DispatchQueue.main.async {
            if let date1 = self.list.first?.created_at, let date2 = addList.first?.created_at {
                if date1 > date2 {
                    self.list = self.list + addList
                } else {
                    self.list = addList + self.list
                }
            } else {
                self.list = addList + self.list
            }
            
            // アカウント情報を更新
            for account in accountList {
                self.accountList.updateValue(account.value, forKey: account.key)
            }
            
            tableView.reloadData()
        }
    }
    
    // セルの数
    private var isFirstView = true
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if list.count == 0, isFirstView {
            isFirstView = false
            if let timelineView = tableView as? TimeLineView {
                timelineView.refresh()
            }
        }
        
        return list.count + (showGrowlCell ? 1 : 0)
    }
    
    // セルのだいたいの高さ(スクロールバーの表示用)
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    // セルの正確な高さ
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == list.count {
            // Growl用セルの高さ
            return 55
        }
        
        // メッセージのビューを一度作り、高さを求める
        let (messageView, data, _) = getMessageViewAndData(indexPath: indexPath, callback: nil)
        
        let imagesOffset: CGFloat
        if let mediaData = data.mediaData {
            imagesOffset = 90 * CGFloat(mediaData.count)
        } else {
            imagesOffset = 0
        }
        
        if data.reblog_acct != nil {
            return max(55, messageView.frame.height + 28 + 20 + imagesOffset)
        } else {
            return max(55, messageView.frame.height + 28 + imagesOffset)
        }
    }
    
    // メッセージのビューとデータを返す
    private func getMessageViewAndData(indexPath: IndexPath, callback: (()->Void)?) -> (UIView, AnalyzeJson.ContentData, Bool) {
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
        if indexPath.row >= list.count {
            if self.showGrowlCell, let timelineView = tableView as? TimeLineView {
                // 過去のトゥートに遡る
                timelineView.refreshOld(id: list.last?.id)
            }
            return getCell(view: tableView, height: 55)
        }
        
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
        
        ImageCache.image(urlStr: account?.avatar_static, isTemp: false) { image in
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
            cell.date = date
            cell.refreshDate()
        }
        
        // 画像や動画ありの場合
        if let mediaData = data.mediaData {
            cell.imageViews = []
            
            for media in mediaData {
                let imageView = UIImageView()
                ImageCache.image(urlStr: media.preview_url, isTemp: true) { image in
                    imageView.image = image
                    cell.setNeedsLayout()
                }
                cell.addSubview(imageView)
                cell.imageViews?.append(imageView)
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
        for imageView in cell.imageViews ?? [] {
            imageView.removeFromSuperview()
        }
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
