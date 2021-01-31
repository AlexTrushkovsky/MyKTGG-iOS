//
//  AppDelegate.swift
//  authKTGG
//
//  Created by Алексей Трушковский on 17.02.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import GoogleSignIn
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate{
    
    var window: UIWindow?
    let notificationCenter = UNUserNotificationCenter.current()
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        ApplicationDelegate.shared.application(app, open: url, options: options)
        return GIDSignIn.sharedInstance().handle(url)
    }
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        notificationCenter.delegate = self
        Messaging.messaging().delegate = self
        requestAutorization()
        application.registerForRemoteNotifications()
        return true
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
      print("Firebase registration token: \(String(describing: fcmToken))")

      let dataDict:[String: String] = ["token": fcmToken ?? ""]
      NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        NotificationCenter.default.addObserver(self, selector: #selector(showModalGroupChoose), name:NSNotification.Name(rawValue: "groupChooseVC"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showModalAuth), name:NSNotification.Name(rawValue: "showAuthVC"), object: nil)
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if user == nil{
                self.showModalAuth()
            }
        }
        UIApplication.shared.applicationIconBadgeNumber = 0
        UserDefaults(suiteName: "group.myktgg")!.set(0, forKey: "badges")
    }
    
    @objc func showModalAuth(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let newvc = storyboard.instantiateViewController(withIdentifier: "RegViewController") as! AuthViewController
        self.window?.rootViewController?.present(newvc, animated: true, completion: nil)
    }
    
   @objc func showModalGroupChoose() {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let newvc = storyboard.instantiateViewController(withIdentifier: "groupChooseVC") as! GroupChooseViewController
    self.window?.rootViewController?.present(newvc, animated: true, completion: nil)
        print("windows may be opened")
    }
    
    func requestAutorization() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            print("Permission granted: \(granted)")
            guard granted else { return }
            self.getNotificationSettings()
        }
    }
    
    func getNotificationSettings() {
        notificationCenter.getNotificationSettings { (settings) in
            print("Notification settings: \(settings)")
            
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        let token = tokenParts.joined()
        print("Device token: \(token)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register APNS")
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo : [AnyHashable: Any] = response.notification.request.content.userInfo
        if let tabBarController = self.window!.rootViewController as? UITabBarController {
            if userInfo["image_url"] as? String != nil{
                tabBarController.selectedIndex = 1
            } else {
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
                if let dateOfCell = df.date(from: response.notification.request.identifier) {
                    UserDefaults.standard.setValue(dateOfCell, forKey: "selectDate")
                }
                tabBarController.selectedIndex = 2
            }
        }
        // tell the app that we have finished processing the user’s action / response
        completionHandler()
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // Perform background operation
        print("got silent push")
        guard let title = userInfo["title"] as? String else { return }
        guard let body = userInfo["body"] as? String else { return }
        guard let dateOfchange = userInfo["date"] as? String else { return }
        var push = [String]()
        
        let sharedDefault = UserDefaults(suiteName: "group.myktgg")!
        
            if title.contains("<in>") && title.contains("</in>") {
                if let superTitle = title.components(separatedBy: "<in>").first {
                    push.append(superTitle)
                }
                push.append(body)
                if let imageName = title.components(separatedBy: "<in>").last?.components(separatedBy: "</in>").first {
                    print(title)
                    print(imageName)
                    push.append(imageName)
                } else {
                    push.append("default")
                }
            } else {
                push.append(title)
                push.append(body)
                push.append("default")
            }
            
            push.append(dateOfchange)
            
        if var arrayOfPushes = sharedDefault.object(forKey: "pushes") as? [[String]]{
            for pushItem in arrayOfPushes {
                if pushItem == push {
                    return
                }
            }
            arrayOfPushes.insert(push, at: 0)
            sharedDefault.set(arrayOfPushes, forKey: "pushes")
            scheduleNotification(title: push[0], notificationType: push[0], body: push[1], date: Date(timeIntervalSinceNow: 5))
        } else {
            sharedDefault.set([push], forKey: "pushes")
            scheduleNotification(title: push[0], notificationType: push[0], body: push[1], date: Date(timeIntervalSinceNow: 5))
        }
        completionHandler(.newData)
    }
    
    func scheduleNotification(title: String, notificationType: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if title == "Будильник" {
            content.sound = UNNotificationSound.init(named: UNNotificationSoundName(rawValue: "alarm.mp3"))
        } else {
            content.sound = .default
        }
        
        content.userInfo = ["date" : date]
        if let badgeNum = UserDefaults(suiteName: "group.myktgg")!.object(forKey: "badges") as? Int {
            content.badge = NSNumber(value: badgeNum+1)
            UserDefaults(suiteName: "group.myktgg")!.set(badgeNum+1, forKey: "badges")
        }
        let timeInterval = date.timeIntervalSinceNow
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: notificationType, content: content, trigger: trigger)
        notificationCenter.add(request) { (error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}
