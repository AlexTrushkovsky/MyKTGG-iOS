//
//  UserEditorTableViewController.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 08.05.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit
import Firebase

class UserEditorTableViewController: UITableViewController {
    
    @IBOutlet weak var logOutButton: UIButton!
    
    @IBOutlet weak var EditorAvatar: UIImageView!
    @IBOutlet weak var FirstLastNameOutlet: UITextField!
    @IBOutlet weak var DoneButtonOutlet: UIBarButtonItem!
    
    @IBOutlet weak var subgroupPicker: UISegmentedControl!
    @IBOutlet weak var GroupPicker: UIPickerView!
    
    @IBOutlet weak var changePassField: UITextField!
    @IBOutlet weak var changePassConfirmField: UITextField!
    
    var group = [String]()
    let ref = Database.database().reference().child("users")
    let user = Auth.auth().currentUser
    lazy var groupNumChoosen = group[0]
    
    @IBAction func changePassAction(_ sender: Any) {
        if changePassField.text == changePassConfirmField.text {
            if changePassConfirmField.text!.count > 6 {
                Auth.auth().currentUser?.updatePassword(to: changePassConfirmField.text!) { (error) in
                    if let error = error {
                        print("Pass change error: \(error)")
                        self.showAlert(title: "Помилка", message: "\(error.localizedDescription)")
                    } else {
                        self.showAlert(title: "Успіх", message: "Пароль успішно змінено!")
                    }
                }
            } else {
                self.showAlert(title: "Помилка", message: "пароль має містити більше 6 символів")
            }
        } else {
            self.showAlert(title: "Помилка", message: "паролі не співпадають")
        }
    }
    
    func transliterate(nonLatin: String) -> String {
        return nonLatin
            .applyingTransform(.toLatin, reverse: false)?
            .applyingTransform(.stripDiacritics, reverse: false)?
            .lowercased()
            .replacingOccurrences(of: " ", with: "") ?? nonLatin
    }
    
