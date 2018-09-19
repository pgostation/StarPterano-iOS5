//
//  TimeLineViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/15.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 各種タイムラインやお気に入りなどを表示するViewController

import UIKit

final class TimeLineViewController: MyViewController {
    enum TimeLineType {
        case home // ホーム
        case local // ローカルタイムライン
        case global // 連合タイムライン
        case user // 指定ユーザータイムライン
        case favorites // お気に入り
        case localTag
        case globalTag
        case mensions // 単一トゥート(と会話)
        // 会話の場合、@の相手全てのTimelineを取得して表示する。まず過去、それから未来。関係ないのは非表示
    }
    
    private let type: TimeLineType
    private let option: String? // user指定時はユーザID、タグ指定時はタグ
    private let mensions: ([AnalyzeJson.ContentData], [String: AnalyzeJson.AccountData])? // typeに.mensions指定時のみ有効
    
    init(type: TimeLineType, option: String? = nil, mensions: ([AnalyzeJson.ContentData], [String: AnalyzeJson.AccountData])? = nil) {
        self.type = type
        self.option = option
        self.mensions = mensions
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        if self.type == .user || self.type == .mensions {
            let view = TimeLineView(type: self.type, option: self.option, mensions: mensions)
            self.view = view
                
            let closeButton = UIButton()
            closeButton.setTitle("CLOSE", for: .normal)
            closeButton.setTitleColor(UIColor.blue, for: .normal)
            closeButton.backgroundColor = UIColor.lightGray
            closeButton.frame = CGRect(x: UIScreen.main.bounds.width / 2 - 50 / 2,
                                       y: UIScreen.main.bounds.height - 70,
                                       width: 50,
                                       height: 50)
            closeButton.addTarget(self, action: #selector(self.closeAction), for: .touchUpInside)
            self.view?.addSubview(closeButton)
            
            // 右スワイプで閉じる
            let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(closeAction))
            swipeGesture.direction = .right
            self.view?.addGestureRecognizer(swipeGesture)
        } else {
            let view = TimeLineView(type: self.type, option: self.option, mensions: mensions)
            self.view = view
        }
    }
    
    @objc func closeAction() {
        UIView.animate(withDuration: 0.3, animations: {
            self.view.frame = CGRect(x: UIScreen.main.bounds.width,
                                     y: 0,
                                     width: UIScreen.main.bounds.width,
                                     height: UIScreen.main.bounds.height)
        }, completion: { _ in
            self.removeFromParentViewController()
            self.view.removeFromSuperview()
        })
    }
}
