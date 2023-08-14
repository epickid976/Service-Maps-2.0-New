//
//  Service_Maps_2_0App.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/27/23.
//

import SwiftUI
import NavigationTransitions

@main
struct Service_Maps_2_0App: App {
    let dataController = DataController.shared
    
    @Environment(\.scenePhase) var scenePhase
    @StateObject var synchronizationManager = SynchronizationManager.shared
    
//        init() {
//    
//            if(StorageManager.shared.synchronized){
//                synchronizationManager.startupProcess()
//            }
//        }
    
    var body: some Scene {
        WindowGroup {
            let synchronizationManagerStartupState = synchronizationManager.startupState
            
            NavigationStack {
                
                switch synchronizationManagerStartupState {
                case .Unknown:
                    SplashScreenView()
                case .Welcome:
                    WelcomeView() {
                        synchronizationManager.startupProcess(synchronizing: true)
                    }
                case .Login:
                    LoginView() {
                        synchronizationManager.startupProcess(synchronizing: true)
                    }
                case .AdminLogin:
                    AdminLoginView() {
                        synchronizationManager.startupProcess(synchronizing: true)
                    }
                case .Validate:
                    VerificationView() {
                        synchronizationManager.startupProcess(synchronizing: true)
                    }
                case .Loading:
                    LoadingView()
                case .Ready:
                    HomeTabView()
                        .environment(\.managedObjectContext, DataController.preview.container.viewContext)
                case .Empty:
                    NoDataView()
                }
            }
            .animation(.easeInOut(duration: 0.25), value: synchronizationManagerStartupState)
            .navigationTransition(
                .slide.combined(with: .fade(.in))
            )
            
            
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                synchronizationManager.startupProcess(synchronizing: true)
            }
            dataController.save()
        }
    }
}
