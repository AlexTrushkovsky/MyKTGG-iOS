//
//  TimeTableViewController.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 01.05.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit

class TimetableViewController: UIViewController, DateScrollPickerDelegate, DateScrollPickerDataSource {
    
    let settings = SettingsViewController()
    let network = TimetableNetworkController()
    var pickedDate = Date()
    var cellInitColor = UIColor.white
    var CellIsHighlighted = false
    var alertStatus = AlertStatus.alert
    let refControl = UIRefreshControl()
    var currentGroup = String()
    var currentSubGroup = Int()
    var lessonCount = 0
    var isRefreshing = false
    var isStudent = true
    var pendingNotifications = [UNNotificationRequest]()
    
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    private lazy var alertView: CustomAlert = {
        let alertView: CustomAlert = CustomAlert.loadFromNib()
        alertView.delegate = self
        return alertView
    }()
    
    let visualEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blurEffect)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    @IBAction func makeNoteAction(_ sender: UIButton) {
        showNoteAlert()
    }
    @IBAction func turnAlarmAction(_ sender: UIButton) {
        guard let cellIndex = timeTableView.indexPathForSelectedRow else { return }
        guard let cell = timeTableView.cellForRow(at: cellIndex) as? TimeTableCell else { return }
        if cell.alarmImage.isHidden {
            self.setAlert(type: .alarmRequest)
            self.animateIn()
        } else {
            showAlarmTurned(cell: cell)
        }
    }
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var timeTableSeparator: UIView!
    @IBOutlet weak var timeTableView: UITableView!
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var weekLabel: UILabel!
    @IBOutlet weak var monthNYearLabel: UILabel!
    @IBOutlet weak var datePicker: DateScrollPicker!
    @IBOutlet weak var todayButtonOutlet: UIButton!
    @IBAction func todayButtonAction(_ sender: UIButton) {
        scrollToday()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        selectDateFromUserDefaults()
        timeTableView.allowsSelection = true
        getPendingNotifications()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDateScroll()
        setUpGestures()
        setUpMainView()
        settings.getUserInfo()
        getCurrentGroup()
        getCurrentSubGroup()
        getCurrentUserType()
        setupVisualEffectView()
        NotificationCenter.default.addObserver(self, selector: #selector(showNoConnectAlert), name:NSNotification.Name(rawValue: "showNoConnectionWithServer"), object: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "group", options: NSKeyValueObservingOptions.new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "subGroup", options: NSKeyValueObservingOptions.new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "isStudent", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    func getPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { requests in
            
            let dq = DispatchQueue.global(qos: .userInteractive)
            dq.async {
                let group  = DispatchGroup()
                group.enter()
                self.pendingNotifications = requests
                print("got noticiation requests")
                group.leave()

                group.notify(queue: DispatchQueue.main) { () in
                    self.reloadRows()
                }
            }
        })
    }
    
    
    func selectDateFromUserDefaults() {
        if let date = UserDefaults.standard.object(forKey: "selectDate") as? Date {
            UserDefaults.standard.setValue(nil, forKey: "selectDate")
            datePicker.scrollToDate(date, animated: false)
            datePicker.selectDate(date, animated: true)
            dateScrollPicker(datePicker, didSelectDate: date)
        } else {
            scrollToday()
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "group" {
            getCurrentGroup()
        } else if keyPath == "isStudent" {
            getCurrentUserType()
        } else if keyPath == "subGroup" {
            getCurrentSubGroup()
        }
    }
    
    func getCurrentGroup() {
        guard let group = UserDefaults.standard.object(forKey: "group") as? String else { return }
        self.currentGroup = group
    }
    
    func getCurrentSubGroup() {
        guard let subGroup = UserDefaults.standard.object(forKey: "subGroup") as? Int else { return }
        self.currentSubGroup = subGroup
    }
    
    func getCurrentUserType() {
        guard let userType = UserDefaults.standard.object(forKey: "isStudent") as? Bool else { return }
        self.isStudent = userType
    }
    
    @objc func showNoConnectAlert(){
        print("show no connection error")
        DispatchQueue.main.sync {
            self.refControl.endRefreshing()
            self.setAlert(type: .alert)
            
            self.alertView.setText(title: "Помилка", subTitle: "Немає зв'язку з мережею", body: "перевірте з'єднання, або cпробуйте будь ласка пізніше")
            self.animateIn()
        }
    }
    
    @objc func refetchData() {
        print("Updating TableView")
        isRefreshing = true
        
        for cell in self.timeTableView.visibleCells {
            if let timetableCell = cell as? TimeTableCell {
                UIView.animate(withDuration: 0.2, delay: 0, options: [.repeat, .autoreverse]) {
                    timetableCell.lessonView.transform = .init(translationX: 0, y: 5)
                } completion: { _ in
                    UIView.animate(withDuration: 0.2) {
                        timetableCell.lessonView.transform = .init(translationX: 0, y: 0)
                    } completion: { _ in
                        self.timeTableView.reloadSections([0], with: .automatic)
                    }
                }
            } else if let timetableCell = cell as? WeekendCell{
                UIView.animate(withDuration: 0.2, delay: 0, options: [.repeat, .autoreverse]) {
                    timetableCell.transform = .init(translationX: 0, y: 5)
                } completion: { _ in
                    UIView.animate(withDuration: 0.2) {
                        timetableCell.transform = .init(translationX: 0, y: 0)
                    } completion: { _ in
                        self.timeTableView.reloadSections([0], with: .automatic)
                    }
                }
            }
        }
        
        DispatchQueue.global().async {
            self.network.fetchData(pickedDate: self.pickedDate, group: self.currentGroup, isStudent: self.isStudent)
            DispatchQueue.main.async {
                self.refControl.endRefreshing()
                self.deselectRows()
                self.isRefreshing = false
                for cell in self.timeTableView.visibleCells {
                    if let timetableCell = cell as? TimeTableCell {
                        timetableCell.lessonView.layer.removeAllAnimations()
                    } else if let timetableCell = cell as? WeekendCell {
                        timetableCell.layer.removeAllAnimations()
                    }
                }
            }
        }
    }
    
    @objc func handleSwipe(sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            switch sender.direction {
            case .right:
                if let swipeToDate = pickedDate.addDays(-1) {
                    datePicker.selectDate(swipeToDate)
                    dateScrollPicker(datePicker, didSelectDate: swipeToDate)
                    print("right")
                }
            case .left:
                if let swipeToDate = pickedDate.addDays(1) {
                    datePicker.selectDate(swipeToDate)
                    dateScrollPicker(datePicker, didSelectDate: swipeToDate)
                    print("left")
                }
            default:
                break
            }
        }
    }
    
    func deselectRows() {
        if let index = timeTableView.indexPathForSelectedRow {
            print("indexPath: ", index)
            checkAction(timeTableView, cellForRowAt: index, status: false)
            timeTableView.deselectRow(at: index, animated: true)
            CellIsHighlighted = false
        }
    }
    
    func deselectRows(index: IndexPath) {
        print("indexPath: ", index)
        checkAction(timeTableView, cellForRowAt: index, status: false)
        timeTableView.deselectRow(at: index, animated: true)
        CellIsHighlighted = false
    }
    
    func reloadRows() {
        if let index = timeTableView.indexPathForSelectedRow {
            CellIsHighlighted = false
            timeTableView.reloadRows(at: [index], with: .automatic)
        }
    }
    
    func reloadRows(index: IndexPath) {
            CellIsHighlighted = false
            timeTableView.reloadRows(at: [index], with: .automatic)
    }
    
    func makeButtonsVisible(bool: Bool, cell: TimeTableCell) {
        switch bool {
        case true:
            if cell.noteText.isHidden == false {
                cell.makeNote.setTitle("Редагувати замітку", for: .normal)
            } else {
                cell.makeNote.setTitle("Створити замітку", for: .normal)
            }
            if cell.alarmText.isHidden == false {
                cell.turnAlarm.setTitle("Редагувати будильник", for: .normal)
            } else {
                cell.turnAlarm.setTitle("Увімкнути будильник", for: .normal)
            }
            UIView.animate(withDuration: 0.3) {
                cell.makeNote.alpha = 1
                cell.turnAlarm.alpha = 1
                cell.lessonName.alpha = 0
                cell.lessonRoom.alpha = 0
                cell.roomImage.alpha = 0
                cell.teacher.alpha = 0
                cell.teacherImage.alpha = 0
                cell.noteImage.alpha = 0
                cell.noteText.alpha = 0
                cell.alarmImage.alpha = 0
                cell.alarmText.alpha = 0
            }
            checkAlarmAvailability(cell: cell)
        default:
            UIView.animate(withDuration: 0.3) {
                cell.makeNote.alpha = 0
                cell.turnAlarm.alpha = 0
                cell.teacher.alpha = 1
                cell.teacherImage.alpha = 1
                cell.lessonName.alpha = 1
                cell.lessonRoom.alpha = 1
                cell.roomImage.alpha = 1
                cell.noteImage.alpha = 1
                cell.noteText.alpha = 1
                cell.alarmImage.alpha = 1
                cell.alarmText.alpha = 1
            }
        }
    }
    
    func checkAction(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, status: Bool) {
        guard let selectedCell = tableView.cellForRow(at: indexPath) as? TimeTableCell else { return }
        switch status {
        case true:
            guard let color = selectedCell.lessonView.backgroundColor else { return }
            self.cellInitColor = color
            UIView.animate(withDuration: 0.3, animations: {
                if self.cellInitColor == UIColor(red: 0.30, green: 0.77, blue: 0.57, alpha: 1.00) {
                    selectedCell.lessonView.backgroundColor = UIColor(red: 0.09, green: 0.40, blue: 0.31, alpha: 1.00)
                    selectedCell.turnAlarm.backgroundColor = UIColor(red: 0.91, green: 0.96, blue: 0.94, alpha: 1.00)
                    selectedCell.turnAlarm.setTitleColor(UIColor(red: 0.30, green: 0.77, blue: 0.57, alpha: 1.00), for: .normal)
                    selectedCell.makeNote.backgroundColor = UIColor(red: 0.91, green: 0.96, blue: 0.94, alpha: 1.00)
                    selectedCell.makeNote.setTitleColor(UIColor(red: 0.30, green: 0.77, blue: 0.57, alpha: 1.00), for: .normal)
                } else if self.cellInitColor == UIColor(red: 0.77, green: 0.30, blue: 0.30, alpha: 1.00) {
                    selectedCell.lessonView.backgroundColor = UIColor(red: 0.40, green: 0.09, blue: 0.09, alpha: 1.00)
                    selectedCell.turnAlarm.backgroundColor = UIColor(red: 0.96, green: 0.91, blue: 0.91, alpha: 1.00)
                    selectedCell.turnAlarm.setTitleColor(UIColor(red: 0.77, green: 0.30, blue: 0.30, alpha: 1.00), for: .normal)
                    selectedCell.makeNote.backgroundColor = UIColor(red: 0.96, green: 0.91, blue: 0.91, alpha: 1.00)
                    selectedCell.makeNote.setTitleColor(UIColor(red: 0.77, green: 0.30, blue: 0.30, alpha: 1.00), for: .normal)
                }
            }, completion: nil)
            self.makeButtonsVisible(bool: status, cell: selectedCell)
        default:
            UIView.animate(withDuration: 0.3, animations: {
                selectedCell.lessonView.backgroundColor = self.cellInitColor
            }, completion: nil)
            self.makeButtonsVisible(bool: status, cell: selectedCell)
        }
    }
    
    //MARK: DatePicker methods
    func dateScrollPicker(_ dateScrollPicker: DateScrollPicker, didSelectDate date: Date) {
        pickedDate = date
        dayLabel.text = date.format(dateFormat: "dd")
        weekLabel.text = date.format(dateFormat: "EEEE").capitalized
        monthNYearLabel.text = date.format(dateFormat: "MMM yyyy").capitalized
        if date.ignoringTime == Date().ignoringTime{
            todayButtonOutlet.backgroundColor = UIColor(red: 0.91, green: 0.96, blue: 0.94, alpha: 1.00)
            todayButtonOutlet.setTitleColor(UIColor(red: 0.30, green: 0.77, blue: 0.57, alpha: 1.00), for: .normal)
            todayButtonOutlet.isEnabled = false
        } else {
            todayButtonOutlet.backgroundColor = UIColor(red: 0.96, green: 0.91, blue: 0.91, alpha: 1.00)
            todayButtonOutlet.setTitleColor(UIColor(red: 0.77, green: 0.30, blue: 0.30, alpha: 1.00), for: .normal)
            todayButtonOutlet.isEnabled = true
        }
        if let index = timeTableView.indexPathForSelectedRow {
            deselectRows(index: index)
            if let cell = timeTableView.cellForRow(at: index) as? TimeTableCell {
                self.makeButtonsVisible(bool: false, cell: cell)
            }
        }
        refetchData()
    }
    
    func scrollToday(){
        deselectRows()
        datePicker.selectToday()
        dateScrollPicker(datePicker, didSelectDate: Date.today())
    }
    
    //MARK: Setup views
    
    private func setupDateScroll() {
        var format = DateScrollPickerFormat()
        format.days = 6
        format.topDateFormat = "EEE"
        format.topFont = UIFont(name: "Poppins-SemiBold", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .semibold)
        format.topTextColor = UIColor(red: 0.74, green: 0.76, blue: 0.80, alpha: 1.00)
        format.topTextSelectedColor = UIColor.white
        format.mediumDateFormat = "dd"
        format.mediumFont = UIFont(name: "Poppins-SemiBold", size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .semibold)
        if #available(iOS 13.0, *) {
            format.mediumTextColor = UIColor.label
        } else {
            format.mediumTextColor = UIColor.black
        }
        format.mediumTextSelectedColor = UIColor.white
        format.bottomDateFormat = ""
        format.dayRadius = 12
        format.dayBackgroundColor = UIColor.clear
        format.dayBackgroundSelectedColor = UIColor(red: 1.00, green: 0.46, blue: 0.28, alpha: 1.00)
        format.animatedSelection = true
        format.separatorEnabled = false
        format.fadeEnabled = true
        format.animationScaleFactor = 1.1
        format.dayPadding = 5
        format.topMarginData = 10
        format.dotWidth = 10
        datePicker.format = format
        datePicker.delegate = self
        datePicker.dataSource = self
    }
    
    func setUpGestures() {
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(sender:)))
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(sender:)))
        leftSwipe.direction = .left
        view.addGestureRecognizer(rightSwipe)
        view.addGestureRecognizer(leftSwipe)
    }
    
    func setUpMainView() {
        background.layer.cornerRadius = 30
        todayButtonOutlet.layer.cornerRadius = 10
//        timeTableView.estimatedRowHeight = 200
        timeTableView.rowHeight = UITableView.automaticDimension
        timeTableView.allowsSelection = false
        refControl.tintColor = UIColor(red: 0.65, green: 0.74, blue: 0.82, alpha: 0.5)
        timeTableView.refreshControl = refControl
        refControl.addTarget(self, action: #selector(refetchData), for: .valueChanged)
    }
    
    //MARK: Custom alert methods
    func turnGestures(bool: Bool) {
        guard let gestures = view.gestureRecognizers else { return }
        for gesture in gestures {
            gesture.isEnabled = bool
        }
    }
    
    func setAlert(type: AlertStatus) {
        self.tabBarController?.setTabBarVisible(visible: false, animated: true)
        alertView = CustomAlert.loadFromNib()
        alertView.delegate = self
        self.alertStatus = type
        view.addSubview(alertView)
        alertView.center = view.center
        alertView.setStyle(type: type)
    }
    
    func setupVisualEffectView() {
        view.addSubview(visualEffectView)
        visualEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        visualEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        visualEffectView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        visualEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        visualEffectView.alpha = 0
    }
    
    func animateIn() {
        print("animated in")
        alertView.alpha = 0
        turnGestures(bool: false)
        alertView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        UIView.animate(withDuration: 0.3) {
            self.visualEffectView.alpha = 1
            self.alertView.alpha = 1
            self.alertView.transform = CGAffineTransform.identity
            
        }
    }
    
    func animateOut() {
        print("animated out")
        turnGestures(bool: true)
        UIView.animate(withDuration: 0.3, animations: {
            print("animation")
            self.visualEffectView.alpha = 0
            self.alertView.alpha = 0
            self.alertView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
            self.tabBarController?.setTabBarVisible(visible: true, animated: false)
        }) { (_) in
            self.alertView.removeFromSuperview()
        }
    }
    
    func okAction(type: AlertStatus) {
        switch type {
        case .note:
            self.addNote()
            self.animateOut()
        case .lateAlarm, .alert:
            self.animateOut()
        case .alarmTurned:
            self.getPendingNotifications()
            self.animateOut()
        case .alarmRequest:
            self.addAlarm()
        }
    }
    
    func cancelAction(type: AlertStatus) {
        switch type {
        case .note:
            self.noteCancel()
            self.animateOut()
        case .lateAlarm, .alert:
            self.animateOut()
        case .alarmTurned:
            self.deleteAlarm()
            self.animateOut()
        case .alarmRequest:
            self.deleteAlarm()
            self.animateOut()
        }
    }
    
    
    //MARK: Alarm methods
    
    func checkAlarmAvailability(cell: TimeTableCell) {
        let cellStartTime = cell.startTime.text
        let date = self.pickedDate
        let stringDateWOTime = date.toString(dateFormat: "dd-MM-yyyy")
        let stringDateWithTime = "\(stringDateWOTime) \(cellStartTime ?? "")"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
        dateFormatter.timeZone = TimeZone(identifier: "Europe/Kiev")
        dateFormatter.locale = Locale(identifier: "uk_UA")
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        guard let convertedDate = dateFormatter.date(from: stringDateWithTime) else { return }
        let convertedDateWithReserve = Calendar.current.date(
            byAdding: .hour,
            value: -1,
            to: convertedDate)!
        print(convertedDateWithReserve)
        print(Date())
        if (convertedDateWithReserve) > Date() {
            cell.turnAlarm.isEnabled = true
            cell.turnAlarm.alpha = 1
        } else {
            cell.turnAlarm.isEnabled = false
            cell.turnAlarm.alpha = 0.5
        }
    }
    
    func addAlarm() {
        //User reserve got from settings
        self.alertView.alpha = 0
        var alertReserve = 60
        if alertView.alarmSegment.selectedSegmentIndex == 1{
            alertReserve = 90
        } else if alertView.alarmSegment.selectedSegmentIndex == 2{
            alertReserve = 120
        }
        
        //getting cell
        guard let cellIndex = timeTableView.indexPathForSelectedRow else { return }
        guard let cell = timeTableView.cellForRow(at: cellIndex) as? TimeTableCell else { return }
        //getting time
        let cellStartTime = cell.startTime.text
        let date = self.pickedDate
        let stringDateWOTime = date.toString(dateFormat: "dd-MM-yyyy")
        let stringDateWithTime = stringDateWOTime+" "+cellStartTime!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
        dateFormatter.timeZone = TimeZone(identifier: "Europe/Kiev")
        dateFormatter.locale = Locale(identifier: "uk_UA")
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        //time without user reserve
        guard let convertedDate = dateFormatter.date(from: stringDateWithTime) else { return }
        //time with user reserve
        let convertedDateWithReserve = Calendar.current.date(
            byAdding: .minute,
            value: -alertReserve,
            to: convertedDate)!
        
        print(stringDateWithTime)
        print(convertedDate)
        print(convertedDateWithReserve)
        
        guard convertedDateWithReserve > Date() else {
            self.setAlert(type: .lateAlarm)
            alertView.setText(title: "Будильник", subTitle: "на жаль в минуле повернутись неможливо", body: "заведіть будильник на інший час")
            self.animateIn()
            return }
        
        guard let lessonName = cell.lessonName.text, let startTime = cell.startTime.text else { return }
        let body = "\(lessonName) на \(startTime)"
        
        let dateDiff = Calendar.current.dateComponents([.day, .hour, .minute], from: Date(), to: convertedDateWithReserve)
        
        guard let dayDiff = dateDiff.day,
              let hourDiff = dateDiff.hour,
              let minuteDiff = dateDiff.minute else { return }
        
        var alertText = dayDiff == 0 ? "" : "\(dayDiff) днів"
        alertText += hourDiff == 0 ? "" : " \(hourDiff) годин"
        alertText += minuteDiff == 0 ? "" : " \(minuteDiff) хвилин"
        self.setAlert(type: .alarmTurned)
        alertView.setText(title: "Будильник", subTitle: "cпрацює через \(alertText)", body: "*ви можете видалити будильник натиснувши кнопку нижче, або з головного меню.")
        self.animateIn()
        addAlarmToPushArray(date: convertedDateWithReserve, lessonName: cell.lessonName.text ?? "")
        self.appDelegate?.scheduleNotification(title: "Будильник", notificationType: "\(convertedDateWithReserve)", body: body, date: convertedDateWithReserve)
    }
    
    func addAlarmToPushArray(date: Date, lessonName: String) {
        let sharedDefault = UserDefaults(suiteName: "group.myktgg")!
        let hoursOfUserDate = String(Calendar.current.component(.hour, from: date)).count == 1 ? "0\(Calendar.current.component(.hour, from: date))" : String(Calendar.current.component(.hour, from: date))
        let minutesOfUserDate = String(Calendar.current.component(.minute, from: date)).count == 1 ? "0\(Calendar.current.component(.minute, from: date))" : String(Calendar.current.component(.minute, from: date))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = lessonName != "" ? "d MMM на \(hoursOfUserDate):\(minutesOfUserDate), \(lessonName)" : "d MMM на \(hoursOfUserDate):\(minutesOfUserDate)"
        let body = formatter.string(from: date)
        let push = ["Будильник", body, "alarm", "\(date)"]
        if var arrayOfPushes = sharedDefault.object(forKey: "pushes") as? [[String]] {
            arrayOfPushes.insert(push, at: 0)
            sharedDefault.set(arrayOfPushes, forKey: "pushes")
        } else {
            sharedDefault.set([push], forKey: "pushes")
        }
    }
    
    func deleteAlarmFromPushArray(date: Date, lessonName: String?) {
        let sharedDefault = UserDefaults(suiteName: "group.myktgg")!
        let hoursOfUserDate = String(Calendar.current.component(.hour, from: date)).count == 1 ? "0\(Calendar.current.component(.hour, from: date))" : String(Calendar.current.component(.hour, from: date))
        let minutesOfUserDate = String(Calendar.current.component(.minute, from: date)).count == 1 ? "0\(Calendar.current.component(.minute, from: date))" : String(Calendar.current.component(.minute, from: date))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = lessonName != nil ? "d MMM на \(hoursOfUserDate):\(minutesOfUserDate), \(lessonName!)" : "d MMM на \(hoursOfUserDate):\(minutesOfUserDate)"
        let body = formatter.string(from: date)
        let push = ["Будильник", body, "alarm", "\(date)"]
        if var arrayOfPushes = sharedDefault.object(forKey: "pushes") as? [[String]]{
            for (index, array) in arrayOfPushes.enumerated() {
                if array == push {
                    arrayOfPushes.remove(at: index)
                    break
                }
            }
            sharedDefault.set(arrayOfPushes, forKey: "pushes")
        }
    }
    
    func showAlarmTurned(cell: TimeTableCell) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests(completionHandler: { requests in
            for request in requests {
                guard let userInfo = request.content.userInfo as? [String:Date] else { return }
                guard let userInfoDate = userInfo["date"] else { return }
                let hoursOfUserDate = Calendar.current.component(.hour, from: userInfoDate)
                let minutesOfUserDate = Calendar.current.component(.minute, from: userInfoDate)
                DispatchQueue.main.async {
                    guard let timeOfCell = cell.startTime.text?.components(separatedBy: ":") else { return }
                    guard let hoursOfCell = Int(timeOfCell[0]) else { return }
                    guard let minutesOfCell = Int(timeOfCell[1]) else { return }
                    guard userInfoDate.ignoringTime == self.pickedDate.ignoringTime else { return }
                    var alarmDate = Date()
                    let userTimeMin = hoursOfUserDate * 60 + minutesOfUserDate
                    let cellTimeMin = hoursOfCell * 60 + minutesOfCell
                    if  (cellTimeMin-60 == userTimeMin) ||
                        (cellTimeMin-90 == userTimeMin) ||
                        (cellTimeMin-120 == userTimeMin) {
                            alarmDate = userInfoDate
                    }
                    
                    let dateDiff = Calendar.current.dateComponents([.day, .hour, .minute], from: Date(), to: alarmDate)
                    guard let dayDiff = dateDiff.day,
                          let hourDiff = dateDiff.hour,
                          let minuteDiff = dateDiff.minute else { return }
                    
                    var alertText = dayDiff == 0 ? "" : "\(dayDiff) днів"
                    alertText += hourDiff == 0 ? "" : " \(hourDiff) годин"
                    alertText += minuteDiff == 0 ? "" : " \(minuteDiff) хвилин"
                    self.alertView.setText(title: "Будильник", subTitle: "cпрацює через \(alertText)", body: "*ви можете видалити будильник натиснувши кнопку нижче, або з головного меню.")
                }
            }
        })
        self.setAlert(type: .alarmTurned)
        self.animateIn()
    }
    
    func deleteAlarm() {
        guard let cellIndex = timeTableView.indexPathForSelectedRow else { return }
        guard let cell = timeTableView.cellForRow(at: cellIndex) as? TimeTableCell else { return }
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests(completionHandler: { requests in
            for request in requests {
                guard let userInfo = request.content.userInfo as? [String:Date] else { return }
                guard let userInfoDate = userInfo["date"] else { return }
                let hoursOfUserDate = Calendar.current.component(.hour, from: userInfoDate)
                let minutesOfUserDate = Calendar.current.component(.minute, from: userInfoDate)
                DispatchQueue.main.sync {
                    guard let timeOfCell = cell.startTime.text?.components(separatedBy: ":") else { return }
                    guard let hoursOfCell = Int(timeOfCell[0]) else { return }
                    guard let minutesOfCell = Int(timeOfCell[1]) else { return }
                    guard userInfoDate.ignoringTime == self.pickedDate.ignoringTime else { return }
                    var identifiers: [String] = []
                    let userTimeMin = hoursOfUserDate * 60 + minutesOfUserDate
                    let cellTimeMin = hoursOfCell * 60 + minutesOfCell
                    if  (cellTimeMin-60 == userTimeMin) ||
                        (cellTimeMin-90 == userTimeMin) ||
                        (cellTimeMin-120 == userTimeMin) {
                            identifiers.append(request.identifier)
                    }
                    self.deleteAlarmFromPushArray(date: userInfoDate, lessonName: cell.lessonName.text)
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
                    self.getPendingNotifications()
                }
            }
        })
    }
    
    func checkAlarms(cell: TimeTableCell, date: Date) {
        print("checking alarms")
        cell.alarmImage.isHidden = true
        cell.alarmText.isHidden = true
        for request in pendingNotifications {
            guard let userInfo = request.content.userInfo as? [String:Date] else { return }
            guard let userInfoDate = userInfo["date"] else { return }
            let hoursOfUserDate = Calendar.current.component(.hour, from: userInfoDate)
            let minutesOfUserDate = Calendar.current.component(.minute, from: userInfoDate)
            guard let timeOfCell = cell.startTime.text?.components(separatedBy: ":") else { return }
            guard let hoursOfCell = Int(timeOfCell[0]) else { return }
            guard let minutesOfCell = Int(timeOfCell[1]) else { return }
            guard userInfoDate.ignoringTime == date.ignoringTime else { return }
            let userTimeMin = hoursOfUserDate * 60 + minutesOfUserDate
            let cellTimeMin = hoursOfCell * 60 + minutesOfCell
            if  (cellTimeMin-60 == userTimeMin) ||
                    (cellTimeMin-90 == userTimeMin) ||
                    (cellTimeMin-120 == userTimeMin) {
                let hoursString = String(Calendar.current.component(.hour, from: userInfoDate)).count == 1 ? "0\(Calendar.current.component(.hour, from: userInfoDate))" : String(Calendar.current.component(.hour, from: userInfoDate))
                let minutesString = String(Calendar.current.component(.minute, from: userInfoDate)).count == 1 ? "0\(Calendar.current.component(.minute, from: userInfoDate))" : String(Calendar.current.component(.minute, from: userInfoDate))
                cell.alarmImage.isHidden = false
                cell.alarmText.isHidden = false
                cell.alarmText.text = "\(hoursString):\(minutesString)"
                print("added alarm on view")
            }
        }
    }
    
    //MARK: Note methods
    func showNoteAlert(){
        guard let cellIndex = timeTableView.indexPathForSelectedRow else { return }
        guard let cell = timeTableView.cellForRow(at: cellIndex) as? TimeTableCell else { return }
        self.setAlert(type: .note)
        alertView.textField.becomeFirstResponder()
        alertView.frame.origin.y -= 129
        alertView.layoutIfNeeded()
        if !cell.noteText.isHidden {
            alertView.textField.text = cell.noteText.text
            alertView.setText(title: "Замітки", subTitle: "редагування замітки", body: "")
            alertView.cancelOutlet.setTitle("Видалити", for: .normal)
        } else {
            alertView.setText(title: "Замітки", subTitle: "нова замітки", body: "")
            alertView.cancelOutlet.setTitle("Відміна", for: .normal)
        }
        self.animateIn()
    }
    
    func noteCancel() {
        print("note cancel...")
        guard let cellIndex = timeTableView.indexPathForSelectedRow else { return }
        guard let cell = timeTableView.cellForRow(at: cellIndex) as? TimeTableCell else { return }
        guard let arrayOfDataOfNotes = UserDefaults.standard.object(forKey: "arrayOfNotes") as? Data else {return}
        do {
            guard let arrayOfNotes = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(arrayOfDataOfNotes as Data) as? [[String : Any]] else { return }
            var newArrayOfNotes = arrayOfNotes
            for (index, item) in arrayOfNotes.enumerated() {
                guard let arrDate = item["date"] as? Date else { return }
                guard let startTime = item["cellStartTime"] as? String else { return }
                guard let text = item["text"] as? String else { return }
                if cell.startTime.text == startTime && cell.noteText.text == text && pickedDate.ignoringTime == arrDate{
                    print("deleted note at \(startTime)")
                    if index >= newArrayOfNotes.startIndex && index < newArrayOfNotes.endIndex {
                        print(newArrayOfNotes[index])
                        newArrayOfNotes.remove(at: index)
                    }
                    
                }
            }
            do {
                let DataOfNotes = try NSKeyedArchiver.archivedData(withRootObject: newArrayOfNotes, requiringSecureCoding: false)
                UserDefaults.standard.set(DataOfNotes, forKey: "arrayOfNotes")
            } catch {
                print(error.localizedDescription)
            }
            timeTableView.reloadRows(at: [cellIndex], with: .automatic)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func addNote() {
        guard let alertText = alertView.textField.text else { return }
        guard alertText != "" else { return }
        guard let cellIndex = timeTableView.indexPathForSelectedRow else { return }
        guard let cell = timeTableView.cellForRow(at: cellIndex) as? TimeTableCell else { return }
        
        cell.noteImage.isHidden = false
        cell.noteText.isHidden = false
        guard let pickedDate = self.pickedDate.ignoringTime else { return }
        
        if let dataOfArrayOfNotes = UserDefaults.standard.object(forKey: "arrayOfNotes") as? Data{
            print("notes found")
            if let cellStartTime = cell.startTime.text {
                let noteDict = ["date": pickedDate,"cellStartTime":cellStartTime,"text":alertText] as [String : Any]
                do {
                    guard let arrayOfNotes = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(dataOfArrayOfNotes) as? [[String : Any]] else { return }
                    var newArrayOfNotes = arrayOfNotes
                    for (index, item) in arrayOfNotes.enumerated() {
                        guard let arrDate = item["date"] as? Date else { return }
                        guard let startTime = item["cellStartTime"] as? String else { return }
                        if cell.startTime.text == startTime && pickedDate == arrDate {
                            newArrayOfNotes.remove(at: index)
                        }
                    }
                    newArrayOfNotes.append(noteDict)
                    do {
                        let noteData = try NSKeyedArchiver.archivedData(withRootObject: newArrayOfNotes, requiringSecureCoding: false)
                        UserDefaults.standard.set(noteData, forKey: "arrayOfNotes")
                    } catch {
                        print(error.localizedDescription)
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        } else {
            print("notes not found, creating new defaults")
            if let startTime = cell.startTime.text {
                let noteDict = [["date": pickedDate,"cellStartTime":startTime,"text":alertText]] as [[String : Any]]
                do {
                    let noteData = try NSKeyedArchiver.archivedData(withRootObject: noteDict, requiringSecureCoding: false)
                    UserDefaults.standard.set(noteData, forKey: "arrayOfNotes")
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        deselectRows(index: cellIndex)
        checkAction(timeTableView, cellForRowAt: cellIndex, status: false)
        timeTableView.reloadRows(at: [cellIndex], with: .automatic)
    }
    
    func checkNotes(cell: TimeTableCell, date: Date) {
        print("checking notes")
        cell.noteText.isHidden = true
        cell.noteImage.isHidden = true
        guard let arrayOfDataOfNotes = UserDefaults.standard.object(forKey: "arrayOfNotes") as? Data else {return}
        do {
            guard let arrayOfNotes = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(arrayOfDataOfNotes as Data) as? [[String : Any]] else { return }
            guard let pickedDate = date.ignoringTime else { return }
            for item in arrayOfNotes {
                guard let arrDate = item["date"] as? Date else { return }
                if pickedDate == arrDate{
                    guard let startTime = item["cellStartTime"] as? String else { return }
                    if cell.startTime.text == startTime {
                        print("founed note at \(startTime)")
                        cell.noteImage.isHidden = false
                        cell.noteText.isHidden = false
                        cell.noteText.text = item["text"] as? String
                    }
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
}
//MARK: TableView methods
extension TimetableViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        network.getInfo(date: pickedDate, subGroup: self.currentSubGroup, isStudent: isStudent)
        self.lessonCount = network.lessonCount
        print("table created, lesson count =", self.lessonCount)
        if self.lessonCount == 0 {
            return 1
        }
        return self.lessonCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.lessonCount == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "WeekendTableCell") as! WeekendCell
            tableView.allowsSelection = false
            timeTableSeparator.isHidden = true
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TimeTableCell") as! TimeTableCell
            network.configureCell(cell: cell, for: indexPath, date: pickedDate, isStudent: isStudent, subGroup: currentSubGroup)
            checkAlarms(cell: cell, date: pickedDate)
            checkNotes(cell: cell, date: pickedDate)
            timeTableView.allowsSelection = true
            timeTableSeparator.isHidden = false
            print("cell returned")
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if CellIsHighlighted == false {
            checkAction(tableView, cellForRowAt: indexPath, status: true)
            CellIsHighlighted = true
            print("selected row with index: \(indexPath.row)")
        } else {
            checkAction(tableView, cellForRowAt: indexPath, status: false)
            CellIsHighlighted = false
            print("deselected row with index: \(indexPath.row)")
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        checkAction(tableView, cellForRowAt: indexPath, status: false)
        CellIsHighlighted = false
        print("row deselected")
    }
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? TimeTableCell {
            self.makeButtonsVisible(bool: false, cell: cell)
        }
    }
}

extension TimetableViewController: CustomAlertDelegate {
    func cancelAction() {
        self.cancelAction(type: self.alertStatus)
    }
    
    func okAction() {
        self.okAction(type: self.alertStatus)
    }
}
