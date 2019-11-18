//
//  UIColor+RGB.swift
//  Wave
//
//  Created by YH Kung on 2019/3/28.
//  Copyright © 2019 WaveRadio. All rights reserved.
//

import UIKit

extension UIColor {

    convenience init(r: Int, g: Int, b: Int) {
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
    }

    convenience init(rgb: Int) {
        self.init(
            r: (rgb >> 16) & 0xFF,
            g: (rgb >> 8) & 0xFF,
            b: rgb & 0xFF
        )
    }

    convenience init(w: Int) {
        self.init(r: w, g: w, b: w)
    }

    static var randomLight: UIColor {
        return UIColor(
            r: 240 - Int(arc4random_uniform(40)),
            g: 240 - Int(arc4random_uniform(40)),
            b: 240 - Int(arc4random_uniform(40))
        )
    }

    static var randomDark: UIColor {
        return UIColor(
            r: 15 + Int(arc4random_uniform(40)),
            g: 15 + Int(arc4random_uniform(40)),
            b: 15 + Int(arc4random_uniform(40))
        )
    }

}
