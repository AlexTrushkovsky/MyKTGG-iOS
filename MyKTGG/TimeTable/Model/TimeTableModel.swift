// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let timeTableRoot = try? newJSONDecoder().decode(TimeTableRoot.self, from: jsonData)

import Foundation

// MARK: - TimeTableRoot
struct TimeTableRoot: Codable {
    var timetable: Timetable?
}

// MARK: - Timetable
struct Timetable: Codable {
    var firstsubgroup, secondsubgroup: Subgroup?
}

// MARK: - Subgroup
struct Subgroup: Codable {
    var firstweek, secondweek: [Week]?
}

// MARK: - Week
struct Week: Codable {
    var mon, tue, wed, thu: [Fri]?
    var fri, sun, sat: [Fri]?
}

// MARK: - Fri
struct Fri: Codable {
    var lessonNum, lesson, teacher, room: String?
}
