//
//  ImageUtils.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/22.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 画像関連

import UIKit
import CoreImage

final class ImageUtils {
    // 画像を回転させる
    static func rotateImage(image: UIImage?, isRight: Bool) -> UIImage? {
        guard let image = image else { return nil }
        guard let ciImage = image.ciImage ?? CIImage(image: image) else { return nil }
        
        if #available(iOS 11.0, *) {
            let orientedImage = ciImage.oriented(isRight ? CGImagePropertyOrientation.right : CGImagePropertyOrientation.left)
            return UIImage(ciImage: orientedImage)
        }
        
        return nil
    }
    
    // 正方形の画像を縮小する
    // アイコンは36pt, 絵文字は40ptくらいにしたい
    static func small(image: EmojiImage, size: CGFloat) -> EmojiImage {
        if image.size.width < size * UIScreen.main.scale { return image }
        
        let rate = max(size / image.size.width, size / image.size.height)
        
        let resizedSize = CGSize(width: image.size.width * rate, height: image.size.height * rate)
        
        UIGraphicsBeginImageContextWithOptions(resizedSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: resizedSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let resizedImage = resizedImage {
            if let data = resizedImage.pngData() {
                return EmojiImage(data: data) ?? image
            }
        }
        
        return image
    }
    
    // 正方形の画像を縮小する
    static func smallIcon(image: UIImage, size: CGFloat) -> UIImage {
        if image.size.width < size * UIScreen.main.scale { return image }
        
        let rate = max(size / image.size.width, size / image.size.height)
        
        let resizedSize = CGSize(width: image.size.width * rate, height: image.size.height * rate)
        
        UIGraphicsBeginImageContextWithOptions(resizedSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: resizedSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let resizedImage = resizedImage {
            if let data = resizedImage.pngData() {
                return UIImage(data: data) ?? image
            }
        }
        
        return image
    }
    
    // 画像をピクセル数以内に縮小する
    static func small(image: UIImage, pixels: CGFloat) -> UIImage {
        if image.size.width * image.size.height < pixels { return image }
        
        let rate = sqrt(pixels / (image.size.width * image.size.height))
        
        let resizedSize = CGSize(width: floor(image.size.width * rate), height: floor(image.size.height * rate))
        
        UIGraphicsBeginImageContextWithOptions(resizedSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: resizedSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let resizedImage = resizedImage {
            if let data = resizedImage.pngData() {
                return UIImage(data: data) ?? image
            }
        }
        
        return image
    }
    
    // 指定色のUIImageを作成
    static func colorImage(color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 1, height: 1), false, 0.0)
        do {
            let context = UIGraphicsGetCurrentContext()
            context?.setFillColor(color.cgColor)
            context?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    // UIViewをキャプチャしてUIImageにする
    // https://qiita.com/nasu_st/items/561d8946966015abd448
    static func imageFromView(view: UIView) -> UIImage? {
        let rect = view.bounds
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        
        view.drawHierarchy(in: rect, afterScreenUpdates: true)
        
        let capture = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return capture
    }
    
    // 画像に透明なピクセルがあるかどうかを調べる
    static func hasAlpha(image: UIImage) -> Bool {
        guard let imageData = image.cgImage?.dataProvider?.data else { return false }
        let data : UnsafePointer = CFDataGetBytePtr(imageData)
        let scale = Int(image.scale)
        let bytesPerPixel = image.cgImage!.bitsPerPixel / 8
        for y in 0..<Int(image.size.height) {
            for x in 0..<Int(image.size.width) {
                let address : Int = ((Int(image.size.width) * (y * scale)) + (x * scale)) * bytesPerPixel
                //let r = CGFloat(data[address])
                //let g = CGFloat(data[address+1])
                //let b = CGFloat(data[address+2])
                let a = CGFloat(data[address+3])
                
                if a < 255 {
                    return true
                }
            }
        }
        return false
    }
    
    // 画像の最大ピクセル数
    static func maxPixels() -> CGFloat {
        // imastodonでは1920 * 1920
        if SettingsData.hostName == "imastodon.net" {
            return 1920 * 1920
        }
        
        // bbbdn.jpでは2560 * 1280
        if SettingsData.hostName == "bbbdn.jp" {
            return 2560 * 1280
        }
        
        // デフォルト
        return 1280 * 1280
    }
}
