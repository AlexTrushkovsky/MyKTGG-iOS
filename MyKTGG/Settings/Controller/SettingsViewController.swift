//
//  SettingsTableViewController.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 11.04.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//
import UIKit
import Firebase
import StoreKit

class SettingsViewController: UITableViewController {
    
    @IBAction func autoProm(_ sender: UISwitch) {
        UserDefaults.standard.set(autoPromoutionSwitch.isOn, forKey: "AutoPromStatus")
        if autoPromoutionSwitch.isOn {
            print("AutoProm is turned on")
        } else {
            print("AutoProm is turned off")
        }
    }
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var groupLabel: UILabel!
    @IBOutlet weak var subGroupLabel: UILabel!
    @IBOutlet weak var UserNameLabel: UILabel!
    @IBOutlet weak var autoPromoutionSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let avatarMethods = AvatarMethods()
        avatarMethods.setupUserImageView(imageView: avatar)
        updateLabels()
        avatarMethods.getAvatarFromUserDefaults(forKey: "avatar", imageView: avatar)
        NotificationCenter.default.addObserver(self, selector: #selector(updateAvatar), name:NSNotification.Name(rawValue: "updateAvatar"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateLabels), name:NSNotification.Name(rawValue: "updateLabels"), object: nil)
    }
    
    @objc func updateAvatar() {
        let avatarMethods = AvatarMethods()
        avatarMethods.getAvatarFromUserDefaults(forKey: "avatar", imageView: avatar)
    }
    @objc func updateLabels() {
        getUserInfo()
        setUserLabels()
    }
    
    func getUserInfo(){
        let userID = Auth.auth().currentUser?.uid
        let db = Database.database().reference()
        db.child("users").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let name = value?["name"] as? String ?? ""
            let group = value?["group"] as? String ?? ""
            let subGroup = value?["subgroup"] as? Int ?? 0
            
            if name != "" {
                UserDefaults.standard.set(name, forKey: "name")
                print(name)
            }
            
            if group != "" {
                UserDefaults.standard.set(group, forKey: "group")
                print(group)
                //                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateGroupParameters"), object: nil)
            }
            
            UserDefaults.standard.set(subGroup, forKey: "subGroup")
            print(subGroup)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateGroupParameters"), object: nil)
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func setUserLabels() {
        if let name = UserDefaults.standard.object(forKey: "name"),
            let text = name as? String {
            UserNameLabel.text = text
        }
        if let group = UserDefaults.standard.object(forKey: "group"),
            let text = group as? String {
            groupLabel.text = text
        }
        if let subGroup = UserDefaults.standard.object(forKey: "subGroup") {
            print("set user labels",subGroup)
            subGroupLabel.text = "\(subGroup as! Int + 1) підгрупа"
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch (section) {
        case 2:
            return "Переводити на наступний курс щороку"
        case 5:
            return "Розробка: Трушковський Олексій\nДизайн: Федюк Денис"
        default:
            return nil
        }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "UserEditor") as? UserEditorTableViewController
                self.navigationController?.pushViewController(vc!, animated: true)
            }
        }
        if indexPath.section == 3 {
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
        if indexPath.section == 4 {
            if indexPath.row == 0 {
                if let url = URL(string: "https://t.me/esen1n25") {
                    UIApplication.shared.open(url)
                }
            }
            if indexPath.row == 1 {
                SKStoreReviewController.requestReview()
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
