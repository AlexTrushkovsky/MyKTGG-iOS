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
    var budyaMode = false
    var budyaOpened = false
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(setUserLabels), name: NSNotification.Name(rawValue: "setUserLabels"), object: nil)
        let tap = UITapGestureRecognizer(target: self, action: #selector(budyaTapped))
        tap.numberOfTapsRequired = 13
        view.addGestureRecognizer(tap)
    }
    
    @objc func reloadView() {
        viewDidLoad()
    }
    
    @objc func budyaTapped() {
        self.budyaMode = true
        tableView.reloadData()

    }
    
    @objc func updateAvatar() {
        let avatarMethods = AvatarMethods()
        avatarMethods.getAvatarFromUserDefaults(forKey: "avatar", imageView: avatar)
    }
    @objc func updateLabels() {
        print("updating user labels...")
        getUserInfo()
    }
    
    func clearUserDefaults() {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
        do{
            try Auth.auth().signOut()
        }catch{
            print(error)
        }
    }
    
    func showClearUserDefaultsAlert(){
        let alert = UIAlertController(title: "Скинути налаштування", message: "Ви впевнені, що ви бажаєте скинути налаштування?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Так", style: .destructive, handler: {(action: UIAlertAction!) in self.clearUserDefaults()}))
        alert.addAction(UIAlertAction(title: "Відмінити", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
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
                print("getUserDefaults name:",name)
            }
            
            if group != "" {
                UserDefaults.standard.set(group, forKey: "group")
                print("getUserDefaults group:",group)
            }
            
            UserDefaults.standard.set(subGroup, forKey: "subGroup")
            print("getUserDefaults subGroup:",subGroup)
            NotificationCenter.default.post(name: NSNotification.Name("setUserLabels"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateGroupParameters"), object: nil)
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    @objc func setUserLabels() {
        if let name = UserDefaults.standard.object(forKey: "name"),
            let text = name as? String {
            UserNameLabel.text = text
            print("new name:", name)
        }
        if let group = UserDefaults.standard.object(forKey: "group"),
            let text = group as? String {
            groupLabel.text = text
            print("new group:", group)
        }
        if let subGroup = UserDefaults.standard.object(forKey: "subGroup") {
            subGroupLabel.text = "\(subGroup as! Int + 1) підгрупа"
        }
    }
    private func budyaShouldBeHidden(_ section: Int) -> Bool {
        if self.budyaMode {
            switch section {
            case 6: return false
            default: return false
            }
        } else {
            switch section {
            case 6: return true
            default: return false
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 6 {
            if budyaShouldBeHidden(section) {
                return 0 // Don't show any rows for hidden sections
            } else {
                if budyaOpened {
                    return super.tableView(tableView, numberOfRowsInSection: section) // Use the default number of rows for other sections
                } else {
                    return 1
                }
            }
        } else {
            return super.tableView(tableView, numberOfRowsInSection: section) // Use the default number of rows for other sections
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
        if indexPath.section == 6 {
            if indexPath.row == 0 {
                budyaOpened = !budyaOpened
                tableView.reloadData()
            }
            if indexPath.row == 1 {
                showClearUserDefaultsAlert()
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
