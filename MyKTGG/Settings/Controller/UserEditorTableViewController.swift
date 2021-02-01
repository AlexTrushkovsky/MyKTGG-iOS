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
    
    @IBOutlet weak var groupPickerIndicator: UIActivityIndicatorView!
    @IBOutlet weak var userTypeButton: UIButton!
    @IBOutlet weak var showIdentifierButton: UIButton!
    @IBOutlet weak var identifireTextField: UITextField!
    @IBOutlet weak var logOutButton: UIButton!
    @IBOutlet weak var EditorAvatar: UIImageView!
    @IBOutlet weak var FirstLastNameOutlet: UITextField!
    @IBOutlet weak var DoneButtonOutlet: UIBarButtonItem!
    @IBOutlet weak var subgroupPicker: UISegmentedControl!
    @IBOutlet weak var GroupPicker: UIPickerView!
    @IBOutlet weak var changePassField: UITextField!
    @IBOutlet weak var changePassConfirmField: UITextField!
    @IBOutlet weak var avatarContainer: UIView!
    
    var group = [String]()
    let ref = Database.database().reference().child("users")
    lazy var groupNumChoosen = group[0]
    let avatarMethods = AvatarMethods()
    let groupCheck = GroupNetworkController()
    var isStudent = true
    
    @IBAction func userTypeButton(_ sender: UIButton) {
        isStudent = !isStudent
        groupPickerIndicator.backgroundColor = UIColor(white: 0.5, alpha: 0.2)
        groupPickerIndicator.startAnimating()
        DispatchQueue.global().async {
            self.group = self.groupCheck.fetchData(isStudent: self.isStudent)
            DispatchQueue.main.async {
                self.GroupPicker.isUserInteractionEnabled = true
                self.formatGroupPickerSection()
                self.selectCurrentGroupOnPicker()
                self.GroupPicker.reloadAllComponents()
                self.groupPickerIndicator.stopAnimating()
            }
        }
    }
    
    
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
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "`", with: "") ?? nonLatin
    }
    
    @IBAction func DoneButtonAction(_ sender: UIButton) {
        guard let user = Auth.auth().currentUser else { return }
        if !group.isEmpty{
            let groupName = "\(groupNumChoosen)"
            ref.child(user.uid).child("public").updateChildValues(["group":groupName]) {
                (error: Error?, ref:DatabaseReference) in
                if let error = error {
                    print("Data could not be saved: \(error).")
                    self.showAlert(title: "Помилка", message: "Не вдалося зберегти дані.\n Перевірте з'єднання та спробуйте знову!")
                } else {
                    print("Data saved succesfully!")
                    print(groupName)
                    if let oldTopic = UserDefaults.standard.object(forKey: "subsctibedTopic") as? String {
                        Messaging.messaging().unsubscribe(fromTopic: oldTopic) { error in
                            print("Unsubscribed from \(oldTopic) pushes")
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
                    self.navigationController?.popViewController(animated: true)
                }
            }
            
        }else{
            return
        }
        if isStudent {
            let subgroup = subgroupPicker.selectedSegmentIndex
            ref.child(user.uid).child("public").updateChildValues(["subgroup":subgroup]) {
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
        saveIsStudent()
        saveEdited()
        navigationController?.popViewController(animated: true)
    }
    
    func saveIsStudent() {
        guard let user = Auth.auth().currentUser else { return }
        ref.child(user.uid).child("public").updateChildValues(["isStudent":isStudent]) {
            (error: Error?, ref:DatabaseReference) in
            if let error = error {
                print("Data could not be saved: \(error).")
                self.showAlert(title: "Помилка", message: "Не вдалося зберегти дані.\n Перевірте з'єднання та спробуйте знову!")
            } else {
                print("Data saved succesfully!")
                print("isStudent: \(self.isStudent)")
                UserDefaults.standard.set(self.isStudent, forKey: "isStudent")
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func logOutAction(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
        logOut()
    }
    @IBAction func showIdentifier(_ sender: Any) {
        UIView.animate(withDuration: 0.3) {
            guard let user = Auth.auth().currentUser else { return }
            self.showIdentifierButton.alpha = 0
            self.identifireTextField.text = user.uid
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
        avatarMethods.setupUserImageView(avatarContainer: avatarContainer, imageView: EditorAvatar)
        updateAvatar()
        NotificationCenter.default.addObserver(self, selector: #selector(updateAvatar), name:NSNotification.Name(rawValue: "updateAvatar"), object: nil)
        FirstLastNameOutlet.text = getUserName()
        FirstLastNameOutlet.addTarget(self, action: #selector(textFieldChange), for: .editingChanged)
        logOutButton.layer.cornerRadius = 15
        GroupPicker.delegate = self
        selectCurrentGroupOnPicker()
        hideKeyboardWhenTappedAround()
        identifireTextField.inputView = nil
        formatGroupPickerSection()
    }
    
    func formatGroupPickerSection() {
        if self.isStudent {
            userTypeButton.setTitle("Обрати викладача", for: .normal)
            subgroupPicker.isHidden = false
        } else {
            userTypeButton.setTitle("Обрати групу", for: .normal)
            subgroupPicker.isHidden = true
            tableView.rowHeight = 0
        }
    }
    
    @objc func updateAvatar() {
        avatarMethods.getAvatarFromUserDefaults(forKey: "avatar", imageView: EditorAvatar)
    }
    
    func selectCurrentGroupOnPicker() {
        if let group = UserDefaults.standard.object(forKey: "group") as? String{
            print(group)
            if let firstIndex = self.group.firstIndex(of: String(group)) {
                GroupPicker.selectRow(firstIndex, inComponent: 0, animated: true)
                groupNumChoosen = self.group[firstIndex]
            } else {
                GroupPicker.selectRow(0, inComponent: 0, animated: true)
                groupNumChoosen = self.group[0]
            }
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
                print("Unsubscribed from \(oldTopic) pushes")
            }
        }
        
        if let oldChangesTopic = UserDefaults.standard.object(forKey: "groupOfChangeSubscription") as? String {
            Messaging.messaging().unsubscribe(fromTopic: "/topics/changesOf\(oldChangesTopic)") { error in
                print("Unsubscribed from \(oldChangesTopic) changes")
            }
        }
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        if let groupDefaults = UserDefaults(suiteName: "group.myktgg") {
            groupDefaults.removeObject(forKey: "pushes")
        }
        UserDefaults.standard.synchronize()
        do{
            try Auth.auth().signOut()
        }catch{
            print(error)
        }
    }
    
    func saveEdited() {
        if FirstLastNameOutlet.text != "" {
            guard let name = FirstLastNameOutlet.text else { return }
            UserDefaults.standard.set(name, forKey: "name")
            let ref = Database.database().reference().child("users")
            guard let user = Auth.auth().currentUser else { return }
            ref.child(user.uid).child("public").updateChildValues(["name":name]) {
                (error: Error?, ref:DatabaseReference) in
                if let error = error {
                    print("Data could not be saved: \(error).")
                } else {
                    print("Name saved succesfully!")
                    print(name)
                    UserDefaults.standard.set(name, forKey: "name")
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateLabels"), object: nil)
                }
            }
        }
        
        let avatar = AvatarMethods()
        guard let image = EditorAvatar.image else { return }
        avatar.uploadAvatar(photo: image) { (result) in
            switch result {
            case .success(let url):
                let ref = Database.database().reference().child("users")
                guard let user = Auth.auth().currentUser else { return }
                ref.child(user.uid).child("public").updateChildValues(["avatarUrl":"\(url)"]) {
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
                actionSheet.view.tintColor = UIColor(red: 0.30, green: 0.77, blue: 0.57, alpha: 1.00)
                let camera = UIAlertAction(title: "Зробити фото", style: .default){_ in
                    self.chooseImagePicker(source: .camera)
                }
                camera.setValue(cameraImage, forKey: "image")
                camera.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
                let photo = UIAlertAction(title: "Обрати з галереї", style: .default){_ in
                    self.chooseImagePicker(source: .photoLibrary)
                }
                photo.setValue(photoImage, forKey: "image")
                photo.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
                let cancel = UIAlertAction(title: "Скасувати", style: .cancel)
                cancel.setValue(UIColor(red: 0.77, green: 0.30, blue: 0.30, alpha: 1.00), forKey: "titleTextColor")
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

extension UIAlertController {

    //Set background color of UIAlertController
    func setBackgroundColor(color: UIColor) {
        if let bgView = self.view.subviews.first, let groupView = bgView.subviews.first, let contentView = groupView.subviews.first {
            contentView.backgroundColor = color
        }
    }

    //Set title font and title color
    func setTitlet(font: UIFont?, color: UIColor?) {
        guard let title = self.title else { return }
        let attributeString = NSMutableAttributedString(string: title)//1
        if let titleFont = font {
            attributeString.addAttributes([NSAttributedString.Key.font : titleFont],//2
                                          range: NSMakeRange(0, title.utf8.count))
        }

        if let titleColor = color {
            attributeString.addAttributes([NSAttributedString.Key.foregroundColor : titleColor],//3
                                          range: NSMakeRange(0, title.utf8.count))
        }
        self.setValue(attributeString, forKey: "attributedTitle")//4
    }

    //Set message font and message color
    func setMessage(font: UIFont?, color: UIColor?) {
        guard let message = self.message else { return }
        let attributeString = NSMutableAttributedString(string: message)
        if let messageFont = font {
            attributeString.addAttributes([NSAttributedString.Key.font : messageFont],
                                          range: NSMakeRange(0, message.utf8.count))
        }

        if let messageColorColor = color {
            attributeString.addAttributes([NSAttributedString.Key.foregroundColor : messageColorColor],
                                          range: NSMakeRange(0, message.utf8.count))
        }
        self.setValue(attributeString, forKey: "attributedMessage")
    }

    //Set tint color of UIAlertController
    func setTint(color: UIColor) {
        self.view.tintColor = color
    }
}
