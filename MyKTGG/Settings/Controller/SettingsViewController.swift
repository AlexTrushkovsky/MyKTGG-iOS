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
    var group = [String]()
    var currentGroup = String()
    
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
    @IBOutlet weak var userEditActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var userEditArrow: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
        userEditActivityIndicator.hidesWhenStopped = true
        let avatarMethods = AvatarMethods()
        avatarMethods.setupUserImageView(imageView: avatar)
        setUserLabels()
        getUserInfo()
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
    
    func showAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК",style: .default))
        present(alert, animated: true, completion: nil)
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
                self.postAboutGroupChangeIfNeeded(group: group)
                print("getUserDefaults group:",group)
                let transliterated = self.transliterate(nonLatin: group)
                Messaging.messaging().subscribe(toTopic: transliterated) { error in
                    print("Subscribed to \(transliterated) pushes")
                }
            }
            
            UserDefaults.standard.set(subGroup, forKey: "subGroup")
            print("getUserDefaults subGroup:",subGroup)
            NotificationCenter.default.post(name: NSNotification.Name("setUserLabels"), object: nil)
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func transliterate(nonLatin: String) -> String {
        return nonLatin
            .applyingTransform(.toLatin, reverse: false)?
            .applyingTransform(.stripDiacritics, reverse: false)?
            .lowercased()
            .replacingOccurrences(of: " ", with: "") ?? nonLatin
    }
    
    func postAboutGroupChangeIfNeeded(group: String) {
        if self.currentGroup != group {
            NotificationCenter.default.post(name: NSNotification.Name("groupChanged"), object: nil)
        }
    }
    
    @objc func setUserLabels() {
        if let name = UserDefaults.standard.object(forKey: "name"),
           let text = name as? String {
            UserNameLabel.text = text
            print("Defaults name:", name)
        }
        if let group = UserDefaults.standard.object(forKey: "group"),
           let text = group as? String {
            groupLabel.text = text
            print("Defaults group:", group)
            self.currentGroup = text
        }
        if let subGroup = UserDefaults.standard.object(forKey: "subGroup") {
            subGroupLabel.text = "\(subGroup as! Int + 1) підгрупа"
            print("Defaults subgroup: \(subGroup as! Int + 1)")
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
                userEditActivityIndicator.startAnimating()
                userEditArrow.isHidden = true
                DispatchQueue.global().async {
                    let groupCheck = GroupNetworkController()
                    self.group = groupCheck.fetchData()
                    DispatchQueue.main.async {
                        if self.group.isEmpty {
                            //throw error
                            self.showAlert(title: "Помилка", message: "Немає зв'язку з мережею. \n Перевірте з`єднання або спробуйте пізніше.")
                            self.userEditActivityIndicator.stopAnimating()
                            self.userEditArrow.isHidden = false
                        } else {
                            let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "UserEditor") as? UserEditorTableViewController
                            vc?.group = self.group
                            self.navigationController?.pushViewController(vc!, animated: true)
                            self.userEditActivityIndicator.stopAnimating()
                            self.userEditArrow.isHidden = false
                        }
                    }
                }
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
