//
//  TextConverter.swift
//  DonParade
//
//  Created by takayoshi on 2019/02/03.
//  Copyright © 2019 pgostation. All rights reserved.
//

// https://qiita.com/sgr-ksmt/items/cc8882aa80a59e5a8355

import Foundation

final class TextConverter {
    private init() {}
    enum JPCharacter {
        case hiragana
        case katakana
        fileprivate var transform: CFString {
            switch self {
            case .hiragana:
                return kCFStringTransformLatinHiragana
            case .katakana:
                return kCFStringTransformLatinKatakana
            }
        }
    }
    
    private static var cache: [String: String] = [:]
    private static var oldCache: [String: String] = [:]
    
    static func convertWithCache(_ text: String, to jpCharacter: JPCharacter) -> String {
        if let cacheStr = cache[text] {
            return cacheStr
        }
        if let cacheStr = oldCache[text] {
            return cacheStr
        }
        
        let converted = convert(text, to: jpCharacter)
        
        cache[text] = converted
        
        if cache.count > 50 {
            oldCache = cache
            cache = [:]
        }
        
        return converted
    }
    
    private static func convert(_ text: String, to jpCharacter: JPCharacter) -> String {
        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var output = ""
        let locale = CFLocaleCreate(kCFAllocatorDefault, CFLocaleCreateCanonicalLanguageIdentifierFromString(kCFAllocatorDefault, "ja" as CFString))
        let range = CFRangeMake(0, input.utf16.count)
        let tokenizer = CFStringTokenizerCreate(
            kCFAllocatorDefault,
            input as CFString,
            range,
            kCFStringTokenizerUnitWordBoundary,
            locale
        )
        
        var tokenType = CFStringTokenizerGoToTokenAtIndex(tokenizer, 0)
        while (tokenType.rawValue != 0) {
            if let text = (CFStringTokenizerCopyCurrentTokenAttribute(tokenizer, kCFStringTokenizerAttributeLatinTranscription) as? NSString).map({ $0.mutableCopy() }) {
                CFStringTransform((text as! CFMutableString), nil, jpCharacter.transform, false)
                output.append(text as! String)
                output.append(" ") // 区切りに空白を入れる
            }
            tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        }
        return output
    }
}
