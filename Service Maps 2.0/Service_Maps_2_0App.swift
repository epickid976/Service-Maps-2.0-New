//
//  Service_Maps_2_0App.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/27/23.
//

import SwiftUI

@main
struct Service_Maps_2_0App: App {
    let dataController = DataController.shared
    @Environment(\.scenePhase) var scenePhase
    @StateObject var authorizationProvider = AuthorizationProvider()
    
    var body: some Scene {
        WindowGroup {
            if authorizationProvider.authorizationToken != nil {
                HomeTabView()
                    .environment(\.managedObjectContext, DataController.preview.container.viewContext)
            } else {
                WelcomeView()
                    .environment(\.managedObjectContext, DataController.preview.container.viewContext)
            }
        }
        .onChange(of: scenePhase) { _ in
            dataController.save()
        }
    }
    
    
}
