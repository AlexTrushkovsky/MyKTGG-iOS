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
      // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app strtup and whenever a new token is generated.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        NotificationCenter.default.addObserver(self, selector: #selector(showModalGroupChoose), name:NSNotification.Name(rawValue: "groupChooseVC"), object: nil)
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if user == nil{
                self.showModalAuth()
            }
        }
        UIApplication.shared.applicationIconBadgeNumber = 0
        UserDefaults(suiteName: "group.myktgg")!.set(0, forKey: "badges")
    }
    
    func showModalAuth(){
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
    
    func scheduleNotification(notificationType: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = notificationType
        content.body = body
        content.sound = .default
        content.badge = 1
        let timeInterval = date.timeIntervalSinceNow
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let identifier = "Change Notification"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
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
