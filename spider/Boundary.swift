//
//  Boundary.swift
//  spider
//
//  Created by Johnny Sparks  on 4/21/19.
//  Copyright © 2019 Johnny Sparks . All rights reserved.
//

import Foundation

enum Boundary: String {
    case top = "top"
    case left = "left"
    case bottom = "bottom"
    case right = "right"

    var identifier: NSString {
        return self.rawValue as NSString
    }

    static func from(_ identifier: NSCopying?) -> Boundary? {
        guard let string = identifier as? NSString else {
            return nil
        }

        return Boundary(rawValue: string as String)
    }
}
