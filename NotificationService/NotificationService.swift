//
//  NotificationService.swift
//  NotificationService
//
//  Created by Алексей Трушковский on 02.01.2021.
//  Copyright © 2021 Алексей Трушковский. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            var push = [String]()
            
            // Modify the notification content here...
            let title = bestAttemptContent.title
            if let superTitle = title.components(separatedBy: "<in>").first {
                push.append(superTitle)
            }
            push.append(bestAttemptContent.body)
            
            if let imageName = bestAttemptContent.title.components(separatedBy: "<in>").last?.components(separatedBy: "</in>").first {
                push.append(imageName)
            } else {
                push.append("default")
            }
            
            let sharedDefault = UserDefaults(suiteName: "group.myktgg")!
            if var arrayOfPushes = sharedDefault.object(forKey: "pushes") as? [[String]]{
                arrayOfPushes.insert(push, at: 0)
                sharedDefault.set(arrayOfPushes, forKey: "pushes")
            } else {
                sharedDefault.set([push], forKey: "pushes")
            }
            
            if let title = title.components(separatedBy: "<in>").first {
                bestAttemptContent.title = title
                if let badgeNum = UserDefaults(suiteName: "group.myktgg")!.object(forKey: "badges") as? Int {
                    bestAttemptContent.badge = NSNumber(value: badgeNum+1)
                    UserDefaults(suiteName: "group.myktgg")!.set(badgeNum+1, forKey: "badges")
                }
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
}
