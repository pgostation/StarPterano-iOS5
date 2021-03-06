//
//  MastodonRequest.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/15.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// MastodonサーバーにHTTP GET/POSTメソッドでJSONを送信する

import Foundation

final class MastodonRequest {
    static let session = URLSession.shared
    
    // GETメソッド
    private static var lastRequestStr = "" // GETメソッドをループして呼ぶのを防ぐ
    private static var lastReqestDate = Date()
    static func get(url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) throws {
        let requestStr = (SettingsData.accessToken ?? "") + url.absoluteString
        if lastRequestStr == requestStr && Date().timeIntervalSince(lastReqestDate) <= 1 {
            print("1秒以内に同一URLへのGETがありました \(url.absoluteString)")
            return
        }
        
        print("get \(url.absoluteString)")
        
        lastRequestStr = requestStr
        lastReqestDate = Date()
        
        var request: URLRequest = URLRequest(url: url)
        
        guard let accessToken = SettingsData.accessToken else { return }
        
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        session.dataTask(with: request) { (data, response, error) in
            if let response = response as? HTTPURLResponse {
                if response.statusCode != 200 {
                    let string = String(data: data ?? Data(), encoding: String.Encoding.utf8) ?? ""
                    
                    print("response.statusCode=\(response.statusCode), data=\(string)")
                    
                    let regex = try? NSRegularExpression(pattern: "<h1>[^<]+</h1>",
                                                         options: NSRegularExpression.Options())
                    let matches = regex?.matches(in: string,
                                                 options: NSRegularExpression.MatchingOptions(),
                                                 range: NSMakeRange(0, string.count))
                    if let result = matches?.first {
                        for i in 0..<result.numberOfRanges {
                            let parsedText = (string as NSString).substring(with: result.range(at: i))
                            
                            MainViewController.instance?.showNotify(text: "ステータス: \(response.statusCode)\n\n\(parsedText)")
                            break
                        }
                    } else {
                        MainViewController.instance?.showNotify(text: "ステータス: \(response.statusCode)")
                    }
                }
                if let remain = response.allHeaderFields["x-ratelimit-remaining"] {
                    print("GET remain=\(remain)")
                }
            }
            
            completionHandler(data, response, error)
            }.resume()
    }
    
    // POSTメソッド
    static func post(url: URL, body: Dictionary<String, Any>, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) throws {
        print("post \(url.path)")
        
        var request: URLRequest = URLRequest(url: url)
        
        guard let accessToken = SettingsData.accessToken else { return }
        
        request.httpMethod = "POST"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        
        session.dataTask(with: request) { (data, response, error) in
            if let response = response as? HTTPURLResponse {
                if response.statusCode != 200 {
                    print("response.statusCode=\(response.statusCode), data=\(String(data: data ?? Data(), encoding: String.Encoding.utf8) ?? "-")")
                }
                if let remain = response.allHeaderFields["x-ratelimit-remaining"] {
                    print("POST remain=\(remain)")
                }
            }
            
            completionHandler(data, response, error)
            }.resume()
    }
    
    // DELETEメソッド
    static func delete(url: URL, body: Dictionary<String, Any>? = nil, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) throws {
        var request: URLRequest = URLRequest(url: url)
        
        guard let accessToken = SettingsData.accessToken else { return }
        
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        if let body = body {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        }
        
        session.dataTask(with: request) { (data, response, error) in
            if let response = response as? HTTPURLResponse {
                if response.statusCode != 200 {
                    print("response.statusCode=\(response.statusCode), data=\(String(data: data ?? Data(), encoding: String.Encoding.utf8) ?? "-")")
                }
                if let remain = response.allHeaderFields["x-ratelimit-remaining"] {
                    print("DELETE remain=\(remain)")
                }
            }
            
            completionHandler(data, response, error)
            }.resume()
    }
    
    // PATCHメソッド
    static func patch(url: URL, body: Dictionary<String, Any>?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) throws {
        var request: URLRequest = URLRequest(url: url)
        
        guard let accessToken = SettingsData.accessToken else { return }
        
        request.httpMethod = "PATCH"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        if let body = body {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        }
        
        session.dataTask(with: request) { (data, response, error) in
            if let response = response as? HTTPURLResponse {
                if response.statusCode != 200 {
                    print("response.statusCode=\(response.statusCode), data=\(String(data: data ?? Data(), encoding: String.Encoding.utf8) ?? "-")")
                }
                if let remain = response.allHeaderFields["x-ratelimit-remaining"] {
                    print("PATCH remain=\(remain)")
                }
            }
            
            completionHandler(data, response, error)
            }.resume()
    }
    
    // POSTメソッド (アクセストークンなし、認証前に使う)
    static func firstPost(url: URL, body: Dictionary<String, String>, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) throws {
        var request: URLRequest = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        
        session.dataTask(with: request, completionHandler: completionHandler).resume()
    }
}
