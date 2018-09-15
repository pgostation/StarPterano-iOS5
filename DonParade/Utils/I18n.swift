//
//  I18n.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/15.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import Foundation

final class I18n {
    static func get(_ text: String) -> String {
        return NSLocalizedString(text, comment: "")
    }
}
