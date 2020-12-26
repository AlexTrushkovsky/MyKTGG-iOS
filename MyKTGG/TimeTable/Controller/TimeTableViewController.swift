//
//  TimeTableViewController.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 01.05.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit

class TimeTableViewController: UIViewController, DateScrollPickerDelegate, DateScrollPickerDataSource {
    
    let settings = SettingsViewController()
    let network = NewTimetableController()
    var pickedDate = Date()
    var cellInitColor = UIColor.white
    var CellIsHighlighted = false
    var alertStatus = AlertStatus.alert
    var animationDuration = 0.3
    let refControl = UIRefreshControl()
    
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
        self.animateIn(animationDuration: self.animationDuration)
    }
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var weekEndImage: UIImageView!
    @IBOutlet weak var timeTableSeparator: UIView!
    @IBOutlet weak var timeTableView: UITableView!
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var weekLabel: UILabel!
    @IBOutlet weak var monthNYearLabel: UILabel!
    @IBOutlet weak var datePicker: DateScrollPicker!
    @IBOutlet weak var todayButtonOutlet: UIButton!
    @IBAction func todayButtonAction(_ sender: UIButton) {
        scrollToday()
        timeTableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setupDateScroll()
        scrollToday()
        refetchData()
        timeTableView.reloadData()
        timeTableView.allowsSelection = true
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpGestures()
        setUpMainView()
        settings.getUserInfo()
        refetchData()
        setupVisualEffectView()
        NotificationCenter.default.addObserver(self, selector: #selector(showNoConnectAlert), name:NSNotification.Name(rawValue: "showNoConnectionWithServer"), object: nil)
    }
    
    @objc func showNoConnectAlert(){
        self.setAlert(type: .alert)
        self.alertView.setText(title: "Помилка", subTitle: "Bідсутнє з'єднання з сервером", body: "cпробуйте будь ласка пізніше")
        self.animateIn(animationDuration: self.animationDuration)
    }
    
   @objc func refetchData() {
        print("Updating TableView")
        deselectRows()
        network.fetchData(tableView: timeTableView, pickedDate: pickedDate)
        refControl.endRefreshing()
        checkNotes()
        timeTableView.reloadData()
    }
    
    func turnGestures(bool: Bool) {
        guard let gestures = view.gestureRecognizers else { return }
        for gesture in gestures {
            gesture.isEnabled = bool
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
            cell.lessonName.isHidden = true
            cell.lessonRoom.isHidden = true
            cell.roomImage.isHidden = true
            cell.teacher.isHidden = true
            cell.teacherImage.isHidden = true
            UIView.animate(withDuration: 0.2, animations: {
                cell.makeNote.isHidden = false
                cell.turnAlarm.isHidden = false
            }, completion: nil)
        default:
            cell.makeNote.isHidden = true
            cell.turnAlarm.isHidden = true
            cell.lessonName.isHidden = false
            cell.lessonRoom.isHidden = false
            cell.roomImage.isHidden = false
            UIView.animate(withDuration: 0.2, animations: {
                cell.teacher.isHidden = false
                cell.teacherImage.isHidden = false
            }, completion: nil)
        }
    }
    
    func checkAction(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, status: Bool) {
        guard let selectedCell = tableView.cellForRow(at: indexPath) as? TimeTableCell else { return }
        switch status {
        case true:
            self.makeButtonsVisible(bool: status, cell: selectedCell)
            self.cellInitColor = selectedCell.lessonView.backgroundColor!
            UIView.animate(withDuration: 0.2, animations: {
                if self.cellInitColor == UIColor(red: 0.30, green: 0.77, blue: 0.57, alpha: 1.00) {
                    selectedCell.lessonView.backgroundColor = UIColor(red: 0.09, green: 0.40, blue: 0.31, alpha: 1.00)
                } else if self.cellInitColor == UIColor(red: 1.00, green: 0.76, blue: 0.47, alpha: 1.00) {
                    selectedCell.lessonView.backgroundColor = UIColor(red: 0.98, green: 0.46, blue: 0.28, alpha: 1.00)
                }
            }, completion: nil)
        default:
            self.makeButtonsVisible(bool: status, cell: selectedCell)
            UIView.animate(withDuration: 0.2, animations: {
                selectedCell.lessonView.backgroundColor = self.cellInitColor
            }, completion: nil)
        }
    }
    
    func animateIn(animationDuration: TimeInterval) {
        turnGestures(bool: false)
        alertView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        alertView.alpha = 0
        
        UIView.animate(withDuration: animationDuration) {
            self.visualEffectView.alpha = 1
            self.alertView.alpha = 1
            self.alertView.transform = CGAffineTransform.identity
            
        }
    }
    
    func animateOut(animationDuration: TimeInterval) {
        turnGestures(bool: true)
        UIView.animate(withDuration: animationDuration, animations: {
            self.visualEffectView.alpha = 0
            self.alertView.alpha = 0
            self.alertView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
            self.tabBarController?.setTabBarVisible(visible: true, animated: false)
        }) { (_) in
            self.alertView.removeFromSuperview()
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
        } else {
            todayButtonOutlet.backgroundColor = UIColor(red: 0.96, green: 0.91, blue: 0.91, alpha: 1.00)
            todayButtonOutlet.setTitleColor(UIColor(red: 0.77, green: 0.30, blue: 0.30, alpha: 1.00), for: .normal)
        }
        if let index = timeTableView.indexPathForSelectedRow {
            print("indexPath: ", index)
            timeTableView.deselectRow(at: index, animated: true)
            CellIsHighlighted = false
            self.makeButtonsVisible(bool: false, cell: timeTableView.cellForRow(at: index) as! TimeTableCell)
        }
        refetchData()
        checkNotes()
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
        format.separatorEnabled = false
        format.fadeEnabled = false
        format.animationScaleFactor = 1.1
        format.dayPadding = 5
        format.topMarginData = 10
        format.dotWidth = 10
        datePicker.format = format
        datePicker.delegate = self
        datePicker.dataSource = self
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
    
//MARK: Alarm methods
    func scheduleAlarm() {
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
            self.animateIn(animationDuration: self.animationDuration)
            return }
        
        let body = "\(cell.lessonName!.text!) на \(cell.startTime!.text!)"
        
        let dateDiff = Calendar.current.dateComponents([.day, .hour, .minute], from: Date(), to: convertedDateWithReserve)
        var alertText = dateDiff.day == 0 ? "" : "\(dateDiff.day!) днів"
        alertText += dateDiff.hour == 0 ? "" : " \(dateDiff.hour!) годин"
        alertText += dateDiff.minute == 0 ? "" : " \(dateDiff.minute!) хвилин"
        self.setAlert(type: .alarmTurned)
        alertView.setText(title: "Будильник", subTitle: "cпрацює через \(alertText)", body: "*цей час завжди можна змінити в налаштуваннях.")
        self.animateIn(animationDuration: self.animationDuration)
        self.appDelegate?.scheduleNotification(notificationType: "Будильник", body: body, date: convertedDateWithReserve)
    }
    
    func okAction(type: AlertStatus) {
        switch type {
        case .note:
            self.addNote(text: alertView.textField.text ?? "")
            self.animateOut(animationDuration: animationDuration)
        case .lateAlarm, .alert:
            self.animateOut(animationDuration: animationDuration)
        case .alarmTurned:
            self.animateOut(animationDuration: animationDuration)
        case .alarmRequest:
            self.alertView.alpha = 0
            self.scheduleAlarm()
        }
    }
    
//MARK: Note methods
    func showNoteAlert(){
        self.setAlert(type: .note)
        alertView.textField.becomeFirstResponder()
        alertView.frame.origin.y -= 129
        alertView.layoutIfNeeded()
        alertView.setText(title: "Замітки", subTitle: "нова замітка", body: "")
        self.animateIn(animationDuration: self.animationDuration)
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
                let noteDict = ["date": pickedDate,"cellIndex":cellIndex!,"text":text] as [String : Any]
                var arrayOfNotes = NSKeyedUnarchiver.unarchiveObject(with: dataOfArrayOfNotes) as! [[String : Any]]
                arrayOfNotes.append(noteDict)
                let NoteData = NSKeyedArchiver.archivedData(withRootObject: arrayOfNotes)
                UserDefaults.standard.set(NoteData, forKey: "arrayOfNotes")
            } else {
                print("notes not found, creating new defaults")
                let noteDict = [["date": pickedDate,"cellIndex":cellIndex!,"text":text]] as [[String : Any]]
                let NoteData = NSKeyedArchiver.archivedData(withRootObject: noteDict)
                UserDefaults.standard.set(NoteData, forKey: "arrayOfNotes")
            }
            
            self.CellIsHighlighted = false
            checkAction(timeTableView, cellForRowAt: cellIndex!, status: false)
        }
    }
    func checkNotes() {
        print("checking notes")
        if let arrayOfDataOfNotes = UserDefaults.standard.object(forKey: "arrayOfNotes") as? Data{
            let arrayOfNotes = NSKeyedUnarchiver.unarchiveObject(with: arrayOfDataOfNotes) as! [[String : Any]]
            print(arrayOfNotes)
            print("pickedDate", pickedDate)
            let pickedDate = self.pickedDate.ignoringTime!
            for date in arrayOfNotes {
                if pickedDate == date["date"] as! Date{
                    print("founded note at:",pickedDate)
                    let index = date["cellIndex"]
                    guard let cell = timeTableView.cellForRow(at: index as! IndexPath) as? TimeTableCell else {return}
                    cell.noteImage.isHidden = false
                    cell.noteText.isHidden = false
                    cell.noteText.text = date["text"] as? String
                } else {
                    let index = date["cellIndex"]
                    if let cell = timeTableView.cellForRow(at: index as! IndexPath) as? TimeTableCell {
                        cell.noteImage.isHidden = true
                        cell.noteText.isHidden = true
                    }
                }
            }
        }
    }
    
}
//MARK: TableView methods
extension TimeTableViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        network.getInfo(date: pickedDate)
        if network.lessonCount == 0 {
            timeTableSeparator.isHidden = true
            weekEndImage.isHidden = false
        } else {
            timeTableSeparator.isHidden = false
            weekEndImage.isHidden = true
        }
        print("table created, lesson count =", network.lessonCount)
        return network.lessonCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimeTableCell") as! TimeTableCell
        cell.lessonView.layer.cornerRadius = 15
        cell.makeNote.layer.cornerRadius = 15
        cell.turnAlarm.layer.cornerRadius = 15
        network.configureCell(cell: cell, for: indexPath, date: pickedDate)
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if CellIsHighlighted == false {
            checkAction(tableView, cellForRowAt: indexPath, status: true)
            CellIsHighlighted = true
            print("row selected")
        } else {
            checkAction(tableView, cellForRowAt: indexPath, status: false)
            CellIsHighlighted = false
            print("row deselected")
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
