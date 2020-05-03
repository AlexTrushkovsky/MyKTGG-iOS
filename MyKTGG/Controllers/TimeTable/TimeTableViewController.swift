//
//  TimeTableViewController.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 01.05.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit

class TimeTableViewController: UIViewController, DateScrollPickerDelegate, DateScrollPickerDataSource {

    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var weekLabel: UILabel!
    @IBOutlet weak var monthNYearLabel: UILabel!
    @IBOutlet weak var datePicker: DateScrollPicker!
    @IBOutlet weak var todayButtonOutlet: UIButton!
    @IBAction func todayButtonAction(_ sender: UIButton) {
        scrollToday()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setupDateScroll()
        scrollToday()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        todayButtonOutlet.layer.cornerRadius = 10
    }
    
    func dateScrollPicker(_ dateScrollPicker: DateScrollPicker, didSelectDate date: Date) {
        dayLabel.text = date.format(dateFormat: "dd")
        weekLabel.text = date.format(dateFormat: "EEEE")
        monthNYearLabel.text = date.format(dateFormat: "MMM yyyy")
        if date.ignoringTime == Date().ignoringTime{
            todayButtonOutlet.backgroundColor = UIColor(red: 0.91, green: 0.96, blue: 0.94, alpha: 1.00)
            todayButtonOutlet.setTitleColor(UIColor(red: 0.30, green: 0.77, blue: 0.57, alpha: 1.00), for: .normal)
        } else {
            todayButtonOutlet.backgroundColor = UIColor(red: 0.96, green: 0.91, blue: 0.91, alpha: 1.00)
            todayButtonOutlet.setTitleColor(UIColor(red: 0.77, green: 0.30, blue: 0.30, alpha: 1.00), for: .normal)
        }
    }

    func scrollToday(){
        datePicker.selectToday()
        dateScrollPicker(datePicker, didSelectDate: Date())
    }
    
    func setupDateScroll() {
        var format = DateScrollPickerFormat()
        format.days = 6
        format.topDateFormat = "EEE"
        format.topFont = UIFont.systemFont(ofSize: 13, weight: .semibold)
        format.topTextColor = UIColor.black
        format.topTextSelectedColor = UIColor.white
        format.mediumDateFormat = "dd"
        format.mediumFont = UIFont.systemFont(ofSize: 20, weight: .bold)
        format.mediumTextColor = UIColor.black
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
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimeTableCell")
        cell?.textLabel!.text = "Cell"
        return cell!
    }
    
    
}
extension TimeTableViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TimeCell", for: indexPath)
        return cell
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
