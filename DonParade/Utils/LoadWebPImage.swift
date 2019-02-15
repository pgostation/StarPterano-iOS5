//
//  LoadWebPImage.swift
//  DonParade
//
//  Created by takayoshi on 2019/02/15.
//  Copyright © 2019 pgostation. All rights reserved.
//

import UIKit
import WebP

final class LoadWebPImage {
    private init() {}
    
    static func load(path: String) -> UIImage? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        
        return load(data: data)
    }
    
    static func load(data: Data) -> UIImage? {
        let decoder = WebPDecoder()
        let options = WebPDecoderOptions()
        guard let cgImage = try? decoder.decode(data, options: options) else { return nil }
        let webpImage = UIImage(cgImage: cgImage)
        
        return webpImage
    }
}
