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
import SDWebImage
import APNGKit

final class DecodeToot {
    // 自前でHTML解析
    static func decodeContentFast(content: String?, emojis: [[String: Any]]?, callback: (()->Void)?) -> (NSMutableAttributedString, Bool, Bool) {
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
        text = text.replacingOccurrences(of: "<p>", with: "\n")
        text = text.replacingOccurrences(of: "</p>", with: "")
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
                linkStr = String(tmpHrefStr2.suffix(max(0, tmpHrefStr2.count - linkStartIndex.encodedOffset)).prefix(max(0, endIndex.encodedOffset - linkStartIndex.encodedOffset - 4)))
            }
            
            var offset = 0
            do {
                let beforeString = text.prefix(startIndex.encodedOffset)
                let beforeCount = beforeString.count
                let afterCount = beforeString.replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">").replacingOccurrences(of: "&quot;", with: "\"").replacingOccurrences(of: "&apos;", with: "'").replacingOccurrences(of: "&amp;", with: "&").count
                offset = afterCount - beforeCount
            }
            
            // リストに追加
            linkList.append((text.index(startIndex, offsetBy: offset) , String(urlStr), linkStr))
            text = String(text.prefix(upTo: startIndex)) + linkStr + String(text.suffix(from: endIndex))
            
            loopCount += 1
        }
        
        // &lt;などをデコード
        text = text.replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">").replacingOccurrences(of: "&quot;", with: "\"").replacingOccurrences(of: "&apos;", with: "'").replacingOccurrences(of: "&amp;", with: "&")
        
        if SettingsData.hiraganaMode {
            text = TextConverter.convertWithCache(text, to: TextConverter.JPCharacter.hiragana)
        }
        
        let attributedText = NSMutableAttributedString(string: text)
        
        // リンクを追加
        for link in linkList {
            var textLength = link.2.count
            if link.0.encodedOffset + textLength > attributedText.length {
                textLength = attributedText.length - link.0.encodedOffset
                if textLength <= 0 { continue }
            }
            attributedText.addAttribute(NSAttributedString.Key.link,
                                        value: link.1,
                                        range: NSRange(location: link.0.encodedOffset,
                                                       length: textLength))
        }
        
        // 絵文字に変える
        if let emojis = emojis {
            for emoji in emojis {
                guard let shortcode = emoji["shortcode"] as? String else { continue }
                let url = emoji["url"] as? String
                
                let attachment = NSTextAttachment()
                attachment.bounds = CGRect(x: 0, y: -3, width: SettingsData.fontSize + 6, height: SettingsData.fontSize + 6)
                
                var execCallback = false
                ImageCache.image(urlStr: url, isTemp: false, isSmall: true, shortcode: shortcode) { image in
                    if execCallback {
                        callback?()
                    } else {
                        attachment.image = image
                        if image.size.width > 0 {
                            attachment.bounds.size = CGSize(width: SettingsData.fontSize + 6, height: image.size.height / image.size.width * SettingsData.fontSize + 6)
                        }
                    }
                }
                if attachment.image == nil {
                    execCallback = true
                }
                
                let attrStr = NSAttributedString(attachment: attachment)
                
                while true {
                    let nsStr = attributedText.string as NSString
                    if !nsStr.contains(":\(shortcode):") { break }
                    let range = nsStr.range(of: ":\(shortcode):")
                    attributedText.replaceCharacters(in: range, with: attrStr)
                }
            }
        }
        
        var hasCard = false
        if linkList.count > 0 {
            for link in linkList {
                if link.2.hasPrefix("#") { continue }
                if link.2.hasPrefix("@") { continue }
                hasCard = true
            }
        } else if text.contains("http://") && text.contains(" href=\"") {
            hasCard = true
        }
        
        return (attributedText, linkList.count > 0, hasCard)
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
        var content = content ?? ""
        
        // プロフィールにimgタグで絵文字が入り込んでくる・・・
        if content.contains("<img ") == true {
            var loopCount = 0
            while let startRange = content.range(of: "<img "), let endRange = content.range(of: ".png\" />"), loopCount < 50 {
                let startIndex = content.index(startRange.lowerBound, offsetBy: 0)
                let endIndex = content.index(endRange.lowerBound, offsetBy: 8)
                
                let tmpEmojiStr = String(content.suffix(from: startIndex))
                if let startRange = tmpEmojiStr.range(of: "\":"), let endRange = tmpEmojiStr.range(of: ":\"") {
                    let startEmojiIndex = tmpEmojiStr.index(startRange.lowerBound, offsetBy: 1)
                    let endEmojiIndex = tmpEmojiStr.index(endRange.lowerBound, offsetBy: 1)
                    let emojiStr = " " + String(tmpEmojiStr.suffix(from: startEmojiIndex).prefix(upTo: endEmojiIndex)) + " "
                        
                    content = String(content.prefix(upTo: startIndex)) + emojiStr + String(content.suffix(from: endIndex))
                }
                
                loopCount += 1
            }
        }
        
        guard let attributedText = parseText2HTML(sourceText: content ) else {
            return (NSMutableAttributedString(string: content), false)
        }
        
        // 絵文字に変える
        if let emojis = emojis {
            for emoji in emojis {
                guard let shortcode = emoji["shortcode"] as? String else { continue }
                let url = emoji["url"] as? String
                
                let attachment = NSTextAttachment()
                attachment.bounds = CGRect(x: 0, y: -3, width: SettingsData.fontSize + 6, height: SettingsData.fontSize + 6)
                var execCallback = false
                ImageCache.image(urlStr: url, isTemp: false, isSmall: true, shortcode: shortcode) { image in
                    if execCallback {
                        callback?()
                    } else {
                        attachment.image = image
                        if image.size.width > 0 {
                            attachment.bounds.size = CGSize(width: SettingsData.fontSize + 6, height: image.size.height / image.size.width * SettingsData.fontSize + 6)
                        }
                    }
                }
                if attachment.image == nil {
                    execCallback = true
                }
                
                let attrStr = NSAttributedString(attachment: attachment)
                
                while true {
                    let nsStr = attributedText.string as NSString
                    if !nsStr.contains(":\(shortcode):") { break }
                    let range = nsStr.range(of: ":\(shortcode):")
                    attributedText.replaceCharacters(in: range, with: attrStr)
                }
            }
        }
        
        let hasLink = (content.contains("<a href") == true)
        
        return (attributedText, hasLink)
    }
    
    // 名前部分の絵文字解析
    static func decodeName(name: String?, emojis: [[String: Any]]?, uiLabel: UILabel? = nil, callback: (()->Void)?) -> NSMutableAttributedString {
        let text = name ?? ""
        
        let attributedText = NSMutableAttributedString(string: text)
        
        if let emojis = emojis {
            for emoji in emojis {
                guard let shortcode = emoji["shortcode"] as? String else { continue }
                if !text.contains(":\(shortcode):") { continue }
                
                let url = emoji["url"] as? String
                
                let attachment = NSTextAttachment()
                attachment.bounds = CGRect(x: 0, y: -3, width: SettingsData.fontSize + 6, height: SettingsData.fontSize + 6)
                var execCallback = false
                ImageCache.image(urlStr: url, isTemp: false, isSmall: true, shortcode: shortcode) { image in
                    if execCallback {
                        callback?()
                    } else {
                        attachment.image = image
                        if image.size.width > 0 {
                            attachment.bounds.size = CGSize(width: SettingsData.fontSize + 6, height: image.size.height / image.size.width * SettingsData.fontSize + 6)
                        }
                    }
                    
                    // カスタム絵文字のアニメーション
                    if let uiLabel = uiLabel, !NormalPNGFileList.isNormal(urlStr: emoji["url"] as? String) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if uiLabel.superview == nil { return }
                            guard let attributedText = uiLabel.attributedText else { return }
                            let list = DecodeToot.getEmojiList(attributedText: attributedText, textStorage: NSTextStorage(attributedString: attributedText))
                            
                            for data in list {
                                for emoji in emojis {
                                    if emoji["shortcode"] as? String == data.1 {
                                        let urlStr = emoji["url"] as? String
                                        APNGImageCache.image(urlStr: urlStr) { image in
                                            if image.frameCount <= 1 {
                                                NormalPNGFileList.add(urlStr: urlStr)
                                                return
                                            }
                                            
                                            let rect: CGRect
                                            do {
                                                let rangeCharacters = data.0
                                                
                                                let tmpLabel = UILabel()
                                                tmpLabel.font = uiLabel.font
                                                
                                                let prevString = attributedText.attributedSubstring(from: NSRange.init(location: 0, length: max(0, rangeCharacters.location - 1)))
                                                tmpLabel.attributedText = prevString
                                                tmpLabel.sizeToFit()
                                                
                                                rect = CGRect(x: tmpLabel.frame.maxX, y: -2, width: SettingsData.fontSize + 6, height: SettingsData.fontSize + 6)
                                            }
                                            
                                            let apngView = APNGImageView(image: image)
                                            apngView.tag = 5555
                                            apngView.autoStartAnimation = true
                                            apngView.backgroundColor = ThemeColor.cellBgColor
                                            apngView.frame = rect
                                            uiLabel.addSubview(apngView)
                                        }
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
                if attachment.image == nil {
                    execCallback = true
                    let dummyImage = EmojiImage()
                    dummyImage.shortcode = shortcode
                    attachment.image = dummyImage
                }
                
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
    static func encodeEmoji(attributedText: NSAttributedString, textStorage: NSTextStorage, isToot: Bool = false) -> String {
        // 絵文字のある場所をリストにする
        var list: [(NSRange, String)] = []
        let range = NSRange(location: 0, length: attributedText.length)
        if (textStorage.containsAttachments(in: range)) {
            let attrString = attributedText
            var location = 0
            while location < range.length {
                var r = NSRange()
                let attrDictionary = attrString.attributes(at: location, effectiveRange: &r)
                let attachment = attrDictionary[NSAttributedString.Key.attachment] as? NSTextAttachment
                if let image = attachment?.image {
                    list.append((r, (image as? EmojiImage)?.shortcode ?? ""))
                }
                location += r.length
            }
        }
        
        // 絵文字から元のコードに置き換える
        let attributedStr = NSMutableAttributedString(attributedString: attributedText)
        for data in list.reversed() {
            if isToot {
                attributedStr.replaceCharacters(in: data.0, with: "\u{200b}:" + data.1 + ":\u{200b}")
            } else {
                attributedStr.replaceCharacters(in: data.0, with: ":" + data.1 + ":")
            }
        }
        
        // 連続するゼロ幅スペースを1つにする
        var str = attributedStr.string
        str = str.replacingOccurrences(of: "\u{200b}\u{200b}", with: "\u{200b}")
        
        return str
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
                let attachment = attrDictionary[NSAttributedString.Key.attachment] as? NSTextAttachment
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
