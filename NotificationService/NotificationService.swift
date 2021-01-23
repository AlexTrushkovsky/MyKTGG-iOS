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
            
            func save(_ identifier: String,
                      data: Data, options: [AnyHashable: Any]?)
                -> UNNotificationAttachment? {
                    let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)
                    do {
                        try FileManager.default.createDirectory(at: directory,
                                                                withIntermediateDirectories: true,
                                                                attributes: nil)
                        let fileURL = directory.appendingPathComponent(identifier)
                        try data.write(to: fileURL, options: [])
                        return try UNNotificationAttachment.init(identifier: identifier,
                                                                 url: fileURL,
                                                                 options: options)
                    } catch {}
                    return nil
            }

            func exitGracefully(_ reason: String = "") {
                let bca    = request.content.mutableCopy()
                    as? UNMutableNotificationContent
                bca!.title = reason
                contentHandler(bca!)
            }
            
            
            
            var push = [String]()
            
            // Modify the notification content here...
            let title = bestAttemptContent.title
            if title.contains("<in>") && title.contains("</in>") {
                if let superTitle = title.components(separatedBy: "<in>").first {
                    push.append(superTitle)
                }
                push.append(bestAttemptContent.body)
                
                if let imageName = bestAttemptContent.title.components(separatedBy: "<in>").last?.components(separatedBy: "</in>").first {
                    push.append(imageName)
                } else {
                    push.append("default")
                }
            } else {
                push.append(bestAttemptContent.title)
                push.append(bestAttemptContent.body)
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
            }
            
            DispatchQueue.main.async {
                guard let content = (request.content.mutableCopy() as? UNMutableNotificationContent) else {
                    return exitGracefully()
                }
                let userInfo : [AnyHashable: Any] = request.content.userInfo
                guard let attachmentURL = userInfo["image_url"] as? String else {
                    return exitGracefully()
                }
                guard let imageData = try? Data(contentsOf: URL(string: attachmentURL)!) else {
                    return exitGracefully()
                }
                guard let attachment = save("image.png", data: imageData, options: nil) else {
                    return exitGracefully()
                }
                content.attachments = [attachment]
                contentHandler(content)
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
