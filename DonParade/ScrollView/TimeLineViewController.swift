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
            closeButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
            closeButton.backgroundColor = ThemeColor.mainButtonsBgColor
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
            
            if SettingsData.accountList.count >= 2 {
                // 右スワイプで前へ
                let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(rightAction))
                rightSwipeGesture.direction = .right
                self.view?.addGestureRecognizer(rightSwipeGesture)
                // 左スワイプで次へ
                let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(leftAction))
                leftSwipeGesture.direction = .left
                self.view?.addGestureRecognizer(leftSwipeGesture)
            }
        }
        
        // ピンチインでミニビューへ
        let pinchInGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchAction(_:)))
        self.view?.addGestureRecognizer(pinchInGesture)
    }
    
    // ユーザータイムライン/詳細トゥートを閉じる
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
    
    // スワイプで次へ
    @objc func leftAction() {
        let newIndex = (getIndexOfAccountList() + 1) % SettingsData.accountList.count
        
        let moveToAccount = SettingsData.accountList[newIndex]
        
        moveTo(moveToAccount: moveToAccount, toRight: false)
    }
    
    // スワイプで前へ
    @objc func rightAction() {
        let newIndex = (getIndexOfAccountList() + SettingsData.accountList.count - 1) % SettingsData.accountList.count
        
        let moveToAccount = SettingsData.accountList[newIndex]
        
        moveTo(moveToAccount: moveToAccount, toRight: true)
    }
    
    private func moveTo(moveToAccount: (String, String), toRight: Bool) {
        SettingsData.hostName = moveToAccount.0
        SettingsData.accessToken = moveToAccount.1
        
        MainViewController.instance?.swipeView(toRight: toRight)
    }
    
    // 現在のタイムライン画面に対応するアカウントの番号を返す
    private func getIndexOfAccountList() -> Int {
        let list = SettingsData.accountList
        
        for (index, data) in list.enumerated() {
            if SettingsData.hostName == data.0 && SettingsData.accessToken == data.1 {
                return index
            }
        }
        
        return 0
    }
    
    // ピンチインでミニビューへ
    @objc func pinchAction(_ gesture: UIPinchGestureRecognizer) {
        guard let view = self.view as? TimeLineView else { return }
        
        if gesture.scale < 0.9 {
            view.enterMiniView()
        } else if gesture.scale > 1.1 {
            view.exitMiniView()
        }
    }
}
