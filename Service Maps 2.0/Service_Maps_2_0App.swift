//
//  Service_Maps_2_0App.swift
//  Service Maps 2.0   
//
//  Created by Jose Blanco on 7/27/23.
//

import SwiftUI
import NavigationTransitions
import BackgroundTasks
import Nuke
import MijickPopupView

@main
struct Service_Maps_2_0App: App {
    
    @Environment(\.scenePhase) var scenePhase
    @StateObject var synchronizationManager = SynchronizationManager.shared
    @StateObject var territoryViewModel = TerritoryViewModel()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject var universalLinksManager = UniversalLinksManager.shared
    
    init() {
        
        //        BGTaskScheduler.shared.register(forTaskWithIdentifier: "￼com.serviceMaps.uploadPendingTasks", using: nil) { task in
        //            ReuploaderWorker.shared.handleReupload(task: task as! BGProcessingTask)
        //        }
    }
    
    var body: some Scene {
        WindowGroup {
            
            var destination: DestinationEnum = instantiateDestination()
            
            
            GeometryReader { proxy in
                NavigationStack {
                    switch destination {
                    case .SplashScreen:
                        SplashScreenView()
                    case .HomeScreen:
                        HomeTabView().implementPopupView()
                            .environment(\.mainWindowSize, proxy.size)
                    case .WelcomeScreen:
                        WelcomeView() {
                            synchronizationManager.startupProcess(synchronizing: true)
                        }
                    case .LoginScreen:
                        LoginView() {
                            synchronizationManager.startupProcess(synchronizing: true)
                        }
                    case .AdministratorLoginScreen:
                        AdminLoginView() {
                            synchronizationManager.startupProcess(synchronizing: true)
                        }
                        
                    case .PhoneLoginScreen:
                        PhoneLoginScreen() {
                            synchronizationManager.startupProcess(synchronizing: true)
                        }
                        
                    case .ValidationScreen:
                        VerificationView() {
                            synchronizationManager.startupProcess(synchronizing: true)
                        }
                    case .LoadingScreen:
                        LoadingView()
                    case .NoDataScreen:
                        NoDataView()
                    case .ActivateEmail:
                        //TO DO ADD VIEWs
                        ValidationView()
                    case .RegisterKeyView:
                        RegisterKeyView()
                        
                    case .ResetPasswordView:
                        ResetPassword()
                        
                    case .PrivacyPolicyView:
                        PrivacyPolicy()
                        
                    }
                }
                .onOpenURL(perform: { url in
                    universalLinksManager.handleIncomingURL(url)
                })
                .animation(.easeIn(duration: 0.25), value: synchronizationManager.startupState)
                .navigationTransition(
                    .slide.combined(with: .fade(.in))
                )
            }
            
            
        }
        
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                if isMoreThanAMinuteOld(date: StorageManager.shared.lastTime) {
                    synchronizationManager.startupProcess(synchronizing: true)
                }
            }
        }
    }
    
    func instantiateDestination() -> DestinationEnum {
        
        var destination: DestinationEnum = .SplashScreen
        let resultDestination = universalLinksManager.determineDestination()
        
        switch synchronizationManager.startupState {
        case .Unknown:
            destination = .SplashScreen
        case .Welcome:
            if resultDestination != .RegisterKeyView {
                destination = resultDestination ?? .WelcomeScreen
            } else {
                destination = .WelcomeScreen
            }
        case .Login:
            destination = .LoginScreen
        case .AdminLogin:
            destination = .AdministratorLoginScreen
        case .PhoneLogin:
            destination = .PhoneLoginScreen
        case .Validate:
            if resultDestination != .RegisterKeyView {
                destination = resultDestination ?? .ValidationScreen
            } else {
                destination = .ValidationScreen
            }
        case .Loading:
            destination = .LoadingScreen
        case .Empty:
            destination = resultDestination ?? .NoDataScreen
        case .Ready:
            destination = resultDestination ?? .HomeScreen
        }
        
        return destination
        
    }
    
    
}
