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
            
            func save(_ identifier: String, data: Data, options: [AnyHashable: Any]?) -> UNNotificationAttachment? {
                let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)
                do {
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
                    let fileURL = directory.appendingPathComponent(identifier)
                    try data.write(to: fileURL, options: [])
                    return try UNNotificationAttachment.init(identifier: identifier, url: fileURL, options: options)
                } catch {}
                return nil
            }
            
            var push = [String]()
            
            push.append(bestAttemptContent.title)
            push.append(bestAttemptContent.body)
            
            let userInfo : [AnyHashable: Any] = request.content.userInfo
            if let attachmentURL = userInfo["image_url"] as? String {
                if let imageData = try? Data(contentsOf: URL(string: attachmentURL)!) {
                    if let attachment = save("image.png", data: imageData, options: nil) {
                        bestAttemptContent.attachments = [attachment]
                    }
                }
            }
            if let icon = userInfo["icon"] as? String {
                push.append(icon)
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
            
            if let badgeNum = UserDefaults(suiteName: "group.myktgg")!.object(forKey: "badges") as? Int {
                bestAttemptContent.badge = NSNumber(value: badgeNum+1)
                UserDefaults(suiteName: "group.myktgg")!.set(badgeNum+1, forKey: "badges")
            }
            
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
}
