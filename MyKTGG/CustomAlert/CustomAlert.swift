//
//  CustomAlert.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 04.08.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit

protocol CustomAlertDelegate {
    func cancelAction()
    func okAction()
}

enum AlertStatus {
    case alert
    case lateAlarm
    case alarmRequest
    case alarmTurned
    case note
}

class CustomAlert: UIView {
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var alarmSegment: UISegmentedControl!
    @IBAction func alarmSegment(_ sender: UISegmentedControl) {
        guard let text = sender.titleForSegment(at: sender.selectedSegmentIndex) else { return }
        subTitleLabel.text = "буде заведено за \(text) годину до пари"
    }
    
    
    var delegate: CustomAlertDelegate?
    
    @IBAction func cancelAction(_ sender: Any) {
        delegate?.cancelAction()
    }
    @IBAction func okAction(_ sender: Any) {
        delegate?.okAction()
    }
    @IBOutlet weak var cancelOutlet: UIButton!
    @IBOutlet weak var okOutlet: UIButton!
    
    func setStyle(type: AlertStatus) {
        backgroundView.roundCorners(corners: [.bottomLeft, .topRight], radius: 50)
        cancelOutlet.layer.cornerRadius = 10
        okOutlet.layer.cornerRadius = 10
        cancelOutlet.backgroundColor = UIColor(red: 0.96, green: 0.91, blue: 0.91, alpha: 1.00)
        cancelOutlet.setTitleColor(UIColor(red: 0.77, green: 0.30, blue: 0.30, alpha: 1.00), for: .normal)
        
        switch type {
        case .alarmRequest:
            print("alarmRequest")
            cancelOutlet.isHidden = false
            okOutlet.isHidden = false
            textField.isHidden = true
            textLabel.isHidden = true
            alarmSegment.isHidden = false
            break
        case .alarmTurned:
            print("alarmTurned")
            cancelOutlet.isHidden = false
            okOutlet.isHidden = false
            textField.isHidden = true
            textLabel.isHidden = false
            alarmSegment.isHidden = true
            break
        case .alert:
            print("alert")
            cancelOutlet.isHidden = true
            okOutlet.isHidden = false
            textField.isHidden = true
            textLabel.isHidden = false
            alarmSegment.isHidden = true
            break
        case .lateAlarm:
            print("lateAlert")
            cancelOutlet.isHidden = true
            okOutlet.isHidden = false
            textField.isHidden = true
            textLabel.isHidden = false
            alarmSegment.isHidden = true
            break
        case .note:
            print("note")
            cancelOutlet.isHidden = false
            okOutlet.isHidden = false
            textLabel.isHidden = true
            textField.isHidden = false
            textLabel.isHidden = false
            alarmSegment.isHidden = true
            break
        }
    }
    
    func setText(title: String, subTitle: String, body: String) {
        titleLabel.text = title
        subTitleLabel.text = subTitle//
        textLabel.text = body
    }
    
}
