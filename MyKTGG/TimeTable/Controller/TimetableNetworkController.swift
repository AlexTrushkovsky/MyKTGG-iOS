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
        guard let url = URL(string: "http://217.76.201.218/cgi-bin/timetable_export.cgi?req_type=rozklad&req_mode=\(mode)&req_format=json&begin_date=\(stringPickedDate)&end_date=\(stringPickedDate)&bs=ok&OBJ_name=\(encodedGroup)") else { return }
        var request = URLRequest(url: url, timeoutInterval: Double.infinity)
        
        let ip = getIPAddress()
        if  ip.contains("192.168.5") {
            request = URLRequest(url: url, timeoutInterval: Double.infinity)
        }
        
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
        cell.lessonView.backgroundColor = UIColor(red: 1.00, green: 0.76, blue: 0.47, alpha: 1.00)
    }
    func formatCellToLesson(cell: TimeTableCell) {
        cell.lessonView.backgroundColor = UIColor(red: 0.30, green: 0.77, blue: 0.57, alpha: 1.00)
    }
    
    func configureCell(cell: TimeTableCell, for indexPath: IndexPath, date: Date, isStudent: Bool, subGroup: Int) {
        print("TT: config cell")
        cell.roomImage.isHidden = false
        cell.lessonRoom.isHidden = false
        cell.teacher.isHidden = false
        cell.teacherImage.isHidden = false
        lessonCount = 0
        if let stringDate = item[indexPath.row].date {
            let newDate = stringDate.toDate(withFormat: "dd.MM.yyyy")
            if date.ignoringTime == newDate?.ignoringTime {
                if var lesson = item[indexPath.row].lessonDescription {
                    if isStudent {
                        if isTZ(lesson: lesson) {
                            formatCellToChange(cell: cell)
                            if isBigChangeForStudent(lesson: lesson) {
                                let firstSubgroupLesson = lesson.components(separatedBy: "<br> <br>")[0]
                                print(firstSubgroupLesson)
                                let secondSubgroupLesson = lesson.components(separatedBy: "<br> <br>")[1]
                                print(secondSubgroupLesson)
                                if subGroup == 0 {
                                    //работаем по первой сабгруппе
                                } else if subGroup == 1 {
                                    //работает по второй сабгруппе
                                }
                            } else {
                                //если замена маленькая
                            }
                            
                            lesson = lesson.replacingOccurrences(of: "Увага! Заміна!", with: "")
                            var newLesson = lesson.components(separatedBy: "замість:")[0]
                            let oldLesson = lesson.components(separatedBy: "замість:")[1]
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
                            } else if isT1(lesson: newLesson, isStudent: isStudent) {
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
                                let firstPart = lesson.components(separatedBy: "<br> <br>")[0]
                                let secondPart = lesson.components(separatedBy: "<br> <br>")[1]
                                print("firstPart of t3:\(firstPart)")
                                print("secondPart of t3:\(secondPart)")
                                var mainPart = String()
                                if firstPart.contains("(підгр. \(subGroup+1))") {
                                    mainPart = firstPart
                                } else if secondPart.contains("(підгр. \(subGroup+1))") {
                                    mainPart = secondPart
                                }
                                    let room = mainPart.components(separatedBy: "<br>")[0]
                                    mainPart = mainPart.replacingOccurrences(of: "\(room)<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                                    let teacher = "\(mainPart.components(separatedBy: ".")[0]).\(lesson.components(separatedBy: ".")[1]).".trimmingCharacters(in: .whitespacesAndNewlines)
                                    mainPart = mainPart.replacingOccurrences(of: teacher, with: "")
                                    let subgroup = mainPart.components(separatedBy: "<br>")[0].trimmingCharacters(in: .whitespacesAndNewlines)
                                    mainPart = mainPart.components(separatedBy: "<br>")[1]
                                    let lesson = mainPart.replacingOccurrences(of: "<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                                    print("subgroup:\(subgroup)")
                                    print("lesson:\(lesson)")
                                    cell.lessonName.text = lesson
                                    print("teacher:\(teacher)")
                                    cell.teacher.text = teacher
                                    print("room:\(room)")
                                    cell.lessonRoom.text = room
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
                            } else if isT1(lesson: lesson, isStudent: isStudent) {
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
                    } else {
                        //For teacher
                        if isTZ(lesson: lesson) {
                            formatCellToChange(cell: cell)
                            if isTZnewCab(lesson: lesson){
                                print(lesson)
                                lesson = lesson.replacingOccurrences(of: "Увага! Заняття перенесено у іншу аудиторію", with: "")
                                let room = lesson.components(separatedBy: "!")[0]
                                lesson = lesson.replacingOccurrences(of: "\(room)!", with: "")
                                cell.lessonRoom.text = room
                                
                                if isTZcancel(lesson: lesson) {
                                    print(lesson)
                                    cell.lessonName.text = "Заняття відмінено"
                                    cell.roomImage.isHidden = true
                                    cell.lessonRoom.isHidden = true
                                    cell.teacher.isHidden = true
                                    cell.teacherImage.isHidden = true
                                } else if isTZforNewTeacher(lesson: lesson) {
                                    print(lesson)
                                    lesson = lesson.replacingOccurrences(of: "Увага! Цей викладач на заміні! Замість викладача ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                                    let teacher = "\(lesson.components(separatedBy: ".")[0]).\(lesson.components(separatedBy: ".")[1]).".trimmingCharacters(in: .whitespacesAndNewlines)
                                    lesson = lesson.replacingOccurrences(of: teacher, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                                    let group = lesson.components(separatedBy: "<br>")[0]
                                    lesson = lesson.replacingOccurrences(of: "\(group)<br>", with: "").replacingOccurrences(of: "<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                                    cell.lessonName.text = lesson
                                    cell.teacher.text = group
                                } else if isTZforOldTeacher(lesson: lesson) {
                                    print(lesson)
                                    lesson = lesson.replacingOccurrences(of: "Увага! Заміна!", with: "")
                                    let newLesson = lesson.components(separatedBy: "замість:")[0]
                                    let newTeacher = "\(lesson.components(separatedBy: ".")[0]).\(newLesson.components(separatedBy: ".")[1]).".trimmingCharacters(in: .whitespacesAndNewlines)
                                    cell.lessonName.text = "Замість вас на заміні \(newTeacher)"
                                    cell.roomImage.isHidden = true
                                    cell.lessonRoom.isHidden = true
                                    cell.teacher.isHidden = true
                                    cell.teacherImage.isHidden = true
                                } else {
                                    cell.lessonName.text = lesson.replacingOccurrences(of: "<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                                    cell.roomImage.isHidden = true
                                    cell.lessonRoom.isHidden = true
                                    cell.teacher.isHidden = true
                                    cell.teacherImage.isHidden = true
                                }
                            } else {
                                if isTZcancel(lesson: lesson) {
                                    print(lesson)
                                    cell.lessonName.text = "Заняття відмінено"
                                    cell.roomImage.isHidden = true
                                    cell.lessonRoom.isHidden = true
                                    cell.teacher.isHidden = true
                                    cell.teacherImage.isHidden = true
                                } else if isTZforNewTeacher(lesson: lesson) {
                                    print(lesson)
                                    if (lesson.components(separatedBy: "<br>").count-1) == 3 {
                                        let room = lesson.components(separatedBy: "<br>")[0]
                                        lesson = lesson.replacingOccurrences(of: "\(room)<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                                        lesson = lesson.replacingOccurrences(of: "Увага! Цей викладач на заміні! Замість викладача ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                                        let teacher = "\(lesson.components(separatedBy: ".")[0]).\(lesson.components(separatedBy: ".")[1]).".trimmingCharacters(in: .whitespacesAndNewlines)
                                        lesson = lesson.replacingOccurrences(of: teacher, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                                        let group = lesson.components(separatedBy: "<br>")[0]
                                        lesson = lesson.replacingOccurrences(of: "\(group)<br>", with: "").replacingOccurrences(of: "<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                                        cell.lessonName.text = lesson
                                        cell.lessonRoom.text = room
                                        cell.teacher.text = group
                                    } else {
                                        cell.lessonName.text = lesson.replacingOccurrences(of: "<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                                        cell.roomImage.isHidden = true
                                        cell.lessonRoom.isHidden = true
                                        cell.teacher.isHidden = true
                                        cell.teacherImage.isHidden = true
                                    }
                                } else if isTZforOldTeacher(lesson: lesson) {
                                    print(lesson)
                                    lesson = lesson.replacingOccurrences(of: "Увага! Заміна!", with: "")
                                    let newLesson = lesson.components(separatedBy: "замість:")[0]
                                    let newTeacher = "\(lesson.components(separatedBy: ".")[0]).\(newLesson.components(separatedBy: ".")[1]).".trimmingCharacters(in: .whitespacesAndNewlines)
                                    cell.lessonName.text = "Замість вас на заміні \(newTeacher)"
                                    cell.roomImage.isHidden = true
                                    cell.lessonRoom.isHidden = true
                                    cell.teacher.isHidden = true
                                    cell.teacherImage.isHidden = true
                                } else {
                                    cell.lessonName.text = lesson.replacingOccurrences(of: "<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                                    cell.roomImage.isHidden = true
                                    cell.lessonRoom.isHidden = true
                                    cell.teacher.isHidden = true
                                    cell.teacherImage.isHidden = true
                                }
                                
                            }
                        } else {
                            formatCellToLesson(cell: cell)
                            if isT2(lesson: lesson) || isT1(lesson: lesson, isStudent: isStudent) {
                                let room = lesson.components(separatedBy: "<br>")[0]
                                lesson = lesson.replacingOccurrences(of: "\(room)<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                                let group = lesson.components(separatedBy: "<br>")[0]
                                lesson = lesson.replacingOccurrences(of: "\(group)<br>", with: "")
                                lesson = lesson.components(separatedBy: "<br>")[0]
                                let lesson = lesson.replacingOccurrences(of: "<br>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                                print("lesson:\(lesson)")
                                cell.lessonName.text = lesson
                                print("group:\(group)")
                                cell.teacher.text = group
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
                    }
                    
                    if let lessontime = item[indexPath.row].lessonTime {
                        if let index = lessontime.firstIndex(of: "-") {
                            let firstPart = lessontime.prefix(upTo: index)
                            let secondPart = lessontime.suffix(from: lessontime.index(index, offsetBy: 1))
                            cell.startTime.text = String(firstPart)
                            cell.endTime.text = String(secondPart)
                        }
                    }
                }
            }
        }
    }
    
    func getIPAddress() -> String {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                guard let interface = ptr?.pointee else { return "" }
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    
                    // wifi = ["en0"]
                    // wired = ["en2", "en3", "en4"]
                    // cellular = ["pdp_ip0","pdp_ip1","pdp_ip2","pdp_ip3"]
                    
                    let name: String = String(cString: (interface.ifa_name))
                    if  name == "en0" || name == "en2" || name == "en3" || name == "en4" || name == "pdp_ip0" || name == "pdp_ip1" || name == "pdp_ip2" || name == "pdp_ip3" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t((interface.ifa_addr.pointee.sa_len)), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address ?? ""
    }
    
    func isT1(lesson: String, isStudent: Bool) -> Bool {
        if isStudent {
            if lesson.components(separatedBy: "<br>").count-1 == 2 && !lesson.contains("підгр.") {
                print("t1 student")
                return true
            } else {
                return false
            }
        } else {
            if lesson.components(separatedBy: "<br>").count-1 == 3 && !lesson.contains("підгр.") {
                print("t1 teacher")
                return true
            } else {
                return false
            }
        }
    }
    
    func isT2(lesson: String) -> Bool {
        //identical for teacher
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
            if lesson.contains("Увага!") {
                return true
            } else {
            return false
        }
    }
    
    func isTZcancel(lesson: String) -> Bool {
            if lesson.contains("Заняття відмінено!") {
                print("tz cancel")
                return true
            } else {
            return false
        }
    }
    
    func isTZnewCab(lesson: String) -> Bool {
        if (lesson.components(separatedBy: "Заняття перенесено у іншу аудиторію").count-1) == 1 && (lesson.components(separatedBy: "!").count-1) >= 2 {
                print("tz new cab")
                return true
            } else {
            return false
        }
    }
    
    func isTZforNewTeacher(lesson: String) -> Bool {
        if (lesson.components(separatedBy: "Цей викладач на заміні!").count-1) == 1 {
                print("tz for new teacher")
                return true
            } else {
            return false
        }
    }
    
    func isTZforOldTeacher(lesson: String) -> Bool {
            if lesson.contains("Увага! Заміна!") {
                print("tz for old teacher")
                return true
            } else {
            return false
        }
    }
    
    func isTZforStudent(lesson: String) -> Bool {
            if lesson.contains("Увага! Заміна!") {
                print("tz for student")
                return true
            } else {
            return false
        }
    }
    
    func isBigChangeForStudent(lesson: String) -> Bool{
        if lesson.contains("<br> <br>") {
            print("big change ofr student")
            return true
        } else {
            return false
        }
    }
    
}
