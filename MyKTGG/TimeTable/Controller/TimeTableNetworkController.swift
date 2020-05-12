//
//  File.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 08.05.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import Foundation
import Alamofire

class TimeTableNetworkController {
    
    var timeTableRoot = TimeTableRoot()
    var newVar = TimeTableRoot()
    var lessonCount = 0
    var fri = [Fri]()
    var subGroup = Subgroup()
    var week = Week()
    var timeTable = Timetable()
    
    public func fetchData(tableView: UITableView, pickedDate: Date){
        guard let group = UserDefaults.standard.object(forKey: "group") as? String else { return }
        let jsonUrlString = "http://217.76.201.219:5000/\(transliterate(nonLatin: group))"
        guard let url = URL(string: jsonUrlString) else { return }
        print("Starting to fetch data from \(jsonUrlString)")
        //Alamofire request
        let alamofireSession = AF.request(url, method: .get)
        alamofireSession.validate()
        alamofireSession.responseJSON { response in
            switch response.result {
            case .success:
                print("Validation Successful")
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                do {
                    let timeTableRoot = try decoder.decode(TimeTableRoot.self, from: response.data!)
                    self.newVar = timeTableRoot
                    self.timeTable = self.newVar.timetable!
                    //MARK: SubGroup pick
                    guard let subGroup = UserDefaults.standard.object(forKey: "subGroup") as? Int else { return }
                    self.subGroup = self.timeTable.firstsubgroup!
                    if subGroup == 1 { self.subGroup = self.timeTable.secondsubgroup! }
                    //self.getInfo(date: pickedDate)
                    self.week = self.subGroup.firstweek!
                    
                    DispatchQueue.main.async {
                        print("Data saved")
                        tableView.reloadData()
                    }
                }catch{
                    print("Failed to convert Data!")
                }
                
            case let .failure(error):
                print("Failed to get JSON: ",error)
            }
        }
    }
    
    func getInfo(date: Date) {
        //MARK: Day pick
        let calendar = Calendar(identifier: .gregorian)
        let weekday = calendar.component(.weekday, from: date)
        print("day: \(weekday)")
        switch weekday {
        case 1:
            if let fri = week.sun {
                self.fri = fri
                lessonCount = fri.count
            } else {
                lessonCount = 0
            }
        case 2:
            if let fri = week.mon {
                self.fri = fri
                lessonCount = fri.count
            } else {
                lessonCount = 0
            }
        case 3:
            if let fri = week.tue {
                self.fri = fri
                lessonCount = fri.count
            } else {
                lessonCount = 0
            }
        case 4:
            if let fri = week.wed {
                self.fri = fri
                lessonCount = fri.count
            } else {
                lessonCount = 0
            }
        case 5:
            if let fri = week.thu {
                self.fri = fri
                lessonCount = fri.count
            } else {
                lessonCount = 0
            }
        case 6:
            if let fri = week.fri{
                self.fri = fri
                lessonCount = fri.count
            } else {
                lessonCount = 0
            }
        case 7:
            if let fri = week.sat {
                self.fri = fri
                lessonCount = fri.count
            } else {
                lessonCount = 0
            }
        default:
            print("weekDay undefined")
        }
        print("Lessons: ",lessonCount)
    }
    
    func configureCell(cell: TimeTableCell, for indexPath: IndexPath, date: Date) {
        print("cell configuring...")
        if let lesson = fri[indexPath.row].lesson{
            cell.lessonName.text = lesson
        }
        
        if let room = fri[indexPath.row].room {
            cell.lessonRoom.text = room
        }
        
        if let teacher = fri[indexPath.row].teacher {
            cell.teacher.text = teacher
        }
        
        switch fri[indexPath.row].lessonNum {
        case "1":
            cell.startTime.text = "09:00"
            cell.endTime.text = "10:20"
        case "2":
            cell.startTime.text = "10:30"
            cell.endTime.text = "11:50"
        case "3":
            cell.startTime.text = "12:20"
            cell.endTime.text = "13:40"
        case "4":
            cell.startTime.text = "13:50"
            cell.endTime.text = "15:10"
        case "5":
            cell.startTime.text = "15:20"
            cell.endTime.text = "16:40"
        case "6":
            cell.startTime.text = "16:50"
            cell.endTime.text = "18:10"
        default:
            cell.startTime.text = "00:00"
            cell.endTime.text = "00:00"
        }
    }
    
    
    func transliterate(nonLatin: String) -> String {
        let mut = NSMutableString(string: nonLatin) as CFMutableString
        CFStringTransform(mut, nil, "Any-Latin; Latin-ASCII; Any-Lower;" as CFString, false)
        return (mut as String).replacingOccurrences(of: " ", with: "-")
    }
}

