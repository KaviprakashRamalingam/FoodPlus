//
//  NotificationManager.swift
//  FoodPlus
//
//  Created by Kaviprakash Ramalingam on 12/12/24.
//

import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}

    // Request notification permissions
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error.localizedDescription)")
            } else {
                print(granted ? "Notification permissions granted" : "Notification permissions denied")
            }
        }
    }

    // Trigger a local notification
    func triggerNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immediate delivery
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }
}
