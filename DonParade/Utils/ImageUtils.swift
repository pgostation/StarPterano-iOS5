//
//  ImageUtils.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/22.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit
import CoreImage

final class ImageUtils {
    static func rotateImage(image: UIImage?) -> UIImage? {
        guard let image = image else { return nil }
        guard let ciImage = image.ciImage ?? CIImage(image: image) else { return nil }
        
        if #available(iOS 11.0, *) {
            let orientedImage = ciImage.oriented(CGImagePropertyOrientation.right)
            return UIImage(ciImage: orientedImage)
        }
        
        return nil
    }
}
