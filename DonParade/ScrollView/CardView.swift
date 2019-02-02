//
//  CardView.swift
//  DonParade
//
//  Created by takayoshi on 2019/02/02.
//  Copyright © 2019 pgostation. All rights reserved.
//

import UIKit

final class CardView: UIView {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let domainLabel = UILabel()
    private var url: URL?
    
    init(id: String?) {
        let rect = CGRect(x: 10, y: 0, width: UIScreen.main.bounds.width - 20, height: 200)
        super.init(frame: rect)
        
        self.addSubview(imageView)
        self.addSubview(titleLabel)
        self.addSubview(bodyLabel)
        self.addSubview(domainLabel)
        
        setProperties()
        
        if let id = id {
            request(id: id)
        }
        
        self.setNeedsLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.clipsToBounds = true
        self.backgroundColor = ThemeColor.viewBgColor
        self.layer.cornerRadius = 8
        self.layer.borderWidth = 1 / UIScreen.main.scale
        self.layer.borderColor = ThemeColor.buttonBorderColor.cgColor
        
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
        bodyLabel.textColor = ThemeColor.messageColor
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
        guard let url = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/statuses/\(id)/card") else { return }
        try? MastodonRequest.get(url: url) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            if let data = data {
                let responseJson = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                if responseJson != nil {
                    let card = AnalyzeJson.analyzeCard(json: responseJson!!)
                    
                    // テキスト
                    DispatchQueue.main.async {
                        strongSelf.titleLabel.text = card.title
                        
                        strongSelf.bodyLabel.text = card.description
                        
                        // 画像を取得して設定
                        ImageCache.image(urlStr: card.image, isTemp: true, isSmall: false, shortcode: nil, isPreview: true) { (image) in
                            strongSelf.imageView.image = image
                            strongSelf.setNeedsLayout()
                        }
                        
                        // タップ時のリンク先
                        let url = URL(string: card.url ?? "")
                        strongSelf.url = url
                        let tapGesture = UITapGestureRecognizer(target: strongSelf, action: #selector(strongSelf.tapAction))
                        strongSelf.addGestureRecognizer(tapGesture)
                        
                        strongSelf.domainLabel.text = url?.host
                    }
                }
            }
        }
    }
    
    @objc func tapAction() {
        if let url = self.url {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
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
                                 y: 70,
                                 width: self.frame.width - 20,
                                 height: self.frame.height - 90)
        
        domainLabel.frame = CGRect(x: 10,
                                   y: self.frame.height - 20,
                                   width: self.frame.width - 20,
                                   height: 20)
    }
}
