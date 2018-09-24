//
//  ProfileViewCell.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/24.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 個人タイムラインの上に表示されるプロフィール欄
//  ここにプロフィールが表示され、フォローしたりブロックやミュートできる

import UIKit

final class ProfileViewCell: UITableViewCell {
    // 背景
    let headerImageView = UIImageView()
    
    // メインの表示
    let iconView = UIImageView()
    let nameLabel = UILabel()
    let idLabel = UILabel()
    let noteLabel = UILabel()
    let dateLabel = UILabel()
    let urlLabel = UILabel()
    
    // 追加分の表示
    var serviceLabels: [String] = []
    var urlLabels: [String] = []
    
    // 数の表示
    let followingCountTitle = UILabel()
    let followingCountLabel = UILabel()
    let followerCountTitle = UILabel()
    let followerCountLabel = UILabel()
    let statusCountTitle = UILabel()
    let statusCountLabel = UILabel()
    
    // フォローしているか、フォローされているかの表示
    let isFollowingLabel = UILabel()
    let isFollowedLabel = UILabel()
    
    // アクションボタン
    //  フォローしたり、アンフォローしたり、ブロックしたり、ミュートしたり、リストに入れたり、ブラウザで開いたりする
    let actionButton = UIButton()
    
    init(accountData: AnalyzeJson.AccountData) {
        super.init(style: .default, reuseIdentifier: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
