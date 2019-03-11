//
//  PollView.swift
//  DonParade
//
//  Created by takayoshi on 2019/03/11.
//  Copyright © 2019 pgostation. All rights reserved.
//

// 投票の内容や結果表示、あるいはボタンを押して投票もできる

import UIKit

final class PollView: UIView {
    private var labels: [UILabel] = [] // 項目名
    private var voteGraphs: [UIView] = [] // グラフ
    private var voteCountLabels: [UILabel] = [] // %と投票数の表示
    private var buttons: [UIButton] = [] // 投票ボタン
    private let totalLabel = UILabel() // 総投票数を表示
    private let expiredLabel = UILabel() // 残り時間/締め切り済みを表示
    private let votedLabel = UILabel() // 投票済みを表示
    
    init(data: AnalyzeJson.PollData) {
        super.init(frame: CGRect(x: 10,
                                 y: 0,
                                 width: UIScreen.main.bounds.width - 20,
                                 height: 50 + CGFloat(data.options.count) * 30))
        
        self.addSubview(totalLabel)
        self.addSubview(expiredLabel)
        self.addSubview(votedLabel)
        
        setProperties(data: data)
        
        for graph in voteGraphs {
            self.addSubview(graph)
        }
        for label in labels {
            self.addSubview(label)
        }
        for label in voteCountLabels {
            self.addSubview(label)
        }
        for button in buttons {
            self.addSubview(button)
            button.addTarget(self, action: #selector(voteAction(_:)), for: .touchUpInside)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // プロパティ設定
    private func setProperties(data: AnalyzeJson.PollData) {
        for option in data.options {
            if let vote = option.1 {
                let view = UIView()
                view.backgroundColor = ThemeColor.contrastColor.withAlphaComponent(0.3)
                if data.votes_count > 0 {
                    view.frame.size.width = (self.frame.width - 80) * CGFloat(vote) / CGFloat(data.votes_count)
                }
                voteGraphs.append(view)
                
                let label = UILabel()
                label.text = "\(vote)"
                label.textColor = ThemeColor.contrastColor
                label.adjustsFontSizeToFitWidth = true
                voteCountLabels.append(label)
            }
            
            let label = UILabel()
            label.text = option.0
            label.textColor = ThemeColor.contrastColor
            label.adjustsFontSizeToFitWidth = true
            labels.append(label)
            
            if data.expired == false && data.voted != true {
                let button = UIButton()
                button.setTitle("+", for: .normal)
                button.backgroundColor = UIColor.blue
                button.clipsToBounds = true
                button.layer.cornerRadius = 8
                buttons.append(button)
            }
        }
        
        totalLabel.text = "\(data.votes_count)"
        totalLabel.textColor = ThemeColor.contrastColor
        totalLabel.adjustsFontSizeToFitWidth = true
        
        if data.expired {
            expiredLabel.text = "expired"
        } else if let expires_at = data.expires_at {
            expiredLabel.text = "expires at: \(expires_at)"
        }
        expiredLabel.textColor = ThemeColor.contrastColor
        expiredLabel.adjustsFontSizeToFitWidth = true
        
        if let voted = data.voted, voted == true {
            votedLabel.text = "voted"
            votedLabel.textColor = ThemeColor.contrastColor
            votedLabel.adjustsFontSizeToFitWidth = true
        }
    }
    
    @objc func voteAction(_ sender: UIButton) {
        // "####"
    }
    
    override func layoutSubviews() {
        var top: CGFloat = 10
        for label in labels {
            label.frame = CGRect(x: 10,
                                 y: top,
                                 width: self.frame.width - 80,
                                 height: 30)
            top += 30
        }
        
        top = 10
        for graph in voteGraphs {
            graph.frame = CGRect(x: 0,
                                 y: top + 5,
                                 width: graph.frame.width,
                                 height: 20)
            top += 30
        }
        
        top = 10
        for label in voteCountLabels {
            label.frame = CGRect(x: self.frame.width - 100,
                                 y: top,
                                 width: 50,
                                 height: 30)
            top += 30
        }
        
        top = 10
        for button in buttons {
            button.frame = CGRect(x: self.frame.width - 40,
                                  y: top + 1,
                                  width: 28,
                                  height: 28)
            top += 30
        }
        
        top += 5
        
        totalLabel.frame = CGRect(x: 0,
                                  y: top,
                                  width: 60,
                                  height: 30)
        
        expiredLabel.frame = CGRect(x: 70,
                                    y: top,
                                    width: 180,
                                    height: 30)
        
        votedLabel.frame = CGRect(x: 260,
                                  y: top,
                                  width: 60,
                                  height: 30)
    }
}
