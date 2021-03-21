import UIKit

class TimetableNetworkController {
    
    var timeTableRoot = TimetableRoot()
    var newVar = TimetableRoot()
    var lessonCount = 0
    var item = [Item]()
    
    public func fetchData(pickedDate: Date, group: String, isStudent: Bool){
        var mode = ""
        if isStudent {
            mode = "group"
        } else {
            mode = "teacher"
        }
        let semaphore = DispatchSemaphore (value: 0)
        let stringPickedDate = pickedDate.toString(dateFormat: "dd.MM.yyyy")
        let parameters = "{\n    \"to\":\"eRVs75zrFUw-kl6gzqszEK:APA91bH4WbX_KzcMdRBXvCk9W8iAizSO60fxfGHW0It_t2HDpd1J4pJth3_GQ-apHVNhUW0mwDsfNzti12Da6vj1kWWEeKYgILLmHRh0caxu-6B4m7XXN16-J8v7iQXkrv2WN9DKL3x2\",\n    \"notification\": {\n        \"body\":\"Test\",\n        \"title\":\"Test\"\n    }\n}"
        let postData = parameters.data(using: .windowsCP1251)
        
        guard let data = group.data(using: .windowsCP1251) else { return }
        let encodedGroup = data.map { String(format: "%%%02hhX", $0) }.joined()
        guard let url = URL(string: "http://app.ktgg.kiev.ua/cgi-bin/timetable_export.cgi?req_type=rozklad&req_mode=\(mode)&req_format=json&begin_date=\(stringPickedDate)&end_date=\(stringPickedDate)&bs=ok&OBJ_name=\(encodedGroup)") else { return }
        var request = URLRequest(url: url)
        
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
            guard let dataString = String(data: data, encoding: .windowsCP1251) else { return }
            let formattedJson = self.formatJson(str: dataString)
            guard let formattedJsonData = formattedJson.data(using: .utf8) else { return }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                let timeTableRoot = try decoder.decode(TimetableRoot.self, from: formattedJsonData)
                self.newVar = timeTableRoot
                guard let item = self.newVar.item else { return }
                self.item = item
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
        result = result.replacingOccurrences(of: "(Сем)", with: "")
        result = result.replacingOccurrences(of: "(Л)", with: "")
        result = result.replacingOccurrences(of: "(ПрЛ)", with: "")
        return result
    }
    
    func getInfo(date: Date, subGroup: Int, isStudent: Bool) {
        print("get info")
        //MARK: Day pick
        lessonCount = 0
        item.removeAll { value in return value.lessonDescription == ""}
        if isStudent {
            if subGroup == 0 {
                item.removeAll { value in
                    if let containsAnotherGroup = value.lessonDescription?.contains("(підгр. 2)") {
                        if containsAnotherGroup {
                            if let containsCurrentGroup = value.lessonDescription?.contains("(підгр. 1)") {
                                if !containsCurrentGroup {
                                    return true
                                }
                            }
                        }
                    }
                    return false
                }
            } else if subGroup == 1{
                item.removeAll { value in
                    if let containsAnotherGroup = value.lessonDescription?.contains("(підгр. 1)") {
                        if containsAnotherGroup {
                            if let containsCurrentGroup = value.lessonDescription?.contains("(підгр. 2)") {
                                if !containsCurrentGroup {
                                    return true
                                }
                            }
                        }
                    }
                    return false
                }
            }
        }
        for lesson in item {
            guard let stringDate = lesson.date else { return }
            guard let newDate = stringDate.toDate(withFormat: "dd.MM.yyyy") else { return }
            guard date.ignoringTime == newDate.ignoringTime else { return }
            guard let lessonNum = Int(lesson.lessonNumber ?? "0") else { return }
            if lessonNum > 0  && lesson.lessonDescription != nil && lesson.lessonDescription != ""{
                if isStudent {
                    if let containsSubGroup = lesson.lessonDescription?.contains("(підгр.") {
                        if containsSubGroup {
                            if let isCurrentSubGroup = lesson.lessonDescription?.contains("(підгр. \(subGroup+1))") {
                                if isCurrentSubGroup {
                                    lessonCount += 1
                                }
                            }
                        } else {
                            lessonCount += 1
                        }
                    }
                } else {
                    lessonCount += 1
                }
            }
        }
    }
    
