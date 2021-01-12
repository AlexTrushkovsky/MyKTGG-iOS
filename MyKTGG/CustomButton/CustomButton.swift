//
//  CustomButton.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 06.01.2021.
//  Copyright © 2021 Алексей Трушковский. All rights reserved.
//

import UIKit

class CustomButton {
    static func UIColorFromRGB(_ rgbValue: Int) -> UIColor {
        return UIColor(red: ((CGFloat)((rgbValue & 0xFF0000) >> 16))/255.0, green: ((CGFloat)((rgbValue & 0x00FF00) >> 8))/255.0, blue: ((CGFloat)((rgbValue & 0x0000FF)))/255.0, alpha: 1.0)
    }
}

