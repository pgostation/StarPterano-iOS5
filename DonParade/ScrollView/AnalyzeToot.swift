//
//  AnalyzeToot.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/17.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// トゥートのHTML文字列を解析して、本文、リンク付き本文、絵文字リストに分解する

import Foundation

final class AnalyzeToot {
    static func analyzeContent(content: String?) -> (NSMutableAttributedString, [String]) {
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
        
        // 絵文字を空白に変換
        for (index, char) in text.enumerated() {
            if char == ":" {
                var emojiStr = ""
                for endIndex in index + 1..<text.count {
                    let endChar = text[text.index(text.startIndex, offsetBy: endIndex)..<text.index(text.startIndex, offsetBy: endIndex + 1)]
                    if let endChar1 = endChar.first {
                        if endChar1 == ":" {
                            // サーバの絵文字リストと一致して入れば絵文字とする
                            //####
                        }
                        else if endChar1 >= "a" && endChar1 <= "z" || endChar1 == "_" {
                            //
                            emojiStr += String(endChar1)
                        } else {
                            // 間に英小文字と_以外があれば、この「:」は無視する
                            break
                        }
                    }
                }
            }
        }
        
        // &lt;などをデコード
        text = text.replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">").replacingOccurrences(of: "&amp;", with: "&")
        
        let attributedText = NSMutableAttributedString(string: text)
        let emojiList: [String] = []
        
        return (attributedText, emojiList)
    }
}