    @IBAction func DoneButtonAction(_ sender: UIButton) {
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
                    self.navigationController?.popViewController(animated: true)
                }
            }
                
            }else{
                return
            }
            let subgroup = subgroupPicker.selectedSegmentIndex
            ref.child(user!.uid).updateChildValues(["subgroup":subgroup]) {
                (error: Error?, ref:DatabaseReference) in
                if let error = error {
                    print("Data could not be saved: \(error).")
                    self.showAlert(title: "Помилка", message: "Не вдалося зберегти дані.\n Перевірте з'єднання та спробуйте знову!")
                } else {
                    print("Data saved succesfully!")
                    print("subgroupIndex = \(subgroup)")
                    UserDefaults.standard.set(subgroup, forKey: "subGroup")
                    self.navigationController?.popViewController(animated: true)
                }
            }
            saveEdited()
            navigationController?.popViewController(animated: true)
        }
        
        @IBAction func logOutAction(_ sender: UIButton) {
            navigationController?.popViewController(animated: true)
            logOut()
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            let avatar = AvatarMethods()
            avatar.setupUserImageView(imageView: EditorAvatar)
            avatar.getAvatarFromUserDefaults(forKey: "avatar", imageView: EditorAvatar)
            FirstLastNameOutlet.text = getUserName()
            FirstLastNameOutlet.addTarget(self, action: #selector(textFieldChange), for: .editingChanged)
            logOutButton.layer.cornerRadius = 15
            GroupPicker.delegate = self
            selectCurrentGroupOnPicker()
            hideKeyboardWhenTappedAround()
        }
        
        func selectCurrentGroupOnPicker() {
            if let group = UserDefaults.standard.object(forKey: "group") as? String{
                print(group)
                guard let firstIndex = self.group.firstIndex(of: String(group)) else { return }
                GroupPicker.selectRow(firstIndex, inComponent: 0, animated: true)
                groupNumChoosen = self.group[firstIndex]
            }
            if let subGroup = UserDefaults.standard.object(forKey: "subGroup") as? Int{
                subgroupPicker.selectedSegmentIndex = subGroup
            }
        }
        
        func getUserName() -> String?{
            if let name = UserDefaults.standard.object(forKey: "name"),
               let text = name as? String {
                return text
            }
            return nil
        }
        
        func logOut(){
            if let oldTopic = UserDefaults.standard.object(forKey: "subsctibedTopic") as? String {
                Messaging.messaging().unsubscribe(fromTopic: oldTopic) { error in
                    print("Unsubscribed from \(oldTopic)")
                }
            }
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            UserDefaults.standard.synchronize()
            do{
                try Auth.auth().signOut()
            }catch{
                print(error)
            }
        }
        
        func saveEdited() {
            
            if FirstLastNameOutlet.text != "" {
                let name = FirstLastNameOutlet.text
                UserDefaults.standard.set(name, forKey: "name")
                let ref = Database.database().reference().child("users")
                let user = Auth.auth().currentUser
                ref.child(user!.uid).updateChildValues(["name":name!]) {
                    (error: Error?, ref:DatabaseReference) in
                    if let error = error {
                        print("Data could not be saved: \(error).")
                    } else {
                        print("Name saved succesfully!")
                        print(name!)
                        UserDefaults.standard.set(name, forKey: "name")
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateLabels"), object: nil)
                    }
                }
            }
            
            let avatar = AvatarMethods()
            avatar.uploadAvatar(photo: EditorAvatar.image!) { (result) in
                switch result {
                
                case .success(let url):
                    let ref = Database.database().reference().child("users")
                    let user = Auth.auth().currentUser
                    ref.child(user!.uid).updateChildValues(["avatarUrl":"\(url)"]) {
                        (error: Error?, ref:DatabaseReference) in
                        if let error = error {
                            print("Data could not be saved: \(error).")
                        } else {
                            print("Photo saved succesfully!")
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateAvatar"), object: nil)
                        }
                    }
                case .failure(_): break
                }
            }
        }
        
        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            if indexPath.section == 0{
                if indexPath.row == 0{
                    let cameraImage = #imageLiteral(resourceName: "camera")
                    let photoImage = #imageLiteral(resourceName: "photo")
                    let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                    let camera = UIAlertAction(title: "зробити фото", style: .default){_ in
                        self.chooseImagePicker(source: .camera)
                    }
                    camera.setValue(cameraImage, forKey: "image")
                    camera.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
                    let photo = UIAlertAction(title: "обрати з галереї", style: .default){_ in
                        self.chooseImagePicker(source: .photoLibrary)
                    }
                    photo.setValue(photoImage, forKey: "image")
                    photo.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
                    let cancel = UIAlertAction(title: "Скасувати", style: .cancel )
                    actionSheet.addAction(camera)
                    actionSheet.addAction(photo)
                    actionSheet.addAction(cancel)
                    present(actionSheet, animated: true)
                    tableView.deselectRow(at: indexPath, animated: true)
                }
            }
        }
        
        func showAlert(title: String, message: String){
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ОК", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    extension UserEditorTableViewController: UITextFieldDelegate {
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
        @objc private func textFieldChange(){
            if FirstLastNameOutlet.text?.isEmpty == false{
                DoneButtonOutlet.isEnabled = true
            }else{
                DoneButtonOutlet.isEnabled = false
            }
        }
    }
    extension UserEditorTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
        
        func chooseImagePicker(source: UIImagePickerController.SourceType){
            if UIImagePickerController.isSourceTypeAvailable(source){
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.allowsEditing=true
                imagePicker.sourceType=source
                present(imagePicker, animated: true)
            }
        }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            EditorAvatar.image = info[.editedImage] as? UIImage
            EditorAvatar.contentMode = .scaleAspectFill
            EditorAvatar.clipsToBounds = true
            DoneButtonOutlet.isEnabled = true
            dismiss(animated: true)
        }
    }
    extension UserEditorTableViewController: UIPickerViewDataSource, UIPickerViewDelegate {
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
    extension UIViewController {
        func hideKeyboardWhenTappedAround() {
            let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
            tap.cancelsTouchesInView = false
            view.addGestureRecognizer(tap)
        }
        
        @objc func dismissKeyboard() {
            view.endEditing(true)
        }
    }
