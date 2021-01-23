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
    var group = [String]()
    var currentGroup = String()
    let avatarMethods = AvatarMethods()
    var isStudent = true
    var isVerified = false
    var isNotificationsAllowed = false

    @IBOutlet weak var newsSwitch: UISwitch!
    @IBOutlet weak var changesSwitch: UISwitch!
    @IBOutlet weak var verifiedImage: UIImageView!
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var avatarContainer: UIView!
    @IBOutlet weak var groupLabel: UILabel!
    @IBOutlet weak var subGroupLabel: UILabel!
    @IBOutlet weak var UserNameLabel: UILabel!
    @IBOutlet weak var userEditActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var userEditArrow: UIImageView!
    @IBOutlet weak var turnNotificationButton: UIButton!
    @IBAction func changeNotificationSettings(_ sender: UIButton) {
        if let appSettings = NSURL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings as URL, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func changesSwitch(_ sender: UISwitch) {
        let group = transliterate(nonLatin: self.currentGroup)
        if sender.isOn {
            Messaging.messaging().subscribe(toTopic: "/topics/changesOf\(group)") { error in
                print("Subscribed to \(group) changes")
                UserDefaults.standard.set(group,forKey: "groupOfChangeSubscription")
            }
        } else {
            Messaging.messaging().unsubscribe(fromTopic: "/topics/changesOf\(group)") { error in
                print("Unsubscribed from \(group) changes")
                UserDefaults.standard.set(nil,forKey: "groupOfChangeSubscription")
            }
        }
    }
    @IBAction func newsSwitch(_ sender: UISwitch) {
        if sender.isOn {
            Messaging.messaging().subscribe(toTopic: "news") { error in
                print("Subscribed to news")
                UserDefaults.standard.set(true,forKey: "isSubscribedForNews")
            }
        } else {
            Messaging.messaging().unsubscribe(fromTopic: "news") { error in
                print("Unsubscribed from news")
                UserDefaults.standard.set(false,forKey: "isSubscribedForNews")
            }
        }
    }
    
    func checkNewsSubscription() {
        guard let isSubscribedForNews =  UserDefaults.standard.object(forKey: "isSubscribedForNews") as? Bool else { return }
        if isSubscribedForNews {
            newsSwitch.isOn = true
        } else {
            newsSwitch.isOn = false
        }
    }
    
    func checkChangesSubscription() {
        if let changesGroup = UserDefaults.standard.object(forKey: "groupOfChangeSubscription") as? String {
            print("user is already subscribed to \(changesGroup)")
            changesSwitch.isOn = true
        } else {
            changesSwitch.isOn = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
        userEditActivityIndicator.hidesWhenStopped = true
        if #available(iOS 13, *) {
            userEditActivityIndicator.style = .medium
        } else {
            userEditActivityIndicator.style = .gray
        }
        checkNotificationSettings()
        avatarMethods.setupUserImageView(avatarContainer: avatarContainer, imageView: avatar)
        setUserLabels()
        getUserInfo()
        getCurrentUserType()
        updateAvatar()
        checkNewsSubscription()
        checkChangesSubscription()
        UserDefaults.standard.addObserver(self, forKeyPath: "group", options: NSKeyValueObservingOptions.new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "name", options: NSKeyValueObservingOptions.new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "subGroup", options: NSKeyValueObservingOptions.new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "isStudent", options: NSKeyValueObservingOptions.new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "verified", options: NSKeyValueObservingOptions.new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "groupOfChangeSubscription", options: NSKeyValueObservingOptions.new, context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateAvatar), name:NSNotification.Name(rawValue: "updateAvatar"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getUserInfo), name:NSNotification.Name(rawValue: "updateLabels"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(checkNotificationStatus), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "group" {
            setGroupLabelfromDefaults()
        } else if keyPath == "name" {
            setNameLabelFromDefaults()
        } else if keyPath == "subGroup"{
            setSubGroupLabelFromUserDefaults()
        }else if keyPath == "isStudent" {
            getCurrentUserType()
        }else if keyPath == "verified" {
            getCurrentUserType()
        }else if keyPath == "groupOfChangeSubscription" {
            checkChangesSubscription()
        }
    }
    
    func setUserLabels() {
        setNameLabelFromDefaults()
        setGroupLabelfromDefaults()
        setSubGroupLabelFromUserDefaults()
        getCurrentUserType()
    }
    
    func checkNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            DispatchQueue.main.sync {
                if settings.authorizationStatus == .authorized {
                    self.isNotificationsAllowed = true
                    self.turnNotificationButton.setTitle("Вимкнути сповіщення", for: .normal)
                    self.turnNotificationButton.backgroundColor = UIColor(red: 0.91, green: 0.96, blue: 0.94, alpha: 1.00)
                    self.turnNotificationButton.setTitleColor(UIColor(red: 0.30, green: 0.77, blue: 0.57, alpha: 1.00), for: .normal)
                    self.turnNotificationButton.isHidden = false
                } else {
                    self.isNotificationsAllowed = false
                    self.turnNotificationButton.setTitle("Увімкнути сповіщення", for: .normal)
                    self.turnNotificationButton.backgroundColor = UIColor(red: 0.96, green: 0.91, blue: 0.91, alpha: 1.00)
                    self.turnNotificationButton.setTitleColor(UIColor(red: 0.77, green: 0.30, blue: 0.30, alpha: 1.00), for: .normal)
                    self.turnNotificationButton.isHidden = false
                }
                UIView.transition(with: self.tableView, duration: 0.3, options: .transitionCrossDissolve, animations: {self.tableView.reloadData()}, completion: nil)
            }
        }
    }
    
    @objc private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            switch settings.authorizationStatus {
            case .authorized, .denied, .provisional, .notDetermined,  .ephemeral:
                self.checkNotificationSettings()
            @unknown default:
                self.checkNotificationSettings()
            }
        }
    }
    
    @objc func getCurrentUserType() {
        guard let isStudent = UserDefaults.standard.object(forKey: "isStudent") as? Bool else { return }
        self.isStudent = isStudent
        if !isStudent{
            subGroupLabel.text = "Викладач"
            if let verified = UserDefaults.standard.object(forKey: "verified") as? String{
                guard let group =  UserDefaults.standard.object(forKey: "group") as? String else {
                    return
                }
                print("verified account of: \(verified)")
                if verified == group {
                    self.isVerified = true
                    self.verifiedImage.image = UIImage(named: "checkmark.shield")
                    self.verifiedImage.isHidden = false
                    self.verifiedImage.tintColor = UIColor(red: 0.28, green: 0.78, blue: 0.56, alpha: 1.00)
                } else {
                    self.isVerified = false
                    self.verifiedImage.image = UIImage(named: "shield.slash")
                    self.verifiedImage.tintColor = UIColor(red: 0.78, green: 0.28, blue: 0.28, alpha: 1.00)
                    self.verifiedImage.isHidden = false
                }
            } else {
                self.isVerified = false
                self.verifiedImage.image = UIImage(named: "shield.slash")
                self.verifiedImage.tintColor = UIColor(red: 0.78, green: 0.28, blue: 0.28, alpha: 1.00)
                self.verifiedImage.isHidden = false
            }
        } else {
            self.verifiedImage.isHidden = true
            setSubGroupLabelFromUserDefaults()
        }
        UIView.transition(with: tableView, duration: 0.3, options: .transitionCrossDissolve, animations: {self.tableView.reloadData()}, completion: nil)
    }
    
    func setGroupLabelfromDefaults() {
        if let group = UserDefaults.standard.object(forKey: "group"),
           let text = group as? String {
            groupLabel.text = text
            print("Defaults group:", group)
            self.currentGroup = text
            getCurrentUserType()
        }
    }
    
    func setNameLabelFromDefaults() {
        if let name = UserDefaults.standard.object(forKey: "name"),
           let text = name as? String {
            UserNameLabel.text = text
            print("Defaults name:", name)
        }
    }
    
    func setSubGroupLabelFromUserDefaults() {
        if let subGroup = UserDefaults.standard.object(forKey: "subGroup") {
            subGroupLabel.text = "\(subGroup as! Int + 1) підгрупа"
            print("Defaults subgroup: \(subGroup as! Int + 1)")
        }
    }
    
    @objc func updateAvatar() {
        avatarMethods.getAvatarFromUserDefaults(forKey: "avatar", imageView: avatar)
    }
    
    func showAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК",style: .default))
        present(alert, animated: true, completion: nil)
    }
    
    @objc func getUserInfo(){
        print("Updating user info...")
        let userID = Auth.auth().currentUser?.uid
        let db = Database.database().reference()
        db.child("users").child(userID!).child("public").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            
            if let name = value?["name"] as? String {
                UserDefaults.standard.set(name, forKey: "name")
                print("getUserDefaults name:",name)
            }
            
            if let group = value?["group"] as? String {
                UserDefaults.standard.set(group, forKey: "group")
                print("getUserDefaults group:",group)
                let transliterated = self.transliterate(nonLatin: group)
                Messaging.messaging().subscribe(toTopic: transliterated) { error in
                    print("Subscribed to \(transliterated) pushes")
                    UserDefaults.standard.set(transliterated,forKey: "subsctibedTopic")
                }
            }
            
            if let subGroup = value?["subgroup"] as? Int {
                UserDefaults.standard.set(subGroup, forKey: "subGroup")
                print("getUserDefaults subGroup:",subGroup)
            }
            
            if let isStudent = value?["isStudent"] as? Bool {
                UserDefaults.standard.set(isStudent, forKey: "isStudent")
            }
        }) { (error) in
            print(error.localizedDescription)
        }
        
        db.child("users").child(userID!).child("secure").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            if let verified = value?["verified"] as? String {
                print("verified account of: \(verified)")
                UserDefaults.standard.set(verified, forKey: "verified")
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func transliterate(nonLatin: String) -> String {
        return nonLatin
            .applyingTransform(.toLatin, reverse: false)?
            .applyingTransform(.stripDiacritics, reverse: false)?
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "ʹ", with: "") ?? nonLatin
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if isStudent {
                return 0
            } else {
                if isVerified {
                    return 0
                } else {
                    return super.tableView(tableView, numberOfRowsInSection: section)
                }
            }
        }
        if section == 2 {
            if self.isNotificationsAllowed {
                return super.tableView(tableView, numberOfRowsInSection: section)
            } else {
                return 1
            }
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            if isStudent {
                return nil
            } else {
                if isVerified {
                    return nil
                } else {
                    return super.tableView(tableView, titleForHeaderInSection: section)
                }
            }
        }
        return super.tableView(tableView, titleForHeaderInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                userEditActivityIndicator.startAnimating()
                let cell = super.tableView.cellForRow(at: indexPath)
                cell?.isUserInteractionEnabled = false
                userEditArrow.isHidden = true
                DispatchQueue.global().async {
                    let groupCheck = GroupNetworkController()
                    self.group = groupCheck.fetchData(isStudent: self.isStudent)
                    DispatchQueue.main.async {
                        if self.group.isEmpty {
                            //throw error
                            self.showAlert(title: "Помилка", message: "Немає зв'язку з мережею. \n Перевірте з`єднання або спробуйте пізніше.")
                            self.userEditActivityIndicator.stopAnimating()
                            cell?.isUserInteractionEnabled = true
                            self.userEditArrow.isHidden = false
                        } else {
                            let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "UserEditor") as? UserEditorTableViewController
                            vc?.group = self.group
                            vc?.isStudent = self.isStudent
                            self.navigationController?.pushViewController(vc!, animated: true)
                            self.userEditActivityIndicator.stopAnimating()
                            cell?.isUserInteractionEnabled = true
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
        if indexPath.section == 5 {
            if indexPath.row == 0 {
                if let url = URL(string: "https://t.me/esen1n25") {
                    UIApplication.shared.open(url)
                }
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
