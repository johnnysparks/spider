//
//  SpiderView.swift
//  spider
//
//  Created by Johnny Sparks  on 4/21/19.
//  Copyright © 2019 Johnny Sparks . All rights reserved.
//

import UIKit

class SpiderView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundColor = .white
        self.layer.cornerRadius = self.bounds.height * 0.5
    }
}
