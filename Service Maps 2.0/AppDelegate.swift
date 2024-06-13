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
import RealmSwift


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        func migrationVersion() {
            let config = Realm.Configuration(
                schemaVersion: 6) { migration, oldSchemaVersion in
                    
                    if oldSchemaVersion < 5 {
                        migration.enumerateObjects(ofType: TokenTerritoryObject.className()) { oldObject, newObject in
                            newObject!["_id"] = ObjectId.generate()
                        }
                    }
                    
                    if oldSchemaVersion < 6 {
                        migration.enumerateObjects(ofType: UserTokenObject.className()) { oldObject, newObject in
                            newObject!["blocked"] = false
                        }
                    }
                }
            Realm.Configuration.defaultConfiguration = config
        }
        
        migrationVersion()
        return true
    }
}
