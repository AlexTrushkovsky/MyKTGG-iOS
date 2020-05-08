//
//  ChangeModel.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 04.05.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import Foundation

struct Change: Codable {
    let date: String?
    let dis, disChange, group, para: [String]?
    let teacher, teacherChange: [String]?
}