    func deinitModel() {
        print("deinit model")
        self.timeTableRoot = TimetableRoot()
        self.newVar = TimetableRoot()
        self.lessonCount = 0
        self.item = [Item]()
    }
    
    func formatCellToChange(cell: TimeTableCell) {
        cell.lessonView.backgroundColor = UIColor(red: 0.77, green: 0.30, blue: 0.30, alpha: 1.00)
    }
    func formatCellToLesson(cell: TimeTableCell) {
        cell.lessonView.backgroundColor = UIColor(red: 0.30, green: 0.77, blue: 0.57, alpha: 1.00)
    }
    
    func configureCell(cell: TimeTableCell, for indexPath: IndexPath, date: Date, isStudent: Bool, subGroup: Int) {
        print("TT: config cell")
        guard indexPath.row >= item.startIndex && indexPath.row < item.endIndex else { return }
        cell.roomImage.isHidden = false
        cell.lessonRoom.isHidden = false
        cell.teacher.isHidden = false
        cell.teacherImage.isHidden = false
        lessonCount = 0
        configureTime(cell: cell, index: indexPath)
        guard let stringDate = item[indexPath.row].date else { return }
        let newDate = stringDate.toDate(withFormat: "dd.MM.yyyy")
        guard date.ignoringTime == newDate?.ignoringTime else { return }
        
        configureLesson(cell: cell, index: indexPath, isStudent: isStudent, subGroup: subGroup)
    }
    
    func configureTime(cell: TimeTableCell, index: IndexPath) {
        if let lessontime = item[index.row].lessonTime {
            if let index = lessontime.firstIndex(of: "-") {
                let firstPart = lessontime.prefix(upTo: index)
                let secondPart = lessontime.suffix(from: lessontime.index(index, offsetBy: 1))
                cell.startTime.text = String(firstPart)
                cell.endTime.text = String(secondPart)
            }
        }
    }
 
    func configureLesson(cell: TimeTableCell, index: IndexPath, isStudent: Bool, subGroup: Int) {
        formatCellToLesson(cell: cell)
        guard let lesson = item[index.row].lessonDescription else { return }
        if isStudent {
            configAsStudent(cell: cell, lesson: lesson, isStudent: isStudent, subGroup: subGroup)
        } else {
            configAsTeacher(cell: cell, lesson: lesson, isStudent: isStudent)
        }
    }
    
    func configAsStudent(cell: TimeTableCell, lesson: String, isStudent: Bool, subGroup: Int) {
        isStudentBig(lesson: lesson, cell: cell, subgroup: subGroup)
    }
    
    func configAsTeacher(cell: TimeTableCell, lesson: String, isStudent: Bool) {
        isTeacherRoomChange(lesson: lesson, cell: cell)
    }
    
    
//MARK: Student declaration
    
