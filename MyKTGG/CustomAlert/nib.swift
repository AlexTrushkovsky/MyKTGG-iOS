//
//  nib.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 04.08.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    class func loadFromNib<T: UIView>() -> T {
        return Bundle.main.loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
}
