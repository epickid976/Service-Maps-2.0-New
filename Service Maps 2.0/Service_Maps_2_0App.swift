//
//  Service_Maps_2_0App.swift
//  Service Maps 2.0   
//
//  Created by Jose Blanco on 7/27/23.
//

import SwiftUI
import NavigationTransitions
import BackgroundTasks

@main
struct Service_Maps_2_0App: App {
    //let databaseManager = RealmManager.shared
    //let cdPublisher = CDPublisher.shared
    
    @Environment(\.scenePhase) var scenePhase
    @StateObject var synchronizationManager = SynchronizationManager.shared
    @StateObject var territoryViewModel = TerritoryViewModel()
    
    init() {
//        BGTaskScheduler.shared.register(forTaskWithIdentifier: "￼com.serviceMaps.uploadPendingTasks", using: nil) { task in
//            ReuploaderWorker.shared.handleReupload(task: task as! BGProcessingTask)
//        }
        
        
    }
    
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
                        //.environmentObject(territoryViewModel)
                case .Empty:
                    NoDataView()
                }
            }
            .animation(.easeIn(duration: 0.25), value: synchronizationManager.startupState)
            .navigationTransition(
                .slide.combined(with: .fade(.in))
            )
            
            
        }
        
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                synchronizationManager.startupProcess(synchronizing: true)
            }
            //dataController.save()
        }
    }
}
