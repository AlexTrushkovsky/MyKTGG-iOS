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
        self.setAlert(type: .alarmRequest)
        alertView.setText(title: "Будильник", subTitle: "буде заведено за 1 годину до пари", body: "Цей час завжди можна змінити в налаштуваннях")
        self.animateIn()
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
        scrollToday()
        timeTableView.allowsSelection = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpGestures()
        setUpMainView()
        settings.getUserInfo()
        getCurrentGroup()
        getCurrentSubGroup()
        getCurrentUserType()
        setupVisualEffectView()
        setupDateScroll()
        NotificationCenter.default.addObserver(self, selector: #selector(showNoConnectAlert), name:NSNotification.Name(rawValue: "showNoConnectionWithServer"), object: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "group", options: NSKeyValueObservingOptions.new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "subGroup", options: NSKeyValueObservingOptions.new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "isStudent", options: NSKeyValueObservingOptions.new, context: nil)
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
        //        guard !isRefreshing else { return }
        isRefreshing = true
        DispatchQueue.global().async {
            self.network.fetchData(pickedDate: self.pickedDate, group: self.currentGroup, isStudent: self.isStudent)
            DispatchQueue.main.async {
                self.refControl.endRefreshing()
                self.deselectRows()
                self.isRefreshing = false
                self.timeTableView.reloadSections([0], with: .automatic)
            }
        }
    }
    
    @objc func handleSwipe(sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            switch sender.direction {
            case .right:
                let swipeToDate = pickedDate.addDays(-1)
                datePicker.selectDate(swipeToDate!)
                dateScrollPicker(datePicker, didSelectDate: swipeToDate!)
                print("right")
            case .left:
                let swipeToDate = pickedDate.addDays(1)
                datePicker.selectDate(swipeToDate!)
                dateScrollPicker(datePicker, didSelectDate: swipeToDate!)
                print("left")
            default:
                break
            }
        }
    }
    
    func deselectRows() {
        if let index = timeTableView.indexPathForSelectedRow {
            print("indexPath: ", index)
            timeTableView.deselectRow(at: index, animated: true)
            CellIsHighlighted = false
        }
    }
    
    func makeButtonsVisible(bool: Bool, cell: TimeTableCell) {
        switch bool {
        case true:
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
            self.cellInitColor = selectedCell.lessonView.backgroundColor!
            UIView.animate(withDuration: 0.3, animations: {
                if self.cellInitColor == UIColor(red: 0.30, green: 0.77, blue: 0.57, alpha: 1.00) {
                    selectedCell.lessonView.backgroundColor = UIColor(red: 0.09, green: 0.40, blue: 0.31, alpha: 1.00)
                } else if self.cellInitColor == UIColor(red: 1.00, green: 0.76, blue: 0.47, alpha: 1.00) {
                    selectedCell.lessonView.backgroundColor = UIColor(red: 0.98, green: 0.46, blue: 0.28, alpha: 1.00)
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
            timeTableView.deselectRow(at: index, animated: true)
            CellIsHighlighted = false
            self.makeButtonsVisible(bool: false, cell: timeTableView.cellForRow(at: index) as! TimeTableCell)
        }
        refetchData()
    }
    
    func scrollToday(){
        deselectRows()
        datePicker.selectToday()
        dateScrollPicker(datePicker, didSelectDate: Date())
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
        format.separatorEnabled = true
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
        timeTableView.estimatedRowHeight = 123
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
        turnGestures(bool: false)
        alertView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        alertView.alpha = 0
        
        UIView.animate(withDuration: 0.3) {
            self.visualEffectView.alpha = 1
            self.alertView.alpha = 1
            self.alertView.transform = CGAffineTransform.identity
            
        }
    }
    
    func animateOut() {
        turnGestures(bool: true)
        UIView.animate(withDuration: 0.3, animations: {
            self.visualEffectView.alpha = 0
            self.alertView.alpha = 0
            self.alertView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
            self.tabBarController?.setTabBarVisible(visible: true, animated: false)
        }) { (_) in
            self.alertView.removeFromSuperview()
        }
    }
    
    //MARK: Alarm methods
    func addAlarm() {
        //User reserve got from settings
        let alertReserve = 1
        //getting cell
        let cellIndex = timeTableView.indexPathForSelectedRow
        let cell = timeTableView.cellForRow(at: cellIndex!) as! TimeTableCell
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
        let convertedDate = dateFormatter.date(from: stringDateWithTime)!
        //time with user reserve
        let convertedDateWithReserve = Calendar.current.date(
            byAdding: .hour,
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
        
        let body = "\(cell.lessonName!.text!) на \(cell.startTime!.text!)"
        
        let dateDiff = Calendar.current.dateComponents([.day, .hour, .minute], from: Date(), to: convertedDateWithReserve)
        var alertText = dateDiff.day == 0 ? "" : "\(dateDiff.day!) днів"
        alertText += dateDiff.hour == 0 ? "" : " \(dateDiff.hour!) годин"
        alertText += dateDiff.minute == 0 ? "" : " \(dateDiff.minute!) хвилин"
        self.setAlert(type: .alarmTurned)
        alertView.setText(title: "Будильник", subTitle: "cпрацює через \(alertText)", body: "*цей час завжди можна змінити в налаштуваннях.")
        self.animateIn()
        self.appDelegate?.scheduleNotification(notificationType: "Будильник", body: body, date: convertedDateWithReserve)
    }
    
    func checkAlarms(cell: TimeTableCell, date: Date) {
        print("checking alarms")
        
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests(completionHandler: { requests in
            for request in requests {
                if request.identifier == "Будильник" {
                    guard let trigger = request.trigger as? UNTimeIntervalNotificationTrigger else { return }
                    guard let dateOfAlarmInterval = trigger.nextTriggerDate() else { return }
                    print("alarm timeinterval: \(dateOfAlarmInterval)")
                    let dateOfAlarm = dateOfAlarmInterval
                    DispatchQueue.main.async {
                        print("Picked dateNTime \(date)")
                        print("dateNTime of alarm \(dateOfAlarm)")
                        if dateOfAlarm.ignoringTime == date.ignoringTime {
                            cell.alarmText.text = dateOfAlarm.description
                            cell.alarmImage.isHidden = false
                            cell.alarmImage.isHidden = false
                        } else {
                            cell.alarmImage.isHidden = true
                            cell.alarmImage.isHidden = true
                        }
                    }
                }
            }
        })
    }
    
    
    func okAction(type: AlertStatus) {
        switch type {
        case .note:
            self.addNote(text: alertView.textField.text ?? "")
            self.animateOut()
        case .lateAlarm, .alert:
            self.animateOut()
        case .alarmTurned:
            self.animateOut()
        case .alarmRequest:
            self.alertView.alpha = 0
            self.addAlarm()
        }
    }
    
    //MARK: Note methods
    func showNoteAlert(){
        self.setAlert(type: .note)
        alertView.textField.becomeFirstResponder()
        alertView.frame.origin.y -= 129
        alertView.layoutIfNeeded()
        alertView.setText(title: "Замітки", subTitle: "нова замітка", body: "")
        self.animateIn()
    }
    func addNote(text: String) {
        if text != "" {
            let cellIndex = timeTableView.indexPathForSelectedRow
            let cell = timeTableView.cellForRow(at: cellIndex!) as! TimeTableCell
            cell.noteImage.isHidden = false
            cell.noteText.isHidden = false
            cell.noteText.text = text
            let pickedDate = self.pickedDate.ignoringTime!
            print("added note with: \(text)")
            
            if let dataOfArrayOfNotes = UserDefaults.standard.object(forKey: "arrayOfNotes") as? Data{
                print("notes founded")
                if let startTime = cell.startTime.text {
                    let noteDict = ["date": pickedDate,"cellStartTime":startTime,"text":text] as [String : Any]
                    print("set note on \(pickedDate) at \(startTime)")
                    do {
                        guard var arrayOfNotes = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(dataOfArrayOfNotes as Data) as? [[String : Any]] else { return }
                        arrayOfNotes.append(noteDict)
                        do {
                            let noteData = try NSKeyedArchiver.archivedData(withRootObject: arrayOfNotes, requiringSecureCoding: false)
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
                    let noteDict = [["date": pickedDate,"cellStartTime":startTime,"text":text]] as [[String : Any]]
                    do {
                        let noteData = try NSKeyedArchiver.archivedData(withRootObject: noteDict, requiringSecureCoding: false)
                        UserDefaults.standard.set(noteData, forKey: "arrayOfNotes")
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
            self.CellIsHighlighted = false
            checkAction(timeTableView, cellForRowAt: cellIndex!, status: false)
            //            timeTableView.reloadRows(at: [cellIndex!], with: .automatic)
        }
    }
    
    func checkNotes(cell: TimeTableCell, date: Date) {
        print("checking notes")
        if let arrayOfDataOfNotes = UserDefaults.standard.object(forKey: "arrayOfNotes") as? Data{
            do {
                guard let arrayOfNotes = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(arrayOfDataOfNotes as Data) as? [[String : Any]] else { return }
                let pickedDate = date.ignoringTime!
                for date in arrayOfNotes {
                    if pickedDate == date["date"] as! Date{
                        guard let startTime = date["cellStartTime"] as? String else { return }
                        if cell.startTime.text == startTime {
                            print("founed note at \(startTime)")
                            cell.noteImage.isHidden = false
                            cell.noteText.isHidden = false
                            cell.noteText.text = date["text"] as? String
                        } else {
                            cell.noteImage.isHidden = true
                            cell.noteText.isHidden = true
                        }
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
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
            tableView.allowsSelection = true
            network.configureCell(cell: cell, for: indexPath, date: pickedDate, isStudent: isStudent, subGroup: currentSubGroup)
            self.checkNotes(cell: cell, date: pickedDate)
            self.checkAlarms(cell: cell, date: pickedDate)
            timeTableSeparator.isHidden = false
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
