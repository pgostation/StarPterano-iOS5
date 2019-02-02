//
//  CardView.swift
//  DonParade
//
//  Created by takayoshi on 2019/02/02.
//  Copyright © 2019 pgostation. All rights reserved.
//

import UIKit
import SafariServices

final class CardView: UIView {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let domainLabel = UILabel()
    private var url: URL?
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        formatter.locale = enUSPosixLocale
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return formatter
    }()
    
    init(id: String?, dateStr: String?) {
        let rect = CGRect(x: 10, y: 0, width: UIScreen.main.bounds.width - 20, height: 200)
        super.init(frame: rect)
        
        self.addSubview(imageView)
        self.addSubview(titleLabel)
        self.addSubview(bodyLabel)
        self.addSubview(domainLabel)
        
        setProperties()
        
        if let id = id {
            let date = CardView.dateFormatter.date(from: dateStr ?? "")
            if let date = date, date.timeIntervalSinceNow >= -2 {
                // 少し待ってからカード情報を取得
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.request(id: id)
                }
            } else {
                // 今すぐカード情報を取得
                request(id: id)
            }
        }
        
        self.setNeedsLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.alpha = 0
        self.clipsToBounds = true
        self.backgroundColor = ThemeColor.viewBgColor
        self.layer.cornerRadius = 8
        self.layer.borderWidth = 1 / UIScreen.main.scale
        self.layer.borderColor = ThemeColor.nameColor.cgColor
        
        imageView.contentMode = .scaleAspectFill
        imageView.alpha = 0.6
        
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byCharWrapping
        titleLabel.textColor = ThemeColor.nameColor
        titleLabel.font = UIFont.boldSystemFont(ofSize: SettingsData.fontSize)
        titleLabel.layer.shadowColor = ThemeColor.viewBgColor.cgColor
        titleLabel.layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
        titleLabel.layer.shadowOpacity = 1.0
        titleLabel.layer.shadowRadius = 1.0
        
        bodyLabel.numberOfLines = 0
        bodyLabel.lineBreakMode = .byCharWrapping
        bodyLabel.textColor = ThemeColor.contrastColor
        bodyLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize)
        bodyLabel.layer.shadowColor = ThemeColor.viewBgColor.cgColor
        bodyLabel.layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
        bodyLabel.layer.shadowOpacity = 1.0
        bodyLabel.layer.shadowRadius = 1.0
        
        domainLabel.textAlignment = .center
        domainLabel.textColor = ThemeColor.messageColor
        domainLabel.font = UIFont.systemFont(ofSize: SettingsData.fontSize - 2)
        domainLabel.layer.shadowColor = ThemeColor.viewBgColor.cgColor
        domainLabel.layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
        domainLabel.layer.shadowOpacity = 1.0
        domainLabel.layer.shadowRadius = 1.0
    }
    
    private func request(id: String) {
        // キャッシュにあるものを利用する
        if let card = CardView.cache[id] {
            draw(card: card)
            return
        }
        
        // リクエスト
        guard let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/statuses/\(id)/card") else { return }
        try? MastodonRequest.get(url: url) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            if let data = data {
                let responseJson = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                if responseJson != nil {
                    let card = AnalyzeJson.analyzeCard(json: responseJson!!)
                    
                    CardView.addCache(id: id, card: card)
                    
                    DispatchQueue.main.async {
                        strongSelf.draw(card: card)
                    }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    if let card = CardView.cache[id] {
                        self?.draw(card: card)
                    }
                }
            }
        }
    }
    
    private func draw(card: AnalyzeJson.CardData) {
        if card.url == nil { return }
        
        self.alpha = 1
        
        // テキスト
        self.titleLabel.text = card.title
        
        self.bodyLabel.text = card.description
        
        if SettingsData.isLoadPreviewImage {
            // 画像を取得して設定
            ImageCache.image(urlStr: card.image, isTemp: true, isSmall: false, shortcode: nil, isPreview: true) { (image) in
                self.imageView.image = image
                self.setNeedsLayout()
            }
        }
        
        // タップ時のリンク先
        let url = URL(string: card.url ?? "")
        self.url = url
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapAction))
        self.addGestureRecognizer(tapGesture)
        
        self.domainLabel.text = url?.host
        
        self.setNeedsLayout()
        self.superview?.setNeedsLayout()
    }
    
    @objc func tapAction() {
        if let url = self.url {
            let controller = SFSafariViewController(url: url)
            MainViewController.instance?.present(controller, animated: true)
        }
    }
    
    private static var cache: [String: AnalyzeJson.CardData] = [:]
    private static var oldCache: [String: AnalyzeJson.CardData] = [:]
    
    // キャッシュに追加
    private static func addCache(id: String, card: AnalyzeJson.CardData) {
        if cache.count >= 20 {
            oldCache = cache
        }
        
        cache[id] = card
    }
    
    // カードがあるかどうかをキャッシュから判断
    static func hasNotCard(id: String) -> Bool {
        if let data = cache[id], data.url == nil {
            return true
        }
        if let data = oldCache[id], data.url == nil {
            return true
        }
        return false
    }
    
    override func layoutSubviews() {
        imageView.frame = CGRect(x: 0,
                                 y: 0,
                                 width: self.frame.width,
                                 height: self.frame.height)
        
        titleLabel.frame = CGRect(x: 10,
                                  y: 10,
                                  width: self.frame.width - 20,
                                  height: 60)
        titleLabel.sizeToFit()
        
        bodyLabel.frame = CGRect(x: 10,
                                 y: titleLabel.frame.maxY + 10,
                                 width: self.frame.width - 20,
                                 height: self.frame.height - (titleLabel.frame.maxY + 10) - 20)
        
        domainLabel.frame = CGRect(x: 10,
                                   y: self.frame.height - 20,
                                   width: self.frame.width - 20,
                                   height: 20)
    }
}
