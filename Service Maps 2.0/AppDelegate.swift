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

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = CustomPopupSceneDelegate.self
        return sceneConfig
    }
}

class CustomPopupSceneDelegate: PopupSceneDelegate {
   override init() { super.init()
       configBuilder = { $0
           
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
