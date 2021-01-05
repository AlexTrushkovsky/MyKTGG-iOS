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
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var groupPicker: UIPickerView!
    @IBOutlet weak var subGroupPicker: UISegmentedControl!
    @IBOutlet weak var doneButton: UIButton!
    
    var group = [String]()
    let ref = Database.database().reference().child("users")
    let user = Auth.auth().currentUser
    lazy var groupNumChoosen = group[0]
    
    func transliterate(nonLatin: String) -> String {
        return nonLatin
            .applyingTransform(.toLatin, reverse: false)?
            .applyingTransform(.stripDiacritics, reverse: false)?
            .lowercased()
            .replacingOccurrences(of: " ", with: "") ?? nonLatin
    }
    
    @IBAction func doneButtonAction(_ sender: UIButton) {
        if !group.isEmpty{
            let groupName = "\(groupNumChoosen)"
            ref.child(user!.uid).updateChildValues(["group":groupName]) {
                (error: Error?, ref:DatabaseReference) in
                if let error = error {
                    print("Data could not be saved: \(error).")
                    self.showAlert(title: "Помилка", message: "Не вдалося зберегти дані.\n Перевірте з'єднання та спробуйте знову!")
                } else {
                    print("Data saved succesfully!")
                    print(groupName)
                    UserDefaults.standard.set(groupName, forKey: "group")
                    let transliterated = self.transliterate(nonLatin: groupName)
                    Messaging.messaging().subscribe(toTopic: transliterated) { error in
                        if let oldTopic = UserDefaults.standard.object(forKey: "subsctibedTopic") as? String {
                            Messaging.messaging().unsubscribe(fromTopic: oldTopic) { error in
                                print("Unsubscribed from \(oldTopic)")
                            }
                        }
                        UserDefaults.standard.set(transliterated, forKey: "subsctibedTopic")
                        print("Subscribed to \(transliterated) pushes")
                    }
                    self.dismiss(animated: true, completion: nil)
                }
            }
            
        }else{
            return
        }
        let subgroup = subGroupPicker.selectedSegmentIndex
        ref.child(user!.uid).updateChildValues(["subgroup":subgroup]) {
            (error: Error?, ref:DatabaseReference) in
            if let error = error {
                print("Data could not be saved: \(error).")
                self.showAlert(title: "Помилка", message: "Не вдалося зберегти дані.\n Перевірте з'єднання та спробуйте знову!")
            } else {
                print("Data saved succesfully!")
                print("subgroupIndex = \(subgroup)")
                UserDefaults.standard.set(subgroup, forKey: "subGroup")
                self.dismiss(animated: true, completion: nil)
            }
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton.layer.cornerRadius = doneButton.bounds.height/2
        groupPicker.delegate = self
        selectCurrentGroupOnPicker()
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
