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

        let config = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    migration.enumerateObjects(ofType: TokenTerritoryObject.className()) { oldObject, newObject in
                        newObject!["_id"] = "\(oldObject!["token"]!):\(oldObject!["territory"]!)"
                    }
                }
            }
        )
        Realm.Configuration.defaultConfiguration = config

        return true
    }
}
