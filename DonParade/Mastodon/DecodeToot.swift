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
    // 自前でHTML解析
    static func decodeContentFast(content: String?, emojis: [[String: Any]]?, callback: (()->Void)?) -> (NSMutableAttributedString, Bool) {
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
        if text.contains("<") {
            text = text.replacingOccurrences(of: "<br />", with: "\n")
            text = text.replacingOccurrences(of: "<br>", with: "\n")
            if text.contains("<span") {
                text = text.replacingOccurrences(of: "<span>", with: "")
                text = text.replacingOccurrences(of: "<span class=\"\">", with: "")
                text = text.replacingOccurrences(of: "<span class=\"invisible\">", with: "")
                text = text.replacingOccurrences(of: "<span class=\"ellipsis\">", with: "")
                text = text.replacingOccurrences(of: "<span class=\"h-card\">", with: "")
                text = text.replacingOccurrences(of: "</span>", with: "")
            }
        }
        
        // リンク
        var linkList: [(String.Index, String, String)] = []
        var loopCount = 0
        while let startRange = text.range(of: "<a "), let endRange = text.range(of: "</a>"), loopCount < 50 {
            let startIndex = text.index(startRange.lowerBound, offsetBy: 0)
            let endIndex = text.index(endRange.lowerBound, offsetBy: 4)
            
            // href文字列を取り出す
            let tmpHrefStr = text.suffix(from: startIndex).prefix(upTo: text.index(endIndex, offsetBy: -4))
            let tmpHrefStr2 = "\(tmpHrefStr)"
            var urlStr = ""
            if let startHrefRange = tmpHrefStr2.range(of: " href=\""), let endHrefRange = tmpHrefStr2.range(of: "\" ") {
                let hrefStartIndex = tmpHrefStr2.index(startHrefRange.lowerBound, offsetBy: 7)
                let hrefEndIndex = tmpHrefStr2.index(endHrefRange.lowerBound, offsetBy: -1)
                urlStr = String(tmpHrefStr2.suffix(max(0, tmpHrefStr2.count - hrefStartIndex.encodedOffset)).prefix(max(0, hrefEndIndex.encodedOffset - hrefStartIndex.encodedOffset + 1)))
            }
            
            // 表示用文字列を取り出す
            var linkStr = ""
            if let startLinkRange = tmpHrefStr2.range(of: ">") {
                let linkStartIndex = tmpHrefStr2.index(startLinkRange.lowerBound, offsetBy: 1)
                linkStr = String(tmpHrefStr2.suffix(tmpHrefStr2.count - linkStartIndex.encodedOffset).prefix(endIndex.encodedOffset - linkStartIndex.encodedOffset - 4))
            }
            
            // リストに追加
            linkList.append((startIndex, String(urlStr), linkStr))
            text = String(text.prefix(upTo: startIndex)) + linkStr + String(text.suffix(from: endIndex))
            
            loopCount += 1
        }
        
        // &lt;などをデコード
        text = text.replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">").replacingOccurrences(of: "&quot;", with: "\"").replacingOccurrences(of: "&apos;", with: "'").replacingOccurrences(of: "&amp;", with: "&")
        
        let attributedText = NSMutableAttributedString(string: text)
        
        // リンクを追加
        for link in linkList {
            if link.0.encodedOffset + link.2.count > attributedText.length { continue }
            attributedText.addAttribute(NSAttributedStringKey.link,
                                        value: link.1,
                                        range: NSRange(location: link.0.encodedOffset, length: link.2.count))
        }
        
        // 絵文字に変える
        if let emojis = emojis {
            for emoji in emojis {
                guard let shortcode = emoji["shortcode"] as? String else { continue }
                let url = emoji["url"] as? String
                
                let attachment = NSTextAttachment()
                var execCallback = false
                ImageCache.image(urlStr: url, isTemp: false, isSmall: true, shortcode: shortcode) { image in
                    if execCallback {
                        callback?()
                    } else {
                        attachment.image = image
                    }
                }
                if attachment.image == nil {
                    execCallback = true
                }
                attachment.bounds = CGRect(x: 0, y: 0, width: SettingsData.fontSize + 4, height: SettingsData.fontSize + 4)
                
                let attrStr = NSAttributedString(attachment: attachment)
                
                while true {
                    let nsStr = attributedText.string as NSString
                    if !nsStr.contains(":\(shortcode):") { break }
                    let range = nsStr.range(of: ":\(shortcode):")
                    attributedText.replaceCharacters(in: range, with: attrStr)
                }
            }
        }
        
        return (attributedText, linkList.count > 0)
    }
    
    // https://qiita.com/kumetter/items/91b433cd4d30abe507c5
    static func parseText2HTML(sourceText text: String) -> NSMutableAttributedString? {
        
        // 受け取ったデータをUTF-8エンコードする
        let encodeData = text.data(using: String.Encoding.utf8, allowLossyConversion: true)
        
        // 表示データのオプションを設定する
        let attributedOptions: [NSAttributedString.DocumentReadingOptionKey: AnyObject] = [
            .documentType: NSAttributedString.DocumentType.html as AnyObject,
            .characterEncoding: String.Encoding.utf8.rawValue as AnyObject
        ]
        
        // 文字列の変換処理
        var attributedString: NSMutableAttributedString?
        do {
            attributedString = try NSMutableAttributedString(
                data: encodeData!,
                options: attributedOptions,
                documentAttributes: nil
            )
        } catch {
            // 変換でエラーが出た場合
        }
        
        return attributedString
    }
    
    static func decodeContent(content: String?, emojis: [[String: Any]]?, callback: (()->Void)?) -> (NSMutableAttributedString, Bool) {
        guard let attributedText = parseText2HTML(sourceText: content ?? "") else {
            return (NSMutableAttributedString(string: content ?? ""), false)
        }
        
        // 絵文字に変える
        if let emojis = emojis {
            for emoji in emojis {
                guard let shortcode = emoji["shortcode"] as? String else { continue }
                let url = emoji["url"] as? String
                
                let attachment = NSTextAttachment()
                var execCallback = false
                ImageCache.image(urlStr: url, isTemp: false, isSmall: true, shortcode: shortcode) { image in
                    if execCallback {
                        callback?()
                    } else {
                        attachment.image = image
                    }
                }
                if attachment.image == nil {
                    execCallback = true
                }
                attachment.bounds = CGRect(x: 0, y: 0, width: SettingsData.fontSize + 4, height: SettingsData.fontSize + 4)
                
                let attrStr = NSAttributedString(attachment: attachment)
                
                while true {
                    let nsStr = attributedText.string as NSString
                    if !nsStr.contains(":\(shortcode):") { break }
                    let range = nsStr.range(of: ":\(shortcode):")
                    attributedText.replaceCharacters(in: range, with: attrStr)
                }
            }
        }
        
        let hasLink = (content?.contains("<a href") == true)
        
        return (attributedText, hasLink)
    }
    
    // 名前部分の絵文字解析
    static func decodeName(name: String?, emojis: [[String: Any]]?, callback: (()->Void)?) -> NSMutableAttributedString {
        let text = name ?? ""
        
        let attributedText = NSMutableAttributedString(string: text)
        
        if let emojis = emojis {
            for emoji in emojis {
                guard let shortcode = emoji["shortcode"] as? String else { continue }
                let url = emoji["url"] as? String
                
                let attachment = NSTextAttachment()
                var execCallback = false
                ImageCache.image(urlStr: url, isTemp: false, isSmall: true, shortcode: shortcode) { image in
                    if execCallback {
                        callback?()
                    } else {
                        attachment.image = image
                    }
                }
                if attachment.image == nil {
                    execCallback = true
                }
                attachment.bounds = CGRect(x: 0, y: 0, width: SettingsData.fontSize + 4, height: SettingsData.fontSize + 4)
                
                let attrStr = NSAttributedString(attachment: attachment)
                
                while true {
                    let nsStr = attributedText.string as NSString
                    if !nsStr.contains(":\(shortcode):") { break }
                    let range = nsStr.range(of: ":\(shortcode):")
                    attributedText.replaceCharacters(in: range, with: attrStr)
                }
            }
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
    
    // 絵文字から元の文字列に戻す
    // https://stackoverflow.com/questions/36465761/can-nsattributedstring-which-contains-nstextattachment-be-storedor-restored
    static func encodeEmoji(attributedText: NSAttributedString, textStorage: NSTextStorage) -> String {
        // 絵文字のある場所をリストにする
        var list: [(NSRange, String)] = []
        let range = NSRange(location: 0, length: attributedText.length)
        if (textStorage.containsAttachments(in: range)) {
            let attrString = attributedText
            var location = 0
            while location < range.length {
                var r = NSRange()
                let attrDictionary = attrString.attributes(at: location, effectiveRange: &r)
                let attachment = attrDictionary[NSAttributedStringKey.attachment] as? NSTextAttachment
                if let image = attachment?.image {
                    list.append((r, (image as? EmojiImage)?.shortcode ?? ""))
                }
                location += r.length
            }
        }
        
        // 絵文字から元のコードに置き換える
        let attributedStr = NSMutableAttributedString(attributedString: attributedText)
        for data in list.reversed() {
            attributedStr.replaceCharacters(in: data.0, with: ":" + data.1 + ":")
        }
        
        return attributedStr.string
    }
    
    // NSAttributedStringから絵文字のshortcodeの配列を返す
    static func getEmojiList(attributedText: NSAttributedString, textStorage: NSTextStorage) -> [(NSRange, String)] {
        // 絵文字のある場所をリストにする
        var list: [(NSRange, String)] = []
        let range = NSRange(location: 0, length: attributedText.length)
        if (textStorage.containsAttachments(in: range)) {
            let attrString = attributedText
            var location = 0
            while location < range.length {
                var r = NSRange()
                let attrDictionary = attrString.attributes(at: location, effectiveRange: &r)
                let attachment = attrDictionary[NSAttributedStringKey.attachment] as? NSTextAttachment
                if let image = attachment?.image {
                    list.append((r, (image as? EmojiImage)?.shortcode ?? ""))
                }
                location += r.length
            }
        }
        
        return list
    }
}

class EmojiImage: UIImage {
    var shortcode: String? = nil
}
