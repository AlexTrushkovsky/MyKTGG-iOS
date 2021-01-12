//
//  AvatarMethods.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 08.05.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit
import GoogleSignIn

class AvatarMethods {
    
    func uploadAvatar(photo: UIImage, completion: @escaping (Result<URL, Error>) -> Void){
        guard !photo.isEqualToImage(UIImage(named: "AvatarPlaceholder")!) else { return }
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let storageRef = Storage.storage().reference().child("avatars").child(userID)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        guard let imageData = photo.jpegData(compressionQuality: 0.4) else { return }
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
                self.saveAvatarToUserDefaults(image: photo, forKey: "avatar")
            }
        }
    }
    
    func setAccName(setName: String) {
        let userID = Auth.auth().currentUser?.uid
        let db = Database.database().reference().child("users")
        db.child(userID!).child("public").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let name = value?["name"] as? String ?? ""
            
            if name != "" {
                UserDefaults.standard.set(name, forKey: "name")
                print("Updated name:",name)
            } else {
                db.child(userID!).child("public").updateChildValues(["name":setName]) {
                    (error: Error?, ref:DatabaseReference) in
                    if let error = error {
                        print("Data could not be saved: \(error).")
                    } else {
                        print("Name saved succesfully!")
                        print(setName)
                        UserDefaults.standard.set(setName, forKey: "name")
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateLabels"), object: nil)
                    }
                }
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func getAvatarFromFacebookAcc() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        let ref = Database.database().reference().child("users")
        let user = Auth.auth().currentUser
        let storageRef = Storage.storage().reference().child("avatars").child(userID)
        
        let db = Database.database().reference()
        db.child("users").child(userID).child("public").observeSingleEvent(of: .value, with: { (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            let url = value?["avatarUrl"] as? String ?? ""
            guard url != "" else {
                
                let graphRequest = GraphRequest(graphPath: "me", parameters: ["fields":"id, email, name, picture.width(480).height(480)"])
                graphRequest.start(completionHandler: { (connection, result, error) in
                    if error != nil {
                        print("Error",error!.localizedDescription)
                    } else {
                        print(result!)
                        let field = result! as? [String:Any]
                        let facebookName = field!["name"] as! String
                        self.setAccName(setName: facebookName)
                        if let imageURL = ((field!["picture"] as? [String: Any])?["data"] as? [String: Any])?["url"] as? String {
                            print(imageURL)
                            let url  = NSURL(string: imageURL)! as URL
                            let data = NSData(contentsOf: url)
                            
                            storageRef.putData(data! as Data, metadata: metadata) { (metadata, error) in
                                guard metadata != nil else {
                                    print("unable to upload Google avatar to firebase")
                                    return
                                }
                                print("image from Google Acc succesfully uploaded to firebase")
                                storageRef.downloadURL { (url, error) in
                                    guard url != nil else {
                                        return
                                    }
                                    guard let photo = UIImage(data: data! as Data) else { return }
                                    self.saveAvatarToUserDefaults(image: photo, forKey: "avatar")
                                    
                                    ref.child(user!.uid).child("public").updateChildValues(["avatarUrl":"\(url!)"]) {
                                        (error: Error?, ref:DatabaseReference) in
                                        if let error = error {
                                            print("Data could not be saved: \(error).")
                                        } else {
                                            print("Photo saved succesfully!")
                                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateAvatar"), object: nil)
                                        }
                                    }
                                }
                            }
                        }
                    }
                })
                return
            }
        })
    }
    
    func getAvatarFromGoogleAcc() {
        if (GIDSignIn.sharedInstance().currentUser != nil) {
            
            let imageUrl = GIDSignIn.sharedInstance().currentUser.profile.imageURL(withDimension: 400).absoluteString
            let url  = NSURL(string: imageUrl)! as URL
            let data = NSData(contentsOf: url)
            guard let userID = Auth.auth().currentUser?.uid else { return }
            let storageRef = Storage.storage().reference().child("avatars").child(userID)
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            let ref = Database.database().reference().child("users")
            let user = Auth.auth().currentUser
            
            let db = Database.database().reference()
            db.child("users").child(userID).child("public").observeSingleEvent(of: .value, with: { (snapshot) in
                
                let value = snapshot.value as? NSDictionary
                let url = value?["avatarUrl"] as? String ?? ""
                guard url != "" else {
                    storageRef.putData(data! as Data, metadata: metadata) { (metadata, error) in
                        guard metadata != nil else {
                            print("unable to upload Google avatar to firebase")
                            return
                        }
                        print("image from Google Acc succesfully uploaded to firebase")
                        storageRef.downloadURL { (url, error) in
                            guard url != nil else {
                                return
                            }
                            guard let photo = UIImage(data: data! as Data) else { return }
                            self.saveAvatarToUserDefaults(image: photo, forKey: "avatar")
                        }
                        ref.child(user!.uid).updateChildValues(["avatarUrl":"\(url)"]) {
                            (error: Error?, ref:DatabaseReference) in
                            if let error = error {
                                print("Data could not be saved: \(error).")
                            } else {
                                print("Photo saved succesfully!")
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateAvatar"), object: nil)
                            }
                        }
                    }
                    return
                }
            })
        }
    }
    
    func downloadAvatar(avatarView: UIImageView){
        print("downloading avatar...")
        let userID = Auth.auth().currentUser?.uid
        let db = Database.database().reference()
        db.child("users").child(userID!).child("public").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let url = value?["avatarUrl"] as? String ?? ""
            guard url != "" else { return }
            let ref = Storage.storage().reference(forURL: url)
            let megaByte = Int64(1 * 1024 * 1024)
            ref.getData(maxSize: megaByte) { (data, error) in
                guard let imageData = data else { return }
                guard let image = UIImage(data: imageData) else { return }
                avatarView.image = image
                self.saveAvatarToUserDefaults(image: image, forKey: "avatar")
            }
        }) { (error) in
            if let placeholder = UIImage(named: "AvatarPlaceholder") {
                print("setting standart avatar")
                avatarView.image = placeholder
            }
            print(error.localizedDescription)
        }
    }
    
    func saveAvatarToUserDefaults(image: UIImage, forKey key: String) {
        print("Saving avatar to userDefaults")
        if let pngRepresentation = image.pngData() {
            UserDefaults.standard.set(pngRepresentation, forKey: key)
        }
    }
    
    func getAvatarFromUserDefaults(forKey key: String, imageView: UIImageView){
        print("Get avatar from userDefaults")
        if let imageData = UserDefaults.standard.object(forKey: key) as? Data,
            let image = UIImage(data: imageData) {
            imageView.image = image
            downloadAvatar(avatarView: imageView)
        } else {
            print("avatar not fount in user defaults")
            if let placeholder = UIImage(named: "AvatarPlaceholder") {
                print("setting standart avatar")
                DispatchQueue.main.async {
                    imageView.image = placeholder
                }
            }
            downloadAvatar(avatarView: imageView)
        }
    }
    
    func setupUserImageView(avatarContainer: UIView, imageView: UIImageView) {
        imageView.clipsToBounds = true
        imageView.applyshadowWithCorner(containerView: avatarContainer, cornerRadious: imageView.frame.height/2)
    }
}

extension UIImage {

    func isEqualToImage(_ image: UIImage) -> Bool {
        let data1 = self.pngData()
        let data2 = image.pngData()
        return data1 == data2
    }

}

extension UIImageView {
    func applyshadowWithCorner(containerView : UIView, cornerRadious : CGFloat){
        containerView.clipsToBounds = false
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.2
        containerView.layer.shadowOffset = CGSize.zero
        containerView.layer.shadowRadius = 3
        containerView.layer.cornerRadius = cornerRadious
        containerView.layer.shadowPath = UIBezierPath(roundedRect: containerView.bounds, cornerRadius: cornerRadious).cgPath
        self.clipsToBounds = true
        self.layer.cornerRadius = cornerRadious
    }
}
