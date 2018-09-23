//
//  ImageUpload.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/23.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit
import Photos

final class ImageUpload {
    private init() { }
    
    // 画像のアップロード
    // https://qiita.com/aryzae/items/8c16bc456588c1251f48
    static func upload(imageUrl: URL, callback: @escaping ([String: Any]?)->Void) {
        // 画像アップロード先URL
        guard let uploadUrl = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/media") else { return }
        
        // params生成
        let params: [String: String] = ["access_token": SettingsData.accessToken ?? ""]
        
        // imageData生成
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(withALAssetURLs: [imageUrl], options: nil)
        guard let asset = fetchResult.firstObject else { return }
        
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat // これを指定しないとプレビュー画像も呼ばれる
        manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { (image, info) in
            guard let image = image else { return }
            let imageData = UIImageJPEGRepresentation(image, 0.8)!
            
            // boudary生成
            let boundary = generateBoundaryString()
            
            // request生成
            var request = URLRequest(url: uploadUrl)
            request.httpMethod = "POST"
            request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.httpBody = createBodyWith(parameters: params, filePathKey: "file", imageData: imageData, boundary: boundary)
            
            // 画像アップロードPOST
            let task = MastodonRequest.session.dataTask(with: request, completionHandler: { data, response, error in
                do {
                    if let data = data, data.count > 0 {
                        let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                        
                        callback(responseJson)
                    } else if error != nil {
                        callback(nil)
                    }
                } catch {
                    print(response!)
                }
            })
            task.resume()
        }
    }
    
    // JPEG固定でファイル名とmime/typeを使用
    private static var filename = "image.jpeg"
    private static let mimetype = "image/jpeg"
    
    // Create body for media
    private static func createBodyWith(parameters: [String: String]?, filePathKey: String?, imageData: Data, boundary: String) -> Data {
        var body = Data()
        
        if let parameters = parameters {
            for (key, value) in parameters {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append("\(value)\r\n")
            }
        }
        
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n")
        body.append("Content-Type: \(mimetype)\r\n\r\n")
        body.append(imageData)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")
        
        return body
    }
    
    private static func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
}

extension Data {
    public mutating func append(_ string: String) {
        let data = Data(string.utf8)
        return self.append(data)
    }
}
