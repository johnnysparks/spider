//
//  UIView+Extensions.swift
//  spider
//
//  Created by Johnny Sparks  on 4/21/19.
//  Copyright © 2019 Johnny Sparks . All rights reserved.
//

import UIKit

extension UIView {
    var topLeftPoint: CGPoint { return frame.origin }
    var topRightPoint: CGPoint { return CGPoint(x: frame.minX, y: frame.maxY) }
    var bottomLeftPoint: CGPoint { return CGPoint(x: frame.maxX, y: frame.minY) }
    var bottomRightPoint: CGPoint { return CGPoint(x: frame.maxX, y: frame.maxY) }
}
