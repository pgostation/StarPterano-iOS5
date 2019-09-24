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
    private var doneButton = UIButton() // 完了ボタン
    private let totalLabel = UILabel() // 総投票数を表示
    private let expiredLabel = UILabel() // 残り時間/締め切り済みを表示
    private let votedLabel = UILabel() // 投票済みを表示
    private var data: AnalyzeJson.PollData
    
    init(data: AnalyzeJson.PollData) {
        self.data = data
        
        super.init(frame: CGRect(x: 10,
                                 y: 0,
                                 width: UIScreen.main.bounds.width - 20,
                                 height: 50 + CGFloat(data.options.count) * 30))
        
        self.addSubview(totalLabel)
        self.addSubview(expiredLabel)
        self.addSubview(votedLabel)
        if data.multiple && data.voted != true {
            self.addSubview(doneButton)
        }
        
        setProperties()
        
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
        doneButton.addTarget(self, action: #selector(doneAction), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // プロパティ設定
    private func setProperties() {
        for (index, option) in data.options.enumerated() {
            if let vote = option.1 {
                let view = UIView()
                view.backgroundColor = ThemeColor.contrastColor.withAlphaComponent(0.3)
                if data.votes_count > 0 {
                    view.frame.size.width = (self.frame.width - 80) * CGFloat(vote) / CGFloat(data.votes_count)
                }
                voteGraphs.append(view)
                
                let label = UILabel()
                label.text = "\(vote)" + I18n.get("VOTE_COUNT_NUM")
                label.textColor = ThemeColor.contrastColor
                label.adjustsFontSizeToFitWidth = true
                voteCountLabels.append(label)
            }
            
            let label = UILabel()
            let (attrStr, _) = DecodeToot.decodeContent(content: option.0, emojis: data.emojis) { [weak self] in
                label.attributedText = DecodeToot.decodeContent(content: option.0, emojis: self?.data.emojis, callback: nil).0
            }
            label.attributedText = attrStr
            label.sizeToFit()
            if label.frame.width > self.frame.width - 100 {
                label.numberOfLines = 2
                label.font = UIFont.systemFont(ofSize: 12)
            }
            label.textColor = ThemeColor.contrastColor
            labels.append(label)
            
            let button = UIButton()
            button.setTitle("+", for: .normal)
            button.backgroundColor = UIColor.blue
            button.clipsToBounds = true
            button.layer.cornerRadius = 8
            buttons.append(button)
            if data.expired == true || data.voted == true {
                button.alpha = 0.3
                button.isEnabled = false
            }
            if data.own_votes.contains(index) {
                // 自分が投票したのはグレーにする
                button.backgroundColor = UIColor.black
                button.setTitle("✔︎", for: .normal)
            }
        }
        
        totalLabel.text = I18n.get("VOTE_TOTAL:") + "\(data.votes_count)"
        totalLabel.textColor = ThemeColor.contrastColor
        totalLabel.adjustsFontSizeToFitWidth = true
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
            formatter.locale = enUSPosixLocale
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
            return formatter
        }()
        
        if data.expired {
            expiredLabel.text = I18n.get("POLLS_EXPIRED")
        } else if let expires_at = data.expires_at {
            if let date = dateFormatter.date(from: expires_at) {
                let remain = date.timeIntervalSinceNow
                let str: String
                if remain < 60 {
                    str = String(format: I18n.get("DATETIME_%D_SECS_AGO"), Int(remain))
                } else if remain < 60 * 60 {
                    str = String(format: I18n.get("DATETIME_%D_MINS_AGO"), Int(remain / 60))
                } else if remain < 24 * 60 * 60 {
                    str = String(format: I18n.get("DATETIME_%D_HOURS_AGO"), Int(remain / 60 / 60))
                } else {
                    str = String(format: I18n.get("DATETIME_%D_DAYS_AGO"), Int(remain / 60 / 60 / 24))
                }
                expiredLabel.text = I18n.get("EXPIRES_TIME_FOR:") + str
            } else {
                expiredLabel.text = I18n.get("EXPIRES_TIME:") + "\(expires_at)"
            }
        }
        expiredLabel.textColor = ThemeColor.contrastColor
        expiredLabel.adjustsFontSizeToFitWidth = true
        
        if let voted = data.voted, voted == true {
            votedLabel.text = I18n.get("VOTED_LABEL")
            votedLabel.textColor = ThemeColor.contrastColor
            votedLabel.adjustsFontSizeToFitWidth = true
        }
        
        doneButton.setTitle(I18n.get("BUTTON_VOTE_DONE"), for: .normal)
        doneButton.isEnabled = false
        doneButton.backgroundColor = UIColor.gray
        doneButton.clipsToBounds = true
        doneButton.layer.cornerRadius = 8
        
        if data.voted == true {
            doneButton.isHidden = true
        }
    }
    
    @objc func voteAction(_ sender: UIButton) {
        if sender.backgroundColor != ThemeColor.cellBgColor {
            sender.backgroundColor = ThemeColor.cellBgColor
        } else {
            sender.backgroundColor = UIColor.blue
            return
        }
        
        if !data.multiple {
            voteRequest()
        } else {
            doneButton.isEnabled = true
        }
    }
    
    @objc func doneAction() {
        voteRequest()
        
        doneButton.isHidden = true
    }
    
    private func voteRequest() {
        let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/polls/\(data.id)/votes")!
        
        var choiceArray: [Int] = []
        
        for (i, button) in self.buttons.enumerated() {
            if button.backgroundColor == ThemeColor.cellBgColor {
                choiceArray.append(i)
            }
        }
        
        if choiceArray.count == 0 { return }
        
        let body: [String: Any] = ["choices": choiceArray]
        
        try? MastodonRequest.post(url: url, body: body) { [weak self] (data, response, error) in
            if let data = data {
                do {
                    if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject] {
                        if let pollData = AnalyzeJson.getPoll(json: responseJson) {
                            self?.data = pollData
                            
                            DispatchQueue.main.async {
                                self?.setProperties()
                            }
                        }
                    }
                } catch { }
            }
        }
    }
    
    override func layoutSubviews() {
        var top: CGFloat = 10
        for label in labels {
            label.frame = CGRect(x: 10,
                                 y: top,
                                 width: self.frame.width - 110,
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
                                    width: 170,
                                    height: 30)
        
        votedLabel.frame = CGRect(x: 250,
                                  y: top,
                                  width: 55,
                                  height: 30)
        
        doneButton.frame = CGRect(x: 220,
                                  y: top,
                                  width: 95,
                                  height: 30)
    }
}
