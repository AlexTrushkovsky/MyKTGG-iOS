//
//  AvatarMethods.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 08.05.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit
import Firebase

class AvatarMethods {
    
    func uploadAvatar(photo: UIImage, completion: @escaping (Result<URL, Error>) -> Void){
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
    
    func downloadAvatar(avatarView: UIImageView){
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
                guard let image = UIImage(data: imageData) else { return }
                avatarView.image = image
                self.saveAvatarToUserDefaults(image: image, forKey: "avatar")
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func saveAvatarToUserDefaults(image: UIImage, forKey key: String) {
        if let pngRepresentation = image.pngData() {
            UserDefaults.standard.set(pngRepresentation, forKey: key)
        }
    }
    
     func getAvatarFromUserDefaults(forKey key: String, imageView: UIImageView){
            if let imageData = UserDefaults.standard.object(forKey: key) as? Data,
                let image = UIImage(data: imageData) {
                imageView.image = image
                downloadAvatar(avatarView: imageView)
            } else {
                downloadAvatar(avatarView: imageView)
        }
    }
    
    func setupUserImageView(imageView: UIImageView) {
        imageView.layer.borderWidth = 1
        imageView.layer.masksToBounds = false
        imageView.layer.borderColor = UIColor.black.cgColor
        imageView.layer.cornerRadius = imageView.frame.height/2
        imageView.clipsToBounds = true
    }
    
}
