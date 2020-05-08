//
//  TimeTableCell.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 04.05.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit

class TimeTableCell: UITableViewCell {
    @IBOutlet weak var lessonView: UIView!
    @IBOutlet weak var timeView: UIView!
    
    @IBOutlet weak var lessonName: UILabel!
    @IBOutlet weak var lesssonType: UILabel!
    @IBOutlet weak var lessonRoom: UILabel!
    @IBOutlet weak var teacher: UILabel!
    @IBOutlet weak var startTime: UILabel!
    @IBOutlet weak var endTime: UILabel!
}