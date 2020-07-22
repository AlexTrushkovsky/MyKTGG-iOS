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
    let network = TimeTableNetworkController()
    var pickedDate = Date()
    var cell = TimeTableCell()
    
    
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
        timeTableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        background.layer.cornerRadius = 30
        todayButtonOutlet.layer.cornerRadius = 10
        timeTableView.estimatedRowHeight = 123
        timeTableView.rowHeight = UITableView.automaticDimension
        settings.getUserInfo()
        network.fetchData(tableView: timeTableView, pickedDate: pickedDate)
        NotificationCenter.default.addObserver(self, selector: #selector(refetchData), name:NSNotification.Name(rawValue: "updateGroupParameters"), object: nil)
    }
    
    @objc func refetchData() {
        print("Updating TableView")
        network.fetchData(tableView: timeTableView, pickedDate: pickedDate)
        timeTableView.reloadData()
    }
    
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
        timeTableView.reloadData()
    }

    func scrollToday(){
        datePicker.selectToday()
        dateScrollPicker(datePicker, didSelectDate: Date())
    }
    
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
}
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
        self.cell = cell
        network.configureCell(cell: cell, for: indexPath, date: pickedDate)
        var recognizer = UITapGestureRecognizer(target: self, action: #selector(checkAction))
        // Add gesture recognizer to your image view
        cell.lessonView.addGestureRecognizer(recognizer)
        cell.lessonView.isUserInteractionEnabled = true
        
        return cell
    }
    @objc func checkAction(sender : UITapGestureRecognizer) {
        print("row selected")
        print(self.cell)
        UIView.animate(withDuration: 0.2, animations: {
            self.cell.lessonView.backgroundColor = UIColor(red: 0.00, green: 0.40, blue: 0.31, alpha: 1.00)
        }, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        print("row selected")
    }
    
}
extension Date {
    func format(dateFormat: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale(identifier: "uk_UA")
        return formatter.string(from: self)
    }
    var ignoringTime: Date? {
        let dateComponents = Calendar.current.dateComponents([.day, .month, .year], from: self)
        return Calendar.current.date(from: dateComponents)
    }
}
