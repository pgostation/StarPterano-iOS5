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
    static func upload(imageUrl: URL, callback: @escaping ([String: Any]?)->Void) {
        // 画像アップロード先URL
        guard let uploadUrl = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/media") else { return }
        
        // imageData生成
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(withALAssetURLs: [imageUrl], options: nil)
        guard let asset = fetchResult.firstObject else { return }
        
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat // これを指定しないとプレビュー画像も呼ばれる
        manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { (image, info) in
            guard let image = image else { return }
            let imageData = UIImageJPEGRepresentation(image, 0.8)!
            
            self.filename = "image.jpeg"
            self.mimetype = "image/jpeg"
            self.uploadData(data: imageData, uploadUrl: uploadUrl, callback: callback)
        }
    }
    
    // 動画のアップロード
    static func upload(movieUrl: URL, callback: @escaping ([String: Any]?)->Void) {
        // 画像アップロード先URL
        guard let uploadUrl = URL(string: "https://\(SettingsData.hostName ?? "")/api/v1/media") else { return }
        
        // movieData生成
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(withALAssetURLs: [movieUrl], options: nil)
        guard let asset = fetchResult.firstObject else { return }
        
        let manager = PHImageManager.default()
        manager.requestAVAsset(forVideo: asset, options: nil) { (asset, audioMix, infoDictionary) in
            guard let assetUrl = asset as? AVURLAsset else { return }
            guard let videoData = try? Data(contentsOf: assetUrl.url) else { return }
            
            // 圧縮して送信
            print("#### videoData = \(videoData.count / 1000)KB")
            if let asset = asset {
                let presetname: String
                if videoData.count < 5000000 {
                    presetname = AVAssetExportPresetHighestQuality
                } else if videoData.count < 20000000 {
                    presetname = AVAssetExportPresetMediumQuality
                } else {
                    presetname = AVAssetExportPresetLowQuality
                }
                guard let exportSession = AVAssetExportSession(asset: asset, presetName: presetname) else { return }
                
                var waitIndicator: WaitIndicator? = nil
                DispatchQueue.main.async {
                    waitIndicator = WaitIndicator()
                    UIUtils.getFrontViewController()?.view.addSubview(waitIndicator!)
                }
                
                let filePath = NSTemporaryDirectory() + "/temp.mov"
                let fileUrl = URL(fileURLWithPath: filePath)
                try? FileManager.default.removeItem(atPath: filePath)
                exportSession.outputURL = fileUrl
                exportSession.outputFileType = AVFileType.mp4
                
                exportSession.exportAsynchronously(completionHandler: {
                    DispatchQueue.main.async {
                        waitIndicator?.removeFromSuperview()
                    }
                    
                    switch exportSession.status {
                    case .completed:
                        self.filename = "movie.mp4"
                        self.mimetype = "video/mp4"
                        if let compressedData = try? Data(contentsOf: fileUrl) {
                            print("#### compressedData = \(compressedData.count / 1000)KB")
                            self.uploadData(data: compressedData, uploadUrl: uploadUrl, callback: callback)
                        }
                    case .failed:
                        break
                    case .cancelled:
                        break
                    default:
                        break
                    }
                })
            }
        }
    }
    
    // mediaデータのアップロード
    private static func uploadData(data: Data, uploadUrl: URL, callback: @escaping ([String: Any]?)->Void) {
        // boudary生成
        let boundary = generateBoundaryString()
        
        // params生成
        let params: [String: String] = ["access_token": SettingsData.accessToken ?? ""]
        
        // request生成
        var request = URLRequest(url: uploadUrl)
        request.httpMethod = "POST"
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = createBodyWith(parameters: params, filePathKey: "file", data: data, boundary: boundary)
        
        var waitIndicator: WaitIndicator? = nil
        DispatchQueue.main.async {
            waitIndicator = WaitIndicator()
            UIUtils.getFrontViewController()?.view.addSubview(waitIndicator!)
        }
        
        // mediaアップロードPOST
        let task = MastodonRequest.session.dataTask(with: request, completionHandler: { data, response, error in
            DispatchQueue.main.async {
                waitIndicator?.removeFromSuperview()
            }
            
            if let response = response as? HTTPURLResponse {
                print("statusCode=\(response.statusCode)")
                print("#allHeaderFields=\(response.allHeaderFields)")
            }
            do {
                if let data = data, data.count > 0 {
                    let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                    
                    callback(responseJson)
                } else if let error = error {
                    print(error.localizedDescription)
                    callback(nil)
                }
            } catch {
                print(response!)
            }
        })
        task.resume()
    }
    
    // ファイル名とmime/type
    private static var filename = ""
    private static var mimetype = ""
    
    // Create body for media
    // https://qiita.com/aryzae/items/8c16bc456588c1251f48
    private static func createBodyWith(parameters: [String: String]?, filePathKey: String?, data: Data, boundary: String) -> Data {
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
        body.append(data)
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
