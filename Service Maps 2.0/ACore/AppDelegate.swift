//
//  AppDelegate.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/24/24.
//

import Foundation
import UIKit
import SwiftUI
import Combine
import MijickPopups

class AppDelegate: NSObject, UIApplicationDelegate{
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = CustomPopupSceneDelegate.self
        return sceneConfig
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle servicemaps://openRecalls
        if url.scheme == "servicemaps", url.host == "openRecalls" {
            NotificationCenter.default.post(name: .openRecallsTab, object: nil)
            print("Open Recalls Tab")
            return true
        }
        
        // Fallback for universal links or other handlers
        return false
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
            UNUserNotificationCenter.current().delegate = self
            return true
        }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let urlString = response.notification.request.content.userInfo["url"] as? String,
           let url = URL(string: urlString) {
            DispatchQueue.main.async {
                UIApplication.shared.open(url)
            }
        }

        // ✅ Tell the system you’re done
        completionHandler()
    }
}

class CustomPopupSceneDelegate: PopupSceneDelegate {
   override init() { super.init()
       configBuilder = { $0
           .vertical { $0
               .tapOutsideToDismissPopup(false)
               .enableDragGesture(false)
               
           }
           .centre { $0
               .tapOutsideToDismissPopup(false)
               .backgroundColor(Color(UIColor.systemGray6).opacity(85))
               .cornerRadius(20)
           }
       }
   }
}

extension PopupManagerID {
    static func unique() -> PopupManagerID {
        return PopupManagerID(rawValue: UUID().uuidString) // Generate a unique ID
    }
}
