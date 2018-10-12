//
//  ImageCheckView.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/26.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 添付画像の表示、解除、NSFWの設定を行う

import UIKit
import Photos

final class ImageCheckView: UIView {
    private let nsfwLabel = UILabel()
    let nsfwSw = UISwitch()
    var urls: [URL] = []
    private var imageViews: [UIView] = []
    private var deleteButtons: [UIButton] = []
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
        
        self.addSubview(nsfwLabel)
        self.addSubview(nsfwSw)
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.backgroundColor = ThemeColor.viewBgColor
        
        nsfwLabel.text = I18n.get("SWITCH_NSFW")
        nsfwLabel.textColor = ThemeColor.messageColor
        nsfwLabel.textAlignment = .right
        
        nsfwSw.isOn = false
        nsfwSw.backgroundColor = UIColor.white
        nsfwSw.clipsToBounds = true
        nsfwSw.layer.cornerRadius = 16
    }
    
    func add(imageUrl: URL) {
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(withALAssetURLs: [imageUrl], options: nil)
        guard let asset = fetchResult.firstObject else { return }
        
        var isGIForPNG = false
        let resources = PHAssetResource.assetResources(for: asset)
        for resource in resources {
            if resource.uniformTypeIdentifier == "com.compuserve.gif" {
                isGIForPNG = true
            }
            if resource.uniformTypeIdentifier == "public.png" {
                isGIForPNG = true
            }
        }
        
        if isGIForPNG {
            addPNGImage(imageUrl: imageUrl, asset: asset)
        } else {
            addNormalImage(imageUrl: imageUrl, asset: asset)
        }
    }
    
    // GIFかPNGの場合
    private func addPNGImage(imageUrl: URL, asset: PHAsset) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat // これを指定しないとプレビュー画像も呼ばれる
        options.version = .original
        manager.requestImageData(for: asset, options: options) { (data, string, orientation, infoDict) in
            guard let data = data else { return }
            
            if !self.urls.contains(imageUrl) {
                self.urls.append(imageUrl)
            }
            
            let imageView: UIView
            if imageUrl.absoluteString.lowercased().contains(".gif") {
                let image = UIImage(gifData: data)
                imageView = UIImageView(gifImage: image)
                (imageView as? UIImageView)?.contentMode = .scaleAspectFit
            } else {
                let image = UIImage(data: data)
                imageView = UIImageView(image: image)
                (imageView as? UIImageView)?.contentMode = .scaleAspectFit
            }
            self.addSubview(imageView)
            self.imageViews.append(imageView)
            
            let deleteButton = UIButton()
            deleteButton.setTitle(I18n.get("BUTTON_DELETE_IMAGE"), for: .normal)
            deleteButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
            deleteButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
            deleteButton.clipsToBounds = true
            deleteButton.layer.cornerRadius = 12
            self.addSubview(deleteButton)
            self.deleteButtons.append(deleteButton)
            deleteButton.addTarget(self, action: #selector(self.deleteAction(_:)), for: .touchUpInside)
            
            self.setNeedsLayout()
        }
    }
    
    // 不透明な静止画
    private func addNormalImage(imageUrl: URL, asset: PHAsset) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat // これを指定しないとプレビュー画像も呼ばれる
        manager.requestImage(for: asset, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFill, options: options) { (image, info) in
            guard let image = image else { return }
            
            if !self.urls.contains(imageUrl) {
                self.urls.append(imageUrl)
            }
            
            let imageView = UIImageView()
            imageView.image = image
            imageView.contentMode = .scaleAspectFit
            self.addSubview(imageView)
            self.imageViews.append(imageView)
            
            let deleteButton = UIButton()
            deleteButton.setTitle(I18n.get("BUTTON_DELETE_IMAGE"), for: .normal)
            deleteButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
            deleteButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
            deleteButton.clipsToBounds = true
            deleteButton.layer.cornerRadius = 12
            self.addSubview(deleteButton)
            self.deleteButtons.append(deleteButton)
            deleteButton.addTarget(self, action: #selector(self.deleteAction(_:)), for: .touchUpInside)
            
            self.setNeedsLayout()
        }
    }
    
    @objc func deleteAction(_ sender: UIButton) {
        for (index, button) in self.deleteButtons.enumerated() {
            if sender == button {
                imageViews[index].removeFromSuperview()
                deleteButtons[index].removeFromSuperview()
                
                if index < urls.count {
                    urls.remove(at: index)
                    imageViews.remove(at: index)
                    deleteButtons.remove(at: index)
                }
                
                (self.superview as? TootView)?.refresh()
                
                self.setNeedsLayout()
                
                break
            }
        }
    }
    
    override func layoutSubviews() {
        nsfwLabel.frame = CGRect(x: 0,
                                 y: 5,
                                 width: 160,
                                 height: 25)
        
        nsfwSw.frame = CGRect(x: 160,
                              y: 2,
                              width: 51,
                              height: 31)
        
        let imageSize: CGFloat = UIScreen.main.bounds.height <= 480 ? 120 : 145
        var x: CGFloat = 0
        var y: CGFloat = 0
        for imageView in self.imageViews {
            imageView.frame = CGRect(x: 5 + x * (imageSize + 10),
                                     y: 45 + y * (imageSize + 60),
                                     width: imageSize,
                                     height: imageSize)
            
            x += 1
            if x >= 2 {
                x = 0
                y += 1
            }
        }
        
        x = 0
        y = 0
        for deleteButton in self.deleteButtons {
            deleteButton.frame = CGRect(x: 40 + x * (imageSize + 10),
                                        y: 195 + y * (imageSize + 60),
                                        width: 80,
                                        height: 35)
            
            x += 1
            if x >= 2 {
                x = 0
                y += 1
            }
        }
        
        self.frame.size.height = 45 + y * (imageSize + 60) + imageSize + 40 + (UIUtils.isIphoneX ? 50 : 0)
    }
}
