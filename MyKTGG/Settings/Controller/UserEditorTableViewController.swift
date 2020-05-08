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
    
    @IBOutlet weak var EditorAvatar: UIImageView!
    @IBOutlet weak var FirstLastNameOutlet: UITextField!
    @IBOutlet weak var DoneButtonOutlet: UIBarButtonItem!
    @IBAction func DoneButtonAction(_ sender: UIButton) {
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
    }
    
    func getUserName() -> String?{
        if let name = UserDefaults.standard.object(forKey: "name"),
            let text = name as? String {
            return text
        }
        return nil
    }
    
    func logOut() {
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
