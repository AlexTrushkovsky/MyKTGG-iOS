import UIKit
import Alamofire

class NewTimetableController {
    
    
    var timeTableRoot = TimetableRoot()
    var newVar = TimetableRoot()
    var lessonCount = 0
    var item = [Item]()
    
    public func fetchData(tableView: UITableView, pickedDate: Date){
        let semaphore = DispatchSemaphore (value: 0)
        let stringPickedDate = pickedDate.toString(dateFormat: "dd.MM.yyyy")
        let parameters = "{\n    \"to\":\"eRVs75zrFUw-kl6gzqszEK:APA91bH4WbX_KzcMdRBXvCk9W8iAizSO60fxfGHW0It_t2HDpd1J4pJth3_GQ-apHVNhUW0mwDsfNzti12Da6vj1kWWEeKYgILLmHRh0caxu-6B4m7XXN16-J8v7iQXkrv2WN9DKL3x2\",\n    \"notification\": {\n        \"body\":\"Test\",\n        \"title\":\"Test\"\n    }\n}"
        let postData = parameters.data(using: .windowsCP1251)
        
        guard let group = UserDefaults.standard.object(forKey: "group") as? String else { return }
        guard let encodedGroup = (group as NSString).addingPercentEscapes(using: String.Encoding.windowsCP1251.rawValue) else { return }
        
        var request = URLRequest(url: URL(string: "http://217.76.201.218/cgi-bin/timetable_export.cgi?req_type=rozklad&req_mode=group&req_format=json&begin_date=\(stringPickedDate)&end_date=\(stringPickedDate)&bs=ok&OBJ_name=\(encodedGroup)")!,timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("key=AAAAgPiWVp0:APA91bGLjDDlC-4RnJ_6OwoEacDvLFo1Y1bcEJTfl0H4u16pBIMGZE047vLatzzzBhXf-WNemJC-ePH7nwrQ6x_3-Hku8-H7bEYZ4zkoOHgdNhfevze60zzhvOSClfiJ1MYushqzZgr8", forHTTPHeaderField: "Authorization")
        
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print(String(describing: error))
                return
            }
            let dataString = String(data: data, encoding: .windowsCP1251)!
            let formattedJson = self.formatJson(str: dataString)
            print(String(data: data, encoding: .windowsCP1251)!)
            guard let formattedJsonData = formattedJson.data(using: .utf8) else { return }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                let timeTableRoot = try decoder.decode(TimetableRoot.self, from: formattedJsonData)
                self.newVar = timeTableRoot
                self.item = self.newVar.item!
            }catch{
                print("TimeTable: Failed to convert Data!")
                self.deinitModel()
                tableView.reloadData()
            }
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        
    }
    
    func formatJson(str: String) -> String {
        let st = ", \"item\":"
        let srt = "}}"
        var result = str.replacingOccurrences(of: st, with: ",")
        result = result.replacingOccurrences(of: "\"item\": {", with: "\"item\": [{")
        result = result.replacingOccurrences(of: srt, with: "}]}")
        return result
    }
    
    
    //    func getWeekNum(date: Date){
    //        print("get week num")
    //        let calendar = Calendar(identifier: .gregorian)
    //        let firstOfSep = DateComponents(month: 9, day: 1)
    //        guard let firstOfSepDate = calendar.date(from: firstOfSep) else { return }
    //        let weekOfFirstOfSep = calendar.component(.weekOfYear, from: firstOfSepDate)
    //        let pickedDateWeekday = calendar.component(.weekOfYear, from: date)
    //        if pickedDateWeekday >= weekOfFirstOfSep && pickedDateWeekday <= 53{
    //            if (pickedDateWeekday - weekOfFirstOfSep) % 2 == 0 {
    //                self.week = self.subGroup.firstweek!
    //            } else {
    //                self.week = self.subGroup.secondweek!
    //            }
    //        } else {
    //            if (53 - 36 + pickedDateWeekday) % 2 == 0 {
    //                self.week = self.subGroup.secondweek!
    //            } else {
    //                self.week = self.subGroup.firstweek!
    //            }
    //        }
    //
    //    }
    
    //    func getSubGroup(){
    //        print("get sub sroup")
    //        //MARK: subGroup pick
    //        guard let subGroup = UserDefaults.standard.object(forKey: "subGroup") as? Int else { return }
    //        self.subGroup = self.timeTable.firstsubgroup!
    //        if subGroup == 1 { self.subGroup = self.timeTable.secondsubgroup! }
    //    }
    //
    //    func checkAdditionalLessons(date: Date) {
    //        print("checkaddlessons")
    //        if date.ignoringTime == change.day.ignoringTime {
    //            guard let changes = change.change.para else { return }
    //            let intChanges = changes.map { Int($0.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789").inverted))!}
    //            for change in intChanges {
    //                if lessonCount < change {
    //                    let add = Fri(lessonNum: String(change), lesson: "", teacher: "", room: "")
    //                    self.fri.append(add)
    //                    lessonCount+=1
    //                }
    //            }
    //        }
    //    }
    
    func getInfo(date: Date) {
        print("get info")
        //MARK: Day pick
        lessonCount = 0
        
        item.removeAll { value in
            return value.lessonDescription == ""
        }
        
        for lesson in item {
            if let stringDate = lesson.date {
                let newDate = stringDate.toDate(withFormat: "dd.MM.yyyy")
                if date.ignoringTime == newDate!.ignoringTime {
                    if let lessonNum = Int(lesson.lessonNumber ?? "0") {
                        if lessonNum > 0  && lesson.lessonDescription != nil && lesson.lessonDescription != ""{
                            lessonCount += 1
                        }
                    }
                } else {
                    print("picked data: \(date.ignoringTime)")
                    print("new data: \(newDate!.ignoringTime)")
                }
            }
        }
        //
        //        switch weekday {
        //        case 1:
        //            if let fri = week.sun {
        //                self.fri = fri
        //                lessonCount = fri.count
        //            } else {
        //                lessonCount = 0
        //            }
        //        case 2:
        //            if let fri = week.mon {
        //                self.fri = fri
        //                lessonCount = fri.count
        //            } else {
        //                lessonCount = 0
        //            }
        //        case 3:
        //            if let fri = week.tue {
        //                self.fri = fri
        //                lessonCount = fri.count
        //            } else {
        //                lessonCount = 0
        //            }
        //        case 4:
        //            if let fri = week.wed {
        //                self.fri = fri
        //                lessonCount = fri.count
        //            } else {
        //                lessonCount = 0
        //            }
        //        case 5:
        //            if let fri = week.thu {
        //                self.fri = fri
        //                lessonCount = fri.count
        //            } else {
        //                lessonCount = 0
        //            }
        //        case 6:
        //            if let fri = week.fri{
        //                self.fri = fri
        //                lessonCount = fri.count
        //            } else {
        //                lessonCount = 0
        //            }
        //        case 7:
        //            if let fri = week.sat {
        //                self.fri = fri
        //                lessonCount = fri.count
        //            } else {
        //                lessonCount = 0
        //            }
        //        default:
        //            print("weekDay undefined")
        //        }
        //        checkAdditionalLessons(date: date)
    }
    
    func deinitModel() {
        print("deinit model")
        self.timeTableRoot = TimetableRoot()
        self.newVar = TimetableRoot()
        self.lessonCount = 0
        self.item = [Item]()
    }
    
    func formatCellToChange(cell: TimeTableCell) {
        cell.lessonView.backgroundColor = UIColor(red: 1.00, green: 0.76, blue: 0.47, alpha: 1.00)
        cell.lessonRoom.isHidden = true
        cell.roomImage.isHidden = true
    }
    func formatCellToLesson(cell: TimeTableCell) {
        cell.lessonView.backgroundColor = UIColor(red: 0.30, green: 0.77, blue: 0.57, alpha: 1.00)
        cell.lessonRoom.isHidden = false
        cell.roomImage.isHidden = false
    }
    
    func configureCell(cell: TimeTableCell, for indexPath: IndexPath, date: Date) {
        print("TT: config cell")
        lessonCount = 0
        formatCellToLesson(cell: cell)
        if let stringDate = item[indexPath.row].date {
            let newDate = stringDate.toDate(withFormat: "dd.MM.yyyy")
            if date.ignoringTime == newDate!.ignoringTime {
                if var lesson = item[indexPath.row].lessonDescription{
                    lesson = lesson.replacingOccurrences(of: "<br>", with: "&")
                    print("Main: \(lesson)")
                    let countofOpenBrackets = lesson.filter { $0 == "(" }.count
                    // Without subgroup
                    if countofOpenBrackets == 1 {
                        
                        if let whitespaceAfterRoom = lesson.firstIndex(of: "&") {
                            let room = String(lesson.prefix(upTo: whitespaceAfterRoom)) // Room founded
                            cell.lessonRoom.text = room
                            print("room\(room)")
                            let teacherAndLessonDesk = String(lesson.suffix(from: lesson.index(whitespaceAfterRoom, offsetBy: 1))).replacingOccurrences(of: "  ", with: "|")
                            print("numOfOpenBrackets: \(countofOpenBrackets)")
                            if let stickAfterTeacher = teacherAndLessonDesk.firstIndex(of: "|") {
                                let teacher = teacherAndLessonDesk.prefix(upTo: stickAfterTeacher) // Teacher founded
                                cell.teacher.text = String(teacher)
                                print("teacher\(teacher)")
                                
                                let subGroupAndLesson = String(teacherAndLessonDesk.suffix(from: teacherAndLessonDesk.index(stickAfterTeacher, offsetBy: 1)))
                                print("subGroupAndLesson: \(subGroupAndLesson)")
                                if let symbolAfterSubgroup = subGroupAndLesson.firstIndex(of: "&") {
                                    let lesson = String(subGroupAndLesson.prefix(upTo: symbolAfterSubgroup)) // Subgroup founded
                                    print("lesson: \(lesson)")
                                    cell.lessonName.text = String(lesson)
                                }
                            }
                        }
                    } else if countofOpenBrackets == 2 {
                        print("With subgroup but 1 lesson")
                        
                    } else if countofOpenBrackets == 4 {
                        
                        if let whitespaceAfterRoom = lesson.firstIndex(of: "&") {
                            let room = String(lesson.prefix(upTo: whitespaceAfterRoom)) // Room founded
                            cell.lessonRoom.text = room
                            print("room\(room)")
                            let teacherAndLessonDesk = String(lesson.suffix(from: lesson.index(whitespaceAfterRoom, offsetBy: 1))).replacingOccurrences(of: "  ", with: "|")
                            let countofOpenBrackets = teacherAndLessonDesk.filter { $0 == "(" }.count
                            print("numOfOpenBrackets: \(countofOpenBrackets)")
                            if let stickAfterTeacher = teacherAndLessonDesk.firstIndex(of: "|") {
                                let teacher = teacherAndLessonDesk.prefix(upTo: stickAfterTeacher) // Teacher founded
                                cell.teacher.text = String(teacher)
                                print("teacher\(teacher)")
                                
                                let subGroupAndLesson = String(teacherAndLessonDesk.suffix(from: teacherAndLessonDesk.index(stickAfterTeacher, offsetBy: 1)))
                                print(subGroupAndLesson)
                                if let symbolAfterSubgroup = subGroupAndLesson.firstIndex(of: "&") {
                                    let subgroup = String(subGroupAndLesson.prefix(upTo: symbolAfterSubgroup)) // Subgroup founded
                                    print("subgroup\(subgroup)")
                                    let lessonAndNextLesson = String(subGroupAndLesson.suffix(from: subGroupAndLesson.index(symbolAfterSubgroup, offsetBy: 1)))
                                    print("lessonAndNextLesson\(lessonAndNextLesson)")
                                    if let symbolAfterLesson = lessonAndNextLesson.firstIndex(of: "&") {
                                        if lessonAndNextLesson.contains("&") {
                                            let lesson = String(lessonAndNextLesson.prefix(upTo: symbolAfterLesson))
                                            print("lesson: \(lesson)")
                                            cell.lessonName.text = String(lesson)
                                        } else {
                                            print("no next lesson")
                                            cell.lessonName.text = String(lessonAndNextLesson.replacingOccurrences(of: "&", with: ""))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if let lessontime = item[indexPath.row].lessonTime {
                        if let index = lessontime.firstIndex(of: "-") {
                            let firstPart = lessontime.prefix(upTo: index)
                            let secondPart = lessontime.suffix(from: lessontime.index(index, offsetBy: 1))
                            cell.startTime.text = String(firstPart)
                            cell.endTime.text = String(secondPart)
                        }
                    }
                } else {
                    print("picked data: \(date)")
                    print("new data: \(newDate)")
                }
            }
            //        if date.ignoringTime == change.day.ignoringTime {
            //            if let lesson = change.change.para {
            //                if indexPath.row >= 0 && indexPath.row < lessonCount {
            //                    for item in 0..<lesson.count {
            //                        let changeNum = lesson[item].trimmingCharacters(in: CharacterSet(charactersIn: "0123456789").inverted)
            //                        if fri[indexPath.row].lessonNum! == changeNum {
            //                            formatCellToChange(cell: cell)
            //                            if let lesson = change.change.disChange?[item]{
            //                                cell.lessonName.text = lesson
            //                            }
            //                            if let teacher = change.change.teacherChange?[item] {
            //                                cell.teacher.text = teacher
            //                            }
            //                        }
            //                    }
            //                }
            //            }
            //        }
            
        }
        
    }
}
