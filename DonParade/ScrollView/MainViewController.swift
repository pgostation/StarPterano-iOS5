//
//  MainViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/15.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// TLやLTLなどへの切り替え機能を持った、メイン画面となるビューコントローラー

import UIKit

final class MainViewController: MyViewController {
    static weak var instance: MainViewController?
    
    override func loadView() {
        MainViewController.instance = self
        
        // 共通部分のビュー
        let view = MainView()
        self.view = view
        
        view.tlButton.addTarget(self, action: #selector(tlAction(_:)), for: .touchUpInside)
        view.ltlButton.addTarget(self, action: #selector(ltlAction(_:)), for: .touchUpInside)
        
        // 起動時はTLを表示する
        tlAction(nil)
    }
    
    private var timelineViewController: TimeLineViewController?
    
    // タイムラインへの切り替え
    @objc func tlAction(_ sender: UIButton?) {
        // 前のビューを外す
        removeOldView()
        
        // 一番下にタイムラインビューを入れる
        self.timelineViewController = TimeLineViewController(type: .home)
        self.addChildViewController(self.timelineViewController!)
        self.view.insertSubview(self.timelineViewController!.view, at: 0)
    }
    
    // LTLへの切り替え
    @objc func ltlAction(_ sender: UIButton?) {
        // 前のビューを外す
        removeOldView()
        
        // 一番下にタイムラインビューを入れる
        self.timelineViewController = TimeLineViewController(type: .local)
        self.addChildViewController(self.timelineViewController!)
        self.view.insertSubview(self.timelineViewController!.view, at: 0)
    }
    
    // 前のビューを外す
    private func removeOldView() {
        if let oldViewController = self.timelineViewController {
            oldViewController.removeFromParentViewController()
            oldViewController.view.removeFromSuperview()
        }
    }
}

private final class MainView: UIView {
    let tlButton = UIButton()
    let ltlButton = UIButton()
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        
        self.addSubview(tlButton)
        self.addSubview(ltlButton)
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.backgroundColor = UIColor.white
        
        tlButton.setTitle(I18n.get("BUTTON_TL"), for: .normal)
        tlButton.backgroundColor = UIColor.lightGray
        tlButton.setTitleColor(UIColor.blue, for: .normal)
        
        ltlButton.setTitle(I18n.get("BUTTON_LTL"), for: .normal)
        ltlButton.backgroundColor = UIColor.lightGray
        ltlButton.setTitleColor(UIColor.blue, for: .normal)
    }
    
    override func layoutSubviews() {
        let screenBounds = UIScreen.main.bounds
        let bottomOffset: CGFloat = UIUtils.isIphoneX ? 50 : 0
        let buttonWidth: CGFloat = 80
        let buttonHeight: CGFloat = 40
        
        tlButton.frame = CGRect(x: 0,
                                  y: screenBounds.height - 100 - bottomOffset,
                                  width: buttonWidth,
                                  height: buttonHeight)
        
        ltlButton.frame = CGRect(x: 0,
                                       y: screenBounds.height - 50 - bottomOffset,
                                       width: buttonWidth,
                                       height: buttonHeight)
    }
}
