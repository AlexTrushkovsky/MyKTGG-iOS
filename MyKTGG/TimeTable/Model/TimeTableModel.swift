//
//  TimeTableModel.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 04.05.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import Foundation

struct TimeTableJsonRoot: Codable {
    let timetable: Timetable?
}

struct Timetable: Codable {
    let firstsubgroup, secondsubgroup: Subgroup?
}

struct Subgroup: Codable {
    let firstweek, secondweek: [Week]?
}

struct Week: Codable {
    let group: String?
    let day: [Day]?
}

struct Day: Codable {
    let mon, tue, wed, thu: [[String: Fri]]?
    let fri, sun, sat: [[String: Fri]]?
}

struct Fri: Codable {
    let lesson, teacher, room: String?
}
