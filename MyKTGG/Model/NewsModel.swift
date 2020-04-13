//
//  News.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 12.04.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import Foundation
struct Items: Decodable {
    var title: String?
    var introtext: String?
    var created: String?
    var imageMedium: String?
    var category: Category?
    var link: String?
}
struct Category: Decodable {
    var name: String?
}
struct Root: Decodable {
    var items: [Items]?
}
