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
class AppDelegate: UIResponder, UIApplicationDelegate{
    
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
        requestAutorization()
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if user == nil{
                self.showModalAuth()
            }
        }
    }
    
    func showModalAuth(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let newvc = storyboard.instantiateViewController(withIdentifier: "RegViewController") as! AuthViewController
        self.window?.rootViewController?.present(newvc, animated: true, completion: nil)
    }
//    func showModalGroupChoose(){
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let newvc = storyboard.instantiateViewController(withIdentifier: "GroupChooseViewController") as! GroupChooseViewController
//        self.window?.rootViewController?.present(newvc, animated: true, completion: nil)
//    }
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
        }
    }
    func scheduleNotification(notificationType: String) {
        let content = UNMutableNotificationContent()
        content.title = notificationType
        content.body = "Заміна: Математика 1 пара"+notificationType
        content.sound = .default
        content.badge = 1
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let identifier = "Local Notification"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        notificationCenter.add(request) { (error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}

