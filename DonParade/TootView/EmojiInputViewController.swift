//
//  EmojiInputViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/21.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 絵文字入力用のビューを表示する
//  カスタムキーボードにしなかったのは、Mac向けに利用することを考慮したため

import UIKit

final class EmojiInputViewController: UIViewController {
    private var emojiList: [EmojiData.EmojiStruct] = []
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        self.emojiList = EmojiData.getEmojiCache(host: SettingsData.hostName!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = EmojiInputView()
    }
}

private final class EmojiInputView: UIView {
    let returnButton = UIButton()
    let deleteButton = UIButton()
    let scrollView = EmojiInputScrollView()
    
}

private final class EmojiInputScrollView: UIScrollView {
    var emojiButtons: [UIButton] = []
}
