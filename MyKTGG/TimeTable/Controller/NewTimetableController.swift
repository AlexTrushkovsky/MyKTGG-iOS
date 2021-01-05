import UIKit
import Alamofire

class NewTimetableController {
    
    var timeTableRoot = TimetableRoot()
    var newVar = TimetableRoot()
    var lessonCount = 0
    var item = [Item]()
    
    public func fetchData(pickedDate: Date, group: String){
        let semaphore = DispatchSemaphore (value: 0)
        let stringPickedDate = pickedDate.toString(dateFormat: "dd.MM.yyyy")
        let parameters = "{\n    \"to\":\"eRVs75zrFUw-kl6gzqszEK:APA91bH4WbX_KzcMdRBXvCk9W8iAizSO60fxfGHW0It_t2HDpd1J4pJth3_GQ-apHVNhUW0mwDsfNzti12Da6vj1kWWEeKYgILLmHRh0caxu-6B4m7XXN16-J8v7iQXkrv2WN9DKL3x2\",\n    \"notification\": {\n        \"body\":\"Test\",\n        \"title\":\"Test\"\n    }\n}"
        let postData = parameters.data(using: .windowsCP1251)
    
        guard let encodedGroup = (group as NSString).addingPercentEscapes(using: String.Encoding.windowsCP1251.rawValue) else { return }
        
        var request = URLRequest(url: URL(string: "http://217.76.201.218/cgi-bin/timetable_export.cgi?req_type=rozklad&req_mode=group&req_format=json&begin_date=\(stringPickedDate)&end_date=\(stringPickedDate)&bs=ok&OBJ_name=\(encodedGroup)")!,timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("key=AAAAgPiWVp0:APA91bGLjDDlC-4RnJ_6OwoEacDvLFo1Y1bcEJTfl0H4u16pBIMGZE047vLatzzzBhXf-WNemJC-ePH7nwrQ6x_3-Hku8-H7bEYZ4zkoOHgdNhfevze60zzhvOSClfiJ1MYushqzZgr8", forHTTPHeaderField: "Authorization")
        
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print("Failed to get JSON: \(String(describing: error))")
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showNoConnectionWithServer"), object: nil)
                self.deinitModel()
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
    }
    func formatCellToLesson(cell: TimeTableCell) {
        cell.lessonView.backgroundColor = UIColor(red: 0.30, green: 0.77, blue: 0.57, alpha: 1.00)
    }
    
    func configureCell(cell: TimeTableCell, for indexPath: IndexPath, date: Date) {
        print("TT: config cell")
        cell.roomImage.isHidden = false
        cell.lessonRoom.isHidden = false
        cell.teacher.isHidden = false
        cell.teacherImage.isHidden = false
        lessonCount = 0
        if let stringDate = item[indexPath.row].date {
            let newDate = stringDate.toDate(withFormat: "dd.MM.yyyy")
            if date.ignoringTime == newDate!.ignoringTime {
                if var lesson = item[indexPath.row].lessonDescription {
                    
                    if isTZ(lesson: lesson) {
                        formatCellToChange(cell: cell)
                        lesson = lesson.replacingOccurrences(of: "Увага! Заміна!", with: "")
                        var newLesson = lesson.components(separatedBy: "замість:")[0]
                        var oldLesson = lesson.components(separatedBy: "замість:")[1]
                        print("NL: \(newLesson)")
                        print("OLDL: \(oldLesson)")
                        if isT3(lesson: newLesson) {
                            
                        } else if isT2(lesson: newLesson) {
                            let room = newLesson.components(separatedBy: "<br>")[0]
                            newLesson = newLesson.replacingOccurrences(of: "\(room)<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                            let teacher = "\(newLesson.components(separatedBy: ".")[0]).\(newLesson.components(separatedBy: ".")[1]).".trimmingCharacters(in: .whitespacesAndNewlines)
                            newLesson = newLesson.replacingOccurrences(of: teacher, with: "")
                            let subgroup = newLesson.components(separatedBy: "<br>")[0].trimmingCharacters(in: .whitespacesAndNewlines)
                            newLesson = newLesson.components(separatedBy: "<br>")[1]
                            let lesson = newLesson.replacingOccurrences(of: "<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                            print("subgroup:\(subgroup)")
                            print("lesson:\(lesson)")
                            cell.lessonName.text = lesson
                            print("teacher:\(teacher)")
                            cell.teacher.text = teacher
                            print("room:\(room)")
                            cell.lessonRoom.text = room
                        } else if isT1(lesson: newLesson) {
                            let room = newLesson.components(separatedBy: "<br>")[0]
                            newLesson = newLesson.replacingOccurrences(of: "\(room)<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                            let teacher = "\(newLesson.components(separatedBy: ".")[0]).\(newLesson.components(separatedBy: ".")[1]).".trimmingCharacters(in: .whitespacesAndNewlines)
                            newLesson = newLesson.replacingOccurrences(of: teacher, with: "")
                            let lesson = newLesson.replacingOccurrences(of: "<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                            print("lesson:\(lesson)")
                            cell.lessonName.text = lesson
                            print("teacher:\(teacher)")
                            cell.teacher.text = teacher
                            print("room:\(room)")
                            cell.lessonRoom.text = room
                        } else {
                            cell.lessonName.text = newLesson.replacingOccurrences(of: "<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                            cell.roomImage.isHidden = true
                            cell.lessonRoom.isHidden = true
                            cell.teacher.isHidden = true
                            cell.teacherImage.isHidden = true
                        }
                        
                    } else {
                        formatCellToLesson(cell: cell)
                        if isT3(lesson: lesson) {
                            var firstPart = lesson.components(separatedBy: "<br> <br>")[0]
                            let secondPart = lesson.components(separatedBy: "<br> <br>")[1]
                            print("firstPart of t3:\(firstPart)")
                            print("secondPart of t3:\(secondPart)")
                            if isT2(lesson: "\(firstPart)<br>") {
                                let room = firstPart.components(separatedBy: "<br>")[0]
                                firstPart = firstPart.replacingOccurrences(of: "\(room)<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                                let teacher = "\(firstPart.components(separatedBy: ".")[0]).\(lesson.components(separatedBy: ".")[1]).".trimmingCharacters(in: .whitespacesAndNewlines)
                                firstPart = firstPart.replacingOccurrences(of: teacher, with: "")
                                let subgroup = firstPart.components(separatedBy: "<br>")[0].trimmingCharacters(in: .whitespacesAndNewlines)
                                firstPart = firstPart.components(separatedBy: "<br>")[1]
                                let lesson = firstPart.replacingOccurrences(of: "<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                                print("subgroup:\(subgroup)")
                                print("lesson:\(lesson)")
                                cell.lessonName.text = lesson
                                print("teacher:\(teacher)")
                                cell.teacher.text = teacher
                                print("room:\(room)")
                                cell.lessonRoom.text = room
                            }
                        } else if isT2(lesson: lesson) {
                            let room = lesson.components(separatedBy: "<br>")[0]
                            lesson = lesson.replacingOccurrences(of: "\(room)<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                            let teacher = "\(lesson.components(separatedBy: ".")[0]).\(lesson.components(separatedBy: ".")[1]).".trimmingCharacters(in: .whitespacesAndNewlines)
                            lesson = lesson.replacingOccurrences(of: teacher, with: "")
                            let subgroup = lesson.components(separatedBy: "<br>")[0].trimmingCharacters(in: .whitespacesAndNewlines)
                            lesson = lesson.components(separatedBy: "<br>")[1]
                            let lesson = lesson.replacingOccurrences(of: "<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                            print("subgroup:\(subgroup)")
                            print("lesson:\(lesson)")
                            cell.lessonName.text = lesson
                            print("teacher:\(teacher)")
                            cell.teacher.text = teacher
                            print("room:\(room)")
                            cell.lessonRoom.text = room
                        } else if isT1(lesson: lesson) {
                            let room = lesson.components(separatedBy: "<br>")[0]
                            lesson = lesson.replacingOccurrences(of: "\(room)<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                            let teacher = "\(lesson.components(separatedBy: ".")[0]).\(lesson.components(separatedBy: ".")[1]).".trimmingCharacters(in: .whitespacesAndNewlines)
                            lesson = lesson.replacingOccurrences(of: teacher, with: "")
                            let lesson = lesson.replacingOccurrences(of: "<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                            print("lesson:\(lesson)")
                            cell.lessonName.text = lesson
                            print("teacher:\(teacher)")
                            cell.teacher.text = teacher
                            print("room:\(room)")
                            cell.lessonRoom.text = room
                        } else {
                            cell.lessonName.text = lesson.replacingOccurrences(of: "<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                            cell.roomImage.isHidden = true
                            cell.lessonRoom.isHidden = true
                            cell.teacher.isHidden = true
                            cell.teacherImage.isHidden = true
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
        }
    }
    
    func isT1(lesson: String) -> Bool {
        if lesson.components(separatedBy: "<br>").count-1 == 2 && !lesson.contains("підгр.") {
            print("t1")
            return true
        } else {
            return false
        }
    }
    
    func isT2(lesson: String) -> Bool {
        if lesson.components(separatedBy: "<br>").count-1 == 3 && lesson.components(separatedBy: "підгр.").count-1 == 1 {
            print("t2")
            return true
        } else {
            return false
        }
    }
    
    func isT3(lesson: String) -> Bool {
        if (lesson.components(separatedBy: "<br>").count-1) == 7 && (lesson.components(separatedBy: "підгр.").count-1) == 2 {
            print("t3")
            return true
        } else {
            return false
        }
    }
    
    func isTZ(lesson: String) -> Bool {
        if (lesson.components(separatedBy: "Увага! Заміна!").count-1) == 1 {
            print("tz")
            return true
        } else {
            return false
        }
    }
}
