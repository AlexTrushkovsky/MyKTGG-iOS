//
//  GroupChooseViewController.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 23.12.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit
import Firebase

class GroupChooseViewController: UIViewController {
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var label: UIView!
    @IBOutlet weak var groupPicker: UIPickerView!
    @IBOutlet weak var subGroupPicker: UISegmentedControl!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var userTypeButton: UIButton!
    
    var group = [String]()
    let groupCheck = GroupNetworkController()
    let ref = Database.database().reference().child("users")
    let user = Auth.auth().currentUser
    lazy var groupNumChoosen = group[0]
    var isStudent:Bool = true{
        willSet{
            if newValue{
                userTypeButton.setTitle("Обрати викладача", for: .normal)
                subGroupPicker.isHidden = false
                setLabel(view: label, text: "Оберіть групу")
            }else{
                userTypeButton.setTitle("Обрати групу", for: .normal)
                subGroupPicker.isHidden = true
                setLabel(view: label, text: "Оберіть викладача")
            }
        }
    }
    
    func transliterate(nonLatin: String) -> String {
        return nonLatin
            .applyingTransform(.toLatin, reverse: false)?
            .applyingTransform(.stripDiacritics, reverse: false)?
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "`", with: "") ?? nonLatin
    }
    @IBAction func userTypeButton(_ sender: UIButton) {
        isStudent = !isStudent
        group = groupCheck.fetchData(isStudent: isStudent)
        selectCurrentGroupOnPicker()
        groupPicker.reloadAllComponents()
    }
    
    @IBAction func doneButtonAction(_ sender: UIButton) {
        if !group.isEmpty{
            let groupName = "\(groupNumChoosen)"
            ref.child(user!.uid).child("public").updateChildValues(["group":groupName]) {
                (error: Error?, ref:DatabaseReference) in
                if let error = error {
                    print("Data could not be saved: \(error).")
                    self.showAlert(title: "Помилка", message: "Не вдалося зберегти дані.\n Перевірте з'єднання та спробуйте знову!")
                } else {
                    print("Data saved succesfully!")
                    print(groupName)
                    UserDefaults.standard.set(groupName, forKey: "group")
                    let transliterated = self.transliterate(nonLatin: groupName)
                    if let oldTopic = UserDefaults.standard.object(forKey: "subsctibedTopic") as? String {
                        Messaging.messaging().unsubscribe(fromTopic: oldTopic) { error in
                            print("Unsubscribed from \(oldTopic)")
                            Messaging.messaging().subscribe(toTopic: transliterated) { error in
                                print("Subscribed to \(transliterated) pushes")
                                UserDefaults.standard.set(transliterated, forKey: "subsctibedTopic")
                            }
                        }
                    }
                    if let oldChangesTopic = UserDefaults.standard.object(forKey: "groupOfChangeSubscription") as? String {
                        Messaging.messaging().unsubscribe(fromTopic: "/topics/changesOf\(oldChangesTopic)") { error in
                            print("Unsubscribed from \(oldChangesTopic) changes")
                            UserDefaults.standard.set(nil,forKey: "groupOfChangeSubscription")
                            let group = self.transliterate(nonLatin: groupName)
                            Messaging.messaging().subscribe(toTopic: "/topics/changesOf\(group)") { error in
                                print("Subscribed to \(group) changes")
                                UserDefaults.standard.set(group,forKey: "groupOfChangeSubscription")
                            }
                        }
                    }
                    self.dismiss(animated: true, completion: nil)
                }
            }
            
        }else{
            return
        }
        if !subGroupPicker.isHidden {
            let subgroup = subGroupPicker.selectedSegmentIndex
            ref.child(user!.uid).child("public").updateChildValues(["subgroup":subgroup]) {
                (error: Error?, ref:DatabaseReference) in
                if let error = error {
                    print("Data could not be saved: \(error).")
                    self.showAlert(title: "Помилка", message: "Не вдалося зберегти дані.\n Перевірте з'єднання та спробуйте знову!")
                } else {
                    print("Data saved succesfully!")
                    print("subgroupIndex:  \(subgroup)")
                    UserDefaults.standard.set(subgroup, forKey: "subGroup")
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
        saveVerification()
        saveUserType()
        self.dismiss(animated: true, completion: nil)
    }
    
    func saveUserType() {
        let userType = isStudent
        ref.child(user!.uid).child("public").updateChildValues(["isStudent":userType]) {
            (error: Error?, ref:DatabaseReference) in
            if let error = error {
                print("Data could not be saved: \(error).")
                self.showAlert(title: "Помилка", message: "Не вдалося зберегти дані.\n Перевірте з'єднання та спробуйте знову!")
            } else {
                print("Data saved succesfully!")
                print("isStudent:  \(userType)")
                UserDefaults.standard.set(userType, forKey: "isStudent")
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func saveVerification() {
        ref.child("users").child(user!.uid).child("secure").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            if let verified = value?["verified"] as? String {
                print("verified account of: \(verified)")
                UserDefaults.standard.set(verified, forKey: "verified")
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        shadowView.layer.cornerRadius = 36
        shadowView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
              shadowView.layer.shadowColor = UIColor.black.cgColor
              shadowView.layer.shadowOffset = .zero
              shadowView.layer.shadowRadius = 20
        shadowView.layer.shadowOpacity = 0.2
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton.applyGradient(colors: [CustomButton.UIColorFromRGB(0x4BB179).cgColor,CustomButton.UIColorFromRGB(0x1291AB).cgColor])
        groupPicker.delegate = self
        getCurrentUserType()
        group = groupCheck.fetchData(isStudent: isStudent)
        selectCurrentGroupOnPicker()
        setLabel(view: label, text: "Оберіть групу")
    }
    
    func getCurrentUserType() {
        guard let userType = UserDefaults.standard.object(forKey: "userType") as? Bool else { return }
        self.isStudent = userType
    }
    
    func selectCurrentGroupOnPicker() {
        if let group = UserDefaults.standard.object(forKey: "group") as? String{
            print(group)
            guard let firstIndex = self.group.firstIndex(of: String(group)) else { return }
            groupPicker.selectRow(firstIndex, inComponent: 0, animated: true)
            groupNumChoosen = self.group[firstIndex]
        }
        if let subGroup = UserDefaults.standard.object(forKey: "subGroup") as? Int{
            subGroupPicker.selectedSegmentIndex = subGroup
        }
    }
    
    func setLabel(view: UIView, text: String) {
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor(red: 0.07, green: 0.57, blue: 0.67, alpha: 1.00).cgColor, UIColor(red: 0.29, green: 0.69, blue: 0.47, alpha: 1.00).cgColor]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradient.frame = view.bounds
        view.layer.addSublayer(gradient)
        let label = UILabel(frame: view.bounds)
        label.text = text
        label.font = UIFont(name: "SourceSansPro-Bold", size: 30)
        label.textAlignment = .center
        label.layer.shadowOffset = .zero
        label.layer.shadowRadius = 3
        label.layer.shadowOpacity = 0.3
        label.layer.masksToBounds = false
        label.layer.shouldRasterize = true
        label.layer.shadowColor = UIColor(red: 0.02, green: 0.58, blue: 0.26, alpha: 1).cgColor
        view.addSubview(label)
        view.mask = label
    }
    
    func showAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
extension GroupChooseViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.group.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.group[row];
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        return groupNumChoosen = "\(self.group[row])"
    }
}
