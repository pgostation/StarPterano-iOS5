//
//  DecodeToot.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/17.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// トゥートのHTML文字列を解析して、リンクや絵文字付き文字列にする

import Foundation
import UIKit

final class DecodeToot {
    static func decodeContent(content: String?, emojis: [[String: Any]]?, callback: (()->Void)?) -> (NSMutableAttributedString, Bool) {
        var text = content ?? ""
        
        // 先頭と最後の<p></p>を取り除く
        if text.hasPrefix("<p>") {
            text = String(text.suffix(text.count - 3))
        }
        if text.hasSuffix("</p>") {
            text = String(text.prefix(text.count - 4))
        }
        
        // 改行
        text = text.replacingOccurrences(of: "</p><p>", with: "\n\n")
        text = text.replacingOccurrences(of: "<br />", with: "\n")
        text = text.replacingOccurrences(of: "<br>", with: "\n")
        text = text.replacingOccurrences(of: "<span>", with: "")
        text = text.replacingOccurrences(of: "<span class=\"\">", with: "")
        text = text.replacingOccurrences(of: "<span class=\"invisible\">", with: "")
        text = text.replacingOccurrences(of: "<span class=\"ellipsis\">", with: "")
        text = text.replacingOccurrences(of: "<span class=\"h-card\">", with: "")
        text = text.replacingOccurrences(of: "</span>", with: "")
        
        // リンク
        var linkList: [(String.Index, String, String)] = []
        while let startRange = text.range(of: "<a "), let endRange = text.range(of: "</a>") {
            let startIndex = text.index(startRange.lowerBound, offsetBy: 0)
            let endIndex = text.index(endRange.lowerBound, offsetBy: 4)
            
            // href文字列を取り出す
            let tmpHrefStr = text.suffix(text.count - startIndex.encodedOffset)
            var urlStr = ""
            if let startHrefRange = tmpHrefStr.range(of: " href=\""), let endHrefRange = tmpHrefStr.range(of: "\" ") {
                let hrefStartIndex = tmpHrefStr.index(startHrefRange.lowerBound, offsetBy: 7)
                let hrefEndIndex = tmpHrefStr.index(endHrefRange.lowerBound, offsetBy: -1)
                urlStr = String(text.suffix(text.count - hrefStartIndex.encodedOffset).prefix(hrefEndIndex.encodedOffset - hrefStartIndex.encodedOffset + 1))
            }
            
            // 表示用文字列を取り出す
            var linkStr = ""
            if let startLinkRange = tmpHrefStr.range(of: ">") {
                let linkStartIndex = tmpHrefStr.index(startLinkRange.lowerBound, offsetBy: 1)
                linkStr = String(text.suffix(text.count - linkStartIndex.encodedOffset).prefix(endIndex.encodedOffset - linkStartIndex.encodedOffset - 4))
            }
            
            // リストに追加
            linkList.append((startIndex, String(urlStr), linkStr))
            text = String(text.prefix(startIndex.encodedOffset)) + linkStr + String(text.suffix(max(0, text.count - endIndex.encodedOffset)))
        }
        
        // &lt;などをデコード
        text = text.replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">").replacingOccurrences(of: "&quot;", with: "\"").replacingOccurrences(of: "&apos;", with: "'").replacingOccurrences(of: "&amp;", with: "&")
        
        // 絵文字の位置をリストアップする
        var emojiList: [(String.Index, NSAttributedString)] = []
        if let emojis = emojis {
            for emoji in emojis {
                guard let shortcode = emoji["shortcode"] as? String else { continue }
                let static_url = emoji["static_url"] as? String
                
                let attachment = NSTextAttachment()
                var execCallback = false
                ImageCache.image(urlStr: static_url, isTemp: false) { image in
                    if execCallback {
                        callback?()
                    } else {
                        attachment.image = image
                    }
                }
                if attachment.image == nil {
                    execCallback = true
                }
                attachment.bounds = CGRect(x: 0, y: 0, width: 18, height: 18)
                
                let attrStr = NSAttributedString(attachment: attachment)
                
                while let range = text.range(of: ":\(shortcode):") {
                    let index = text.index(range.lowerBound, offsetBy: 0)
                    text = text.replacingOccurrences(of: ":\(shortcode):", with: "", options: String.CompareOptions.anchored, range: range)
                    emojiList.append((index, attrStr))
                }
            }
        }
        
        let attributedText = NSMutableAttributedString(string: text)
        
        // 絵文字を追加
        for emoji in emojiList {
            attributedText.insert(emoji.1, at: min(emoji.0.encodedOffset, attributedText.length))
        }
        
        // リンクを追加
        for link in linkList {
            if link.0.encodedOffset + link.2.count > attributedText.length { continue }
            attributedText.addAttribute(NSAttributedStringKey.link,
                                        value: link.1,
                                        range: NSRange(location: link.0.encodedOffset, length: link.2.count))
        }
        
        return (attributedText, linkList.count > 0)
    }
    
    // 名前部分の絵文字解析
    static func decodeName(name: String?, emojis: [[String: Any]]?, callback: (()->Void)?) -> NSMutableAttributedString {
        var text = name ?? ""
        
        // 絵文字の位置をリストアップする
        var emojiList: [(String.Index, NSAttributedString)] = []
        if let emojis = emojis {
            for emoji in emojis {
                guard let shortcode = emoji["shortcode"] as? String else { continue }
                let static_url = emoji["static_url"] as? String
                
                let attachment = NSTextAttachment()
                var execCallback = false
                ImageCache.image(urlStr: static_url, isTemp: false) { image in
                    if execCallback {
                        callback?()
                    } else {
                        attachment.image = image
                    }
                }
                if attachment.image == nil {
                    execCallback = true
                }
                attachment.bounds = CGRect(x: 0, y: 0, width: 18, height: 18)
                
                let attrStr = NSAttributedString(attachment: attachment)
                
                while let range = text.range(of: ":\(shortcode):") {
                    let index = text.index(range.lowerBound, offsetBy: 0)
                    text = text.replacingOccurrences(of: ":\(shortcode):", with: "", options: String.CompareOptions.anchored, range: range)
                    emojiList.append((index, attrStr))
                }
            }
        }
        
        let attributedText = NSMutableAttributedString(string: text)
        
        // 絵文字を追加
        for emoji in emojiList {
            attributedText.insert(emoji.1, at: emoji.0.encodedOffset)
        }
        
        return attributedText
    }
    
    // 日時を解析
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        formatter.locale = enUSPosixLocale
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return formatter
    }()
    static func decodeTime(text: String) -> Date {
        return dateFormatter.date(from: text) ?? Date()
    }
}
