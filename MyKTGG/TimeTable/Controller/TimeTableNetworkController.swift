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
    var timetable = Timetable()
    var subgroup = Subgroup()
    var week = Week()
    var fri = Fri()
    
    public func fetchData(){
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
                    self.timeTableRoot = try decoder.decode(TimeTableRoot.self, from: response.data!)
                    //print(response)
                   dump(self.timeTableRoot)
                    DispatchQueue.main.async {
                        print("Data saved")
                    }
                }catch{
                    print("Failed to convert Data!")
                }
                
            case let .failure(error):
                print("Failed to get JSON: ",error)
            }
        }
    }
    
    func configureCell(cell: TimeTableCell, for indexPath: IndexPath) {
        print("cell configuring...")
        timetable = timeTableRoot.timetable!
        //MARK: make subgroups
        subgroup = timetable.firstsubgroup!
        //MARK: make weeksChange
        week = subgroup.firstweek![indexPath.row]
        fri = week.mon![indexPath.row]

        if let lesson = fri.lesson{
            cell.lessonName.text = lesson
        }

        if let room = fri.room {
            cell.lessonRoom.text = room
        }

        if let teacher = fri.teacher {
            cell.teacher.text = teacher
        }
    }
        
    
    func transliterate(nonLatin: String) -> String {
        let mut = NSMutableString(string: nonLatin) as CFMutableString
        CFStringTransform(mut, nil, "Any-Latin; Latin-ASCII; Any-Lower;" as CFString, false)
        return (mut as String).replacingOccurrences(of: " ", with: "-")
    }
}
