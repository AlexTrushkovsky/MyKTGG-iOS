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
    
    var groupNum = [
        "11","12","13","14","15",
        "21","22","23","24","25",
        "31","32","33","34","35",
        "41","42","43","44","45"]
    var groupSpec = ["ІПЗ","КІ","ОО","ПТБД","ФБС","ПВ","ПВб","ГРС(РО)","ГРС(ГО)","ГРСб","ХТ","Т" ,"Тб","ФО"]
    var groupChoosen = ""
    let ref = Database.database().reference().child("users")
    let user = Auth.auth().currentUser
    lazy var groupNumChoosen = groupNum[0]
    lazy var groupSpecChoosen = groupSpec[0]
    
    @IBAction func doneButtonAction(_ sender: UIButton) {
        if !groupNumChoosen.isEmpty || !groupSpecChoosen.isEmpty{
            let groupName = "\(groupNumChoosen)-\(groupSpecChoosen)"
            ref.child(user!.uid).updateChildValues(["group":groupName]) {
                (error: Error?, ref:DatabaseReference) in
                if let error = error {
                    print("Data could not be saved: \(error).")
                    self.showAlert(title: "Помилка", message: "Не вдалося зберегти дані.\n Перевірте з'єднання та спробуйте знову!")
                } else {
                    print("Data saved succesfully!")
                    print(groupName)
                    UserDefaults.standard.set(groupName, forKey: "group")
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
            let first = group.prefix(2)
            let second = group.suffix(from: group.index(group.startIndex, offsetBy: 3)).filter { $0 != "-" }
            let bachelor = group.suffix(1)
            print(bachelor)
            print(first)
            print(second)
            guard let firstIndex = groupNum.firstIndex(of: String(first)) else { return }
            guard let secondIndex = groupSpec.firstIndex(of: String(second)) else { return }
            groupPicker.selectRow(firstIndex, inComponent: 0, animated: true)
            groupPicker.selectRow(secondIndex, inComponent: 1, animated: true)
            groupNumChoosen = groupNum[firstIndex]
            groupSpecChoosen = groupSpec[secondIndex]
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
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if (component == 0) {
            return groupNum.count ;
        }
        else if (component == 1) {
            return groupSpec.count ;
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if (component == 0) {
            return groupNum[row] ;
        }
        else if (component == 1) {
            return groupSpec[row] ;
        }
        return nil
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if (component == 0) {
            groupNumChoosen = "\(groupNum[row])"
        }
        else if (component == 1) {
            groupSpecChoosen = "\(groupSpec[row])"
        }
    }
}
