//
//  GroupChooseViewController.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 01.03.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit
import Firebase

class GroupChooseViewController: UIViewController {
    @IBOutlet weak var GroupPicker: UIPickerView!
    @IBOutlet weak var chooseButtonView: UIButton!
    @IBOutlet weak var darkView: UIView!
    @IBOutlet weak var ActivityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GroupPicker.delegate = self
        darkView.isHidden=true
        ActivityIndicator.isHidden=true
    }
    
    func showAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    var groupNum = [
        "11","12","13","14","15",
        "21","22","23","24","25",
        "31","32","33","34","35",
        "41","42","43","44","45"]
    var groupSpec = ["ІПЗ","КІ","ОО","ПТБД","ФБС","ПВ","ГРС(РО)","ГРС(ГО)","ХТ","Т"]
    var groupChoosen = ""
    let ref = Database.database().reference().child("users")
    let user = Auth.auth().currentUser
    lazy var groupNumChoosen = groupNum[0]
    lazy var groupSpecChoosen = groupSpec[0]
    @IBAction func chooseButtonAction(_ sender: UIButton) {
        darkView.isHidden=false
        ActivityIndicator.startAnimating()
        ActivityIndicator.isHidden = false
        if !groupNumChoosen.isEmpty || !groupSpecChoosen.isEmpty{
            ref.child(user!.uid).updateChildValues(["group":"\(groupNumChoosen)-\(groupSpecChoosen)"]) {
                (error: Error?, ref:DatabaseReference) in
                if let error = error {
                    print("Data could not be saved: \(error).")
                    self.showAlert(title: "Помилка", message: "Не вдалося зберегти дані.\n Перевірте з'єднання та спробуйте знову!")
                } else {
                    print("Data saved succesfully!")
                    
                }
                self.darkView.isHidden=true
                self.ActivityIndicator.stopAnimating()
                self.ActivityIndicator.isHidden = true
            }
            
        }else{
            return
        }
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
