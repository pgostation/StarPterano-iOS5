//
//  SearchViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/23.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 検索画面

import UIKit

final class SearchViewController: MyViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = SearchView()
        self.view = view
        
        view.closeButton.addTarget(self, action: #selector(self.closeAction), for: .touchUpInside)
        
        // 右スワイプで閉じる
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(closeAction))
        swipeGesture.direction = .right
        self.view?.addGestureRecognizer(swipeGesture)
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

private final class SearchView: UIView {
    let closeButton = UIButton()
    let segmentControl = UISegmentedControl()
    let textField = UITextField()
    let tableView = SearchTableView()
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        
        self.addSubview(tableView)
        self.addSubview(segmentControl)
        self.addSubview(textField)
        self.addSubview(closeButton)
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.backgroundColor = ThemeColor.viewBgColor
        
        // アカウント/トゥートの切り替え
        // セグメントコントロール
        segmentControl.insertSegment(withTitle: I18n.get("SEARCH_SEG_TOOT"), at: 0, animated: false)
        segmentControl.insertSegment(withTitle: I18n.get("SEARCH_SEG_ACCOUNT"), at: 1, animated: false)
        segmentControl.selectedSegmentIndex = 0
        segmentControl.tintColor = ThemeColor.mainButtonsTitleColor
        segmentControl.backgroundColor = ThemeColor.cellBgColor
        
        // 検索文字列入力フィールド
        textField.backgroundColor = ThemeColor.cellBgColor
        textField.borderStyle = .line
        textField.layer.borderWidth = 1
        textField.layer.borderColor = ThemeColor.dateColor.cgColor
        
        // 閉じるボタン
        closeButton.setTitle("×", for: .normal)
        closeButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        closeButton.backgroundColor = ThemeColor.mainButtonsBgColor
        closeButton.layer.cornerRadius = 10
        closeButton.clipsToBounds = true
        closeButton.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        closeButton.layer.borderWidth = 1
    }
    
    override func layoutSubviews() {
        segmentControl.frame = CGRect(x: UIScreen.main.bounds.width / 2 - 180 / 2,
                                      y: UIUtils.statusBarHeight() + 1,
                                      width: 180,
                                      height: 40)
        
        textField.frame = CGRect(x: 5,
                                 y: segmentControl.frame.maxY + 2,
                                 width: UIScreen.main.bounds.width - 10,
                                 height: 50)
        
        closeButton.frame = CGRect(x: UIScreen.main.bounds.width / 2 - 50 / 2,
                                   y: UIScreen.main.bounds.height - 70,
                                   width: 50,
                                   height: 50)
        
        tableView.frame = CGRect(x: 0,
                                 y: textField.frame.maxY + 2,
                                 width: UIScreen.main.bounds.width,
                                 height: UIScreen.main.bounds.height - (textField.frame.maxY + 2))
    }
}

private final class SearchTableView: UIView {
    let model = SearchTableViewModel()
}

private final class SearchTableViewModel: UIView {
}
