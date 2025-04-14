//
//  NotificationManager.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 1/20/25.
//

import UserNotifications
import SwiftData

@MainActor
class NotificationManager {
    static let shared = NotificationManager()

    /// Request notification permission
    func requestPermission() async throws {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        if !granted {
            throw NSError(domain: "NotificationPermission", code: 1, userInfo: [NSLocalizedDescriptionKey: "Notification permission not granted."])
        }
    }

    /// Schedule a notification
    func scheduleNotification(id: String, title: String, body: String, date: Date, deepLink: String? = nil) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        if let deepLink = deepLink {
            content.userInfo = ["url": deepLink] // 👈 Add deep link
        }

        var dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        dateComponents.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Scheduled: \(id)")
        } catch {
            print("❌ Error scheduling notification: \(error.localizedDescription)")
        }
    }

    /// Remove a scheduled notification
    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// Remove all notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
