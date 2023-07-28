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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
        }
        .onChange(of: scenePhase) { _ in
            dataController.save()
        }
    }
    
    
}
