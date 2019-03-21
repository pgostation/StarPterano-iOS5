//
//  PushNotificationSettings.swift
//  DonParade
//
//  Created by takayoshi on 2019/03/21.
//  Copyright © 2019 pgostation. All rights reserved.
//

import UIKit
import UserNotifications
import FirebaseMessaging

final class PushNotificationSettings {
    static func auth() {
        let application = UIApplication.shared
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.badge, .sound, .alert],
                completionHandler: { (granted: Bool, error: Swift.Error?) in
                    if let _ = error { return }
                    if granted == false { return }
                    
                    DispatchQueue.main.async {
                        application.registerForRemoteNotifications()
                    }
            })
        } else {
            let settings = UIUserNotificationSettings(
                types: [.alert, .badge, .sound],
                categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
    }
}

extension AppDelegate {
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        application.registerForRemoteNotifications()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        //let iosToken = deviceToken.map { String(format: "%.2hhx", $0) }.joined()
        
        sendFcmToken(isRetry: false)
    }
    
    private func sendFcmToken(isRetry: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Firebase Cloud Messaging用のトークンを取得する
            if let fcmToken = Messaging.messaging().fcmToken {
                TootViewController.toot(text: "StarPterano Push Notification Device Token:\n" + fcmToken, spoilerText: nil, nsfw: false, visibility: "direct", addJson: [:], view: nil)
            } else if !isRetry {
                self.sendFcmToken(isRetry: true)
            } else {
                Dialog.show(message: "Error: Can't get token.")
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        DispatchQueue.main.async {
            print("プッシュ通知登録エラー")
        }
    }
}