    func isStudentBig(lesson: String, cell: TimeTableCell, subgroup: Int) {
        //getting subgroup if bigchange and giving new lessonDesk
        if lesson.contains("(підгр. 1)") && lesson.contains("(підгр. 2)") && lesson.contains("<br> <div class='link'> </div> <br>") {
            let firstPart = lesson.components(separatedBy: "<br> <div class='link'> </div> <br>")[0]
            let lastPart = lesson.components(separatedBy: "<br> <div class='link'> </div> <br>")[1]
            var lessonForSubgroup: String? = nil
            if firstPart.contains("(підгр. \(subgroup+1)") {
                lessonForSubgroup = "\(firstPart)<br>"
            } else {
                lessonForSubgroup = lastPart
            }
            if lessonForSubgroup != nil {
                let lesson = lessonForSubgroup!.replacingOccurrences(of: "<div class='link'> </div>", with: "").replacingOccurrences(of: "<div class='link'></div>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                print("\(cell.startTime.text ?? "") - got subgroup lesson")
                isStudentRoomChange(lesson: lesson, cell: cell)
                return
            }
        }
        let formattedLesson = lesson.replacingOccurrences(of: "<div class='link'> </div>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        isStudentRoomChange(lesson: formattedLesson, cell: cell)
    }
    
    var room: String? = nil
    func isStudentRoomChange(lesson: String, cell: TimeTableCell) {
        //if yes, remember new room
        if lesson.contains("Увага! Заняття перенесено у іншу аудиторію") {
            let lessonStr = lesson.replacingOccurrences(of: "Увага! Заняття перенесено у іншу аудиторію", with: "")
            let room = lessonStr.components(separatedBy: "!")[0].trimmingCharacters(in: .whitespacesAndNewlines)
            self.room = room
            formatCellToChange(cell: cell)
            print("\(cell.startTime.text ?? "") - room change found")
            isStudentChangeWithLessonNameWithCab(lesson: lessonStr.replacingOccurrences(of: "\(room)!", with: "").trimmingCharacters(in: .whitespacesAndNewlines), cell: cell)
            return
        }
        isStudentChangeWithLessonNameWithCab(lesson: lesson, cell: cell)
    }
    
    func isStudentChangeWithLessonNameWithCab(lesson: String, cell: TimeTableCell) {
        //if yes result, write and return
        if lesson.contains("Увага! Заміна!") && lesson.contains("замість:") && lesson.components(separatedBy: "<br>").count == 3{
            var lessonStr = lesson.replacingOccurrences(of: "Увага! Заміна!", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let teacher = "\(lessonStr.components(separatedBy: ".")[0]).\(lessonStr.components(separatedBy: ".")[1])."
            lessonStr = lessonStr.replacingOccurrences(of: teacher, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let lessonName = lessonStr.components(separatedBy: "замість:")[0].trimmingCharacters(in: .whitespacesAndNewlines)
            if lessonName != "" {
                lessonStr = lessonStr.replacingOccurrences(of: lessonName, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                lessonStr = lessonStr.replacingOccurrences(of: "замість:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                var room = lessonStr.components(separatedBy: "<br>")[0]
                formatCellToChange(cell: cell)
                cell.lessonName.text = lessonName
                cell.teacher.text = teacher
                if self.room != nil {
                    room = self.room!
                    self.room = nil
                }
                cell.lessonRoom.text = room
                print("\(cell.startTime.text ?? "") - change with lesson name with cab found")
                return
            }
        }
        isStudentChangeWithLessonNameWoCab(lesson: lesson, cell: cell)
    }
    
    func isStudentChangeWithLessonNameWoCab(lesson: String, cell: TimeTableCell) {
        //if yes result, write and return
        if lesson.contains("Увага! Заміна!") && lesson.contains("замість:") && lesson.components(separatedBy: "<br>").count == 2{
            var lessonStr = lesson.replacingOccurrences(of: "Увага! Заміна!", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let teacher = "\(lessonStr.components(separatedBy: ".")[0]).\(lessonStr.components(separatedBy: ".")[1])."
            lessonStr = lessonStr.replacingOccurrences(of: teacher, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let lessonName = lessonStr.components(separatedBy: "замість:")[0].trimmingCharacters(in: .whitespacesAndNewlines)
            if lessonName != "" {
                formatCellToChange(cell: cell)
                cell.lessonName.text = lessonName
                cell.teacher.text = teacher
                if self.room != nil {
                    cell.lessonRoom.text = self.room!
                    self.room = nil
                } else {
                    cell.lessonRoom.isHidden = true
                    cell.roomImage.isHidden = true
                }
                print("\(cell.startTime.text ?? "") - change with lesson name and without cab found")
                return
            }
        }
        isStudentChangeWithoutLessonNameWithCab(lesson: lesson, cell: cell)
    }
    
    func isStudentChangeWithoutLessonNameWithCab(lesson: String, cell: TimeTableCell) {
        //if yes result, write and return
        if lesson.contains("Увага! Заміна!") && lesson.contains("замість:") && lesson.components(separatedBy: "<br>").count == 3 {
            var lessonStr = lesson.replacingOccurrences(of: "Увага! Заміна!", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let teacher = "\(lessonStr.components(separatedBy: ".")[0]).\(lessonStr.components(separatedBy: ".")[1])."
            lessonStr = lessonStr.replacingOccurrences(of: teacher, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let lessonName = lessonStr.components(separatedBy: "замість:")[0].trimmingCharacters(in: .whitespacesAndNewlines)
            if lessonName == "" {
                formatCellToChange(cell: cell)
                lessonStr = lessonStr.replacingOccurrences(of: "замість:", with: "")
                let oldTeacher = "\(lessonStr.components(separatedBy: ".")[0]).\(lessonStr.components(separatedBy: ".")[1])."
                lessonStr = lessonStr.replacingOccurrences(of: oldTeacher, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                let room = lessonStr.components(separatedBy: "<br>")[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let lesson = lessonStr.components(separatedBy: "<br>")[1].replacingOccurrences(of: "<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                cell.lessonName.text = lesson
                cell.teacher.text = teacher
                cell.lessonRoom.text = room
                if self.room != nil {
                    cell.lessonRoom.text = room
                    self.room = nil
                }
                print("\(cell.startTime.text ?? "") - change wo lesson name with cab found")
                return
            }
        }
        isStudentChangeWithoutLessonNameWoCab(lesson: lesson, cell: cell)
    }
    
    func isStudentChangeWithoutLessonNameWoCab(lesson: String, cell: TimeTableCell) {
        //if yes result, write and return
        if lesson.contains("Увага! Заміна!") && lesson.contains("замість:") && lesson.components(separatedBy: "<br>").count == 2{
            var lessonStr = lesson.replacingOccurrences(of: "Увага! Заміна!", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let teacher = "\(lessonStr.components(separatedBy: ".")[0]).\(lessonStr.components(separatedBy: ".")[1])."
            lessonStr = lessonStr.replacingOccurrences(of: teacher, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let lessonName = lessonStr.components(separatedBy: "замість:")[0].trimmingCharacters(in: .whitespacesAndNewlines)
            if lessonName == "" {
                formatCellToChange(cell: cell)
                lessonStr = lessonStr.replacingOccurrences(of: "замість:", with: "")
                let oldTeacher = "\(lessonStr.components(separatedBy: ".")[0]).\(lessonStr.components(separatedBy: ".")[1])."
                lessonStr = lessonStr.replacingOccurrences(of: oldTeacher, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                let room = lessonStr.components(separatedBy: "<br>")[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let lesson = lessonStr.components(separatedBy: "<br>")[1].replacingOccurrences(of: "<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                cell.lessonName.text = lesson
                cell.teacher.text = teacher
                cell.lessonRoom.text = room
                if self.room != nil {
                    cell.lessonRoom.text = self.room!
                    self.room = nil
                } else {
                    cell.lessonRoom.isHidden = true
                    cell.roomImage.isHidden = true
                }
                print("\(cell.startTime.text ?? "") - change wo lesson name wo cab found")
                return
            }
        }
        isStudentChangeCanceled(lesson: lesson, cell: cell)
    }
    
    func isStudentChangeCanceled(lesson: String, cell: TimeTableCell) {
        //if yes result, write and return
        if lesson.contains("Увага! Заняття відмінено!") {
            formatCellToChange(cell: cell)
            cell.lessonName.text = "Заняття відмінено"
            cell.lessonRoom.isHidden = true
            cell.teacher.isHidden = true
            cell.roomImage.isHidden = true
            cell.teacherImage.isHidden = true
            print("\(cell.startTime.text ?? "") - change canceled found")
            return
        }
        isStudentSubgroupLessonWithCab(lesson: lesson, cell: cell)
    }
    
    func isStudentSubgroupLessonWithCab(lesson: String, cell: TimeTableCell) {
        //if yes result, write and return
        if lesson.contains("(підгр.") && lesson.components(separatedBy: "<br>").count == 4{
            var room = lesson.components(separatedBy: "<br>")[0]
            var lessonStr = lesson.replacingOccurrences(of: "\(room)<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            var teacher = "\(lessonStr.components(separatedBy: ".")[0]).\(lessonStr.components(separatedBy: ".")[1])."
            lessonStr = lessonStr.replacingOccurrences(of: "\(teacher)", with: "")
            teacher = teacher.replacingOccurrences(of: "(підгр. 1)", with: "").replacingOccurrences(of: "(підгр. 2)", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let lessonName = lessonStr.components(separatedBy: "<br>")[1].trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "<br>", with: "")
            if self.room != nil {
                room = self.room!
                self.room = nil
            }
            cell.lessonName.text = lessonName
            cell.lessonRoom.text = room
            cell.teacher.text = teacher
            print("\(cell.startTime.text ?? "") - subgroup lesson with cab found")
            return
        }
        isStudentSubgroupLessonWoCab(lesson: lesson, cell: cell)
    }
    
    func isStudentSubgroupLessonWoCab(lesson: String, cell: TimeTableCell) {
        //if yes result, write and return
        if lesson.contains("(підгр.") && lesson.components(separatedBy: "<br>").count == 3{
            var teacher = "\(lesson.components(separatedBy: ".")[0]).\(lesson.components(separatedBy: ".")[1])."
            let lessonStr = lesson.replacingOccurrences(of: "\(teacher)", with: "")
            teacher = teacher.replacingOccurrences(of: "(підгр. 1)", with: "").replacingOccurrences(of: "(підгр. 2)", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let lessonName = lessonStr.components(separatedBy: "<br>")[1].trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "<br>", with: "")
            if self.room != nil {
                cell.lessonRoom.text = self.room!
                self.room = nil
            } else {
                cell.lessonRoom.isHidden = true
                cell.roomImage.isHidden = true
            }
            cell.lessonName.text = lessonName
            cell.teacher.text = teacher
            print("\(cell.startTime.text ?? "") - subgroup lesson without cab found")
            return
        }
        isStudentDefaultLessonWithCab(lesson: lesson, cell: cell)
    }
    
    func isStudentDefaultLessonWithCab(lesson: String, cell: TimeTableCell) {
        //if yes result, write and return
        if lesson.components(separatedBy: "<br>").count == 3 {
            var room = lesson.components(separatedBy: "<br>")[0]
            var lessonStr = lesson.replacingOccurrences(of: "\(room)<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let teacher = "\(lessonStr.components(separatedBy: ".")[0]).\(lessonStr.components(separatedBy: ".")[1])."
            lessonStr = lessonStr.replacingOccurrences(of: "\(teacher)", with: "")
            let lessonName = lessonStr.replacingOccurrences(of: "<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            if self.room != nil {
                room = self.room!
                self.room = nil
            }
            cell.lessonName.text = lessonName
            cell.lessonRoom.text = room
            cell.teacher.text = teacher
            print("\(cell.startTime.text ?? "") - default lesson with cab found")
            return
        }
        isStudentDefaultLessonWoCab(lesson: lesson, cell: cell)
    }
    
    func isStudentDefaultLessonWoCab(lesson: String, cell: TimeTableCell) {
        //if yes result, write and return
        if lesson.components(separatedBy: "<br>").count == 2 {
            let teacher = "\(lesson.components(separatedBy: ".")[0]).\(lesson.components(separatedBy: ".")[1])."
            let lessonStr = lesson.replacingOccurrences(of: "\(teacher)", with: "")
            let lessonName = lessonStr.replacingOccurrences(of: "<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            var room: String? = nil
            if self.room != nil {
                room = self.room!
                self.room = nil
            }
            cell.lessonName.text = lessonName
            if room != nil {
                cell.lessonRoom.text = room
            } else {
                cell.roomImage.isHidden = true
                cell.lessonRoom.isHidden = true
            }
            cell.teacher.text = teacher
            print("\(cell.startTime.text ?? "") - default lesson wo cab found")
            return
        }
        putEverythingInline(lesson: lesson, cell: cell)
    }
    
    func putEverythingInline(lesson: String, cell: TimeTableCell) {
        //put inline deleting occurances of tags
        print("\(cell.startTime.text ?? "") - occurances not found")
        let lessonName = lesson.replacingOccurrences(of: "<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        cell.lessonName.text = lessonName
        cell.lessonRoom.isHidden = true
        cell.teacher.isHidden = true
        cell.roomImage.isHidden = true
        cell.teacherImage.isHidden = true
    }
    
//MARK: Teacher declaration
    
    func isTeacherRoomChange(lesson: String, cell: TimeTableCell) {
        //if yes, remember new room
        if lesson.contains("Увага! Заняття перенесено у іншу аудиторію") {
            let lessonStr = lesson.replacingOccurrences(of: "Увага! Заняття перенесено у іншу аудиторію", with: "")
            let room = lessonStr.components(separatedBy: "!")[0].trimmingCharacters(in: .whitespacesAndNewlines)
            self.room = room
            formatCellToChange(cell: cell)
            print("\(cell.startTime.text ?? "") - room change found")
            isTeacherChanged(lesson: lessonStr.replacingOccurrences(of: "\(room)!", with: "").trimmingCharacters(in: .whitespacesAndNewlines), cell: cell)
            return
        }
        isTeacherChanged(lesson: lesson, cell: cell)
    }
    
    func isTeacherChanged(lesson: String, cell: TimeTableCell) {
        //if yes result, write and return
        if lesson.contains("Увага! Заміна! Заняття проведе інший викладач:") && lesson.components(separatedBy: "<br>").count == 3 {
            var lessonStr = lesson.replacingOccurrences(of: "Увага! Заміна! Заняття проведе інший викладач:", with: "")
            let teacher = "\(lessonStr.components(separatedBy: ".")[0]).\(lessonStr.components(separatedBy: ".")[1])."
            lessonStr = lessonStr.replacingOccurrences(of: teacher, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let group = lessonStr.components(separatedBy: "<br>")[0]
            lessonStr = lessonStr.replacingOccurrences(of: "\(group)<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let lessonName = lessonStr.components(separatedBy: "<br>")[0]
            var room: String? = nil
            if self.room != nil {
                room = self.room!
                self.room = nil
            }
            cell.lessonName.text = lessonName
            cell.teacher.text = group
            if room != nil {
                cell.lessonRoom.text = room
            } else {
                cell.roomImage.isHidden = true
                cell.lessonRoom.isHidden = true
            }
            return
        }
        isTeacherChanges(lesson: lesson, cell: cell)
    }
    
    func isTeacherChanges(lesson: String, cell: TimeTableCell) {
        //if yes result, write and return
        if lesson.contains("Увага! Цей викладач на заміні! Замість викладача") && lesson.components(separatedBy: "<br>").count == 3 {
            let oldTeacher = "\(lesson.components(separatedBy: ".")[0]).\(lesson.components(separatedBy: ".")[1])."
            var lessonStr = lesson.replacingOccurrences(of: oldTeacher, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let group = lessonStr.components(separatedBy: "<br>")[0].trimmingCharacters(in: .whitespacesAndNewlines)
            lessonStr = lessonStr.replacingOccurrences(of: "\(group)<br>", with: "")
            let lessonName = lessonStr.components(separatedBy: "<br>")[0].trimmingCharacters(in: .whitespacesAndNewlines)
            var room: String? = nil
            if self.room != nil {
                room = self.room!
                self.room = nil
            }
            cell.lessonName.text = lessonName
            cell.teacher.text = group
            if room != nil {
                cell.lessonRoom.text = room
            } else {
                cell.roomImage.isHidden = true
                cell.lessonRoom.isHidden = true
            }
            return
        }
        isTeacherDefaultLessonWithCab(lesson: lesson, cell: cell)
    }
    
    func isTeacherDefaultLessonWithCab(lesson: String, cell: TimeTableCell) {
        //if yes result, write and return
        if lesson.components(separatedBy: "<br>").count == 4 {
            var room = lesson.components(separatedBy: "<br>")[0].trimmingCharacters(in: .whitespacesAndNewlines)
            var lessonStr = lesson.replacingOccurrences(of: "\(room)<br>", with: "")
            let group = lessonStr.components(separatedBy: "<br>")[0].trimmingCharacters(in: .whitespacesAndNewlines)
            lessonStr = lessonStr.replacingOccurrences(of: "\(group) <br>", with: "").replacingOccurrences(of: "\(group)<br>", with: "")
            let lessonName = lessonStr.components(separatedBy: "<br>")[0].trimmingCharacters(in: .whitespacesAndNewlines)
            if self.room != nil {
                room = self.room!
                self.room = nil
            }
            cell.lessonName.text = lessonName
            cell.lessonRoom.text = room
            cell.teacher.text = group
            return
        }
        isTeacherDefaultLessonWoCab(lesson: lesson, cell: cell)
    }
    
    func isTeacherDefaultLessonWoCab(lesson: String, cell: TimeTableCell) {
        //if yes result, write and return
        if lesson.components(separatedBy: "<br>").count == 3 {
            let group = lesson.components(separatedBy: "<br>")[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let lessonStr = lesson.replacingOccurrences(of: "\(group) <br>", with: "")
            let lessonName = lessonStr.components(separatedBy: "<br>")[0].trimmingCharacters(in: .whitespacesAndNewlines)
            var room: String? = nil
            if self.room != nil {
                room = self.room!
                self.room = nil
            }
            cell.lessonName.text = lessonName
            cell.teacher.text = group
            if room != nil {
                cell.lessonRoom.text = room
            } else {
                cell.roomImage.isHidden = true
                cell.lessonRoom.isHidden = true
            }
            return
        }
        putEverythingInline(lesson: lesson, cell: cell)
    }
    
}
