//
//  SettingsTableViewController.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 11.04.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//
import UIKit
import Firebase
import FirebaseStorage

class SettingsViewController: UITableViewController {
    
    //let defaults = UserDefaults.standard
    private var editMode = false
    private var userName = ""
    private var group = ""
    private var userNameIsChanged = false
    @IBOutlet weak var groupLabel: UILabel!
    @IBOutlet weak var UserNameLabel: UILabel!
    @IBAction func logOutAction(_ sender: UIButton) {
        do{
            try Auth.auth().signOut()
        }catch{
            print(error)
        }
    }
    
    @IBOutlet weak var FirstLastNameOutlet: UITextField!
    @IBOutlet weak var DoneButtonOutlet: UIBarButtonItem!
    @IBAction func DoneButtonAction(_ sender: UIButton) {
        uploadAvatar(photo: userImage.image!) { (result) in
            switch result {
                
            case .success(let url):
                let ref = Database.database().reference().child("users")
                let user = Auth.auth().currentUser
                ref.child(user!.uid).updateChildValues(["avatarUrl":"\(url)"]) {
                    (error: Error?, ref:DatabaseReference) in
                    if let error = error {
                        print("Data could not be saved: \(error).")
                    } else {
                        print("Data saved succesfully!")
                        
                    }
                }
            case .failure(_): break
            }
        }
    }
    
    func getUserInfo(){
        let userID = Auth.auth().currentUser?.uid
        let db = Database.database().reference()
        db.child("users").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let name = value?["name"] as? String ?? ""
            let group = value?["group"] as? String ?? ""
            guard name != "" else { return }
            print(name)
            //            if self.editMode == false {
            //                self.FirstLastNameOutlet.text = name
            //            } else {
            //                self.UserNameLabel.text = name
            //            }
            self.userName = name
            guard group != "" else { return }
            print(group)
            //            if self.editMode {
            //                self.groupLabel.text = group
            //            }
            self.group = group
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func downloadAvatar(){
        let userID = Auth.auth().currentUser?.uid
        let db = Database.database().reference()
        db.child("users").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let url = value?["avatarUrl"] as? String ?? ""
            guard url != "" else { return }
            print(url)
            let ref = Storage.storage().reference(forURL: url)
            let megaByte = Int64(1 * 1024 * 1024)
            ref.getData(maxSize: megaByte) { (data, error) in
                guard let imageData = data else { return }
                let image = UIImage(data: imageData)
                self.userImage.image = image
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func uploadAvatar(photo: UIImage, completion: @escaping (Result<URL, Error>) -> Void){
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let storageRef = Storage.storage().reference().child("avatars").child(userID)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        guard let imageData = userImage.image?.jpegData(compressionQuality: 0.4) else { return }
        storageRef.putData(imageData, metadata: metadata) { (metadata, error) in
            guard let _ = metadata else {
                completion(.failure(error!))
                return
            }
            storageRef.downloadURL { (url, error) in
                guard let url = url else {
                    completion(.failure(error!))
                    return
                }
                completion(.success(url))
            }
        }
    }
    
    @IBOutlet weak var userImage: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        userImage.layer.borderWidth = 1
        userImage.layer.masksToBounds = false
        userImage.layer.borderColor = UIColor.black.cgColor
        userImage.layer.cornerRadius = userImage.frame.height/2
        userImage.clipsToBounds = true
        downloadAvatar()
        getUserInfo()
        //UserNameLabel.text = userName
        //groupLabel.text = group
        //FirstLastNameOutlet.text = userName
    }
    
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let text = "Розробка: Трушковський Олексій\nДизайн: Федюк Денис"
        switch (section) {
        case 4:
            return text
        default:
            return nil
        }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2{
            if indexPath.row == 0 {
                if let url = URL(string: "https://next.privat24.ua/payments/form/%7B%22token%22:%22e287b0fa-9f54-487f-9ed3-cb4f67e9a2cb%22%7D") {
                    UIApplication.shared.open(url)
                }
            }
            if indexPath.row == 1 {
                if let url = URL(string: "https://ktgg.kiev.ua/uk/") {
                    UIApplication.shared.open(url)
                }
            }
        }
        if indexPath.section == 3{
            if indexPath.row == 0{
                if let url = URL(string: "https://t.me/esen1n25") {
                    UIApplication.shared.open(url)
                    
                }
            }
        }
        if editMode == false {
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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        if identifier == "toEdit" {
            print("EditMode = true")
            editMode = true
        } else {
            print("EditMode = false")
            editMode = false
            
        }
    }
}
extension SettingsViewController: UITextFieldDelegate {
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
//Mark: Work with image
extension SettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
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
        userImage.image = info[.editedImage] as? UIImage
        userImage.contentMode = .scaleAspectFill
        userImage.clipsToBounds = true
        DoneButtonOutlet.isEnabled = true
        dismiss(animated: true)
    }
}
