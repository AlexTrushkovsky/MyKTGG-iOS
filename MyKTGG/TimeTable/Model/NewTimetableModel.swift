//
//  NewTimetableModel.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 25.12.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import Foundation

struct TimetableRoot: Codable {
    var item: [Item]?
}
struct Item: Codable {
    var group, date, comment, lessonName, lessonTime, lessonDescription, lessonNumber: String?
}
