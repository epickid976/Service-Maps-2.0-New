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
import MijickPopups
import Toasts

//MARK: -ORIGINAL NEW-

@main
struct Service_Maps_2_0App: App {
    
    @Environment(\.scenePhase) var scenePhase
    @StateObject var synchronizationManager = SynchronizationManager.shared
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject var universalLinksManager = UniversalLinksManager.shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var deepLink: URL?
    
    init() {
        SynchronizationManager.shared.startupProcess(synchronizing: true)
    }
    
    

    var body: some Scene {
        WindowGroup {
            
            let destination: DestinationEnum = instantiateDestination()
            
            // Remove outer NavigationStack - HomeTabView manages its own navigation
            VStack {
                switch destination {
                case .SplashScreen:
                    SplashScreenView()
                case .HomeScreen:
                    HomeTabView().installToast(position: .bottom)
                case .WelcomeScreen:
                    NavigationStack { WelcomeView() { Task { SynchronizationManager.shared.startupProcess(synchronizing: true) } } }
                case .LoginScreen:
                    NavigationStack {
                        LoginView() {
                            Task {
                                synchronizationManager.startupProcess(synchronizing: true)
                                SynchronizationManager.shared.startupProcess(synchronizing: false)
                            }
                        }
                    }
                case .AdministratorLoginScreen:
                    NavigationStack { AdminLoginView() { Task { synchronizationManager.startupProcess(synchronizing: true) } } }
                case .PhoneLoginScreen:
                    NavigationStack { PhoneLoginScreen() { Task { synchronizationManager.startupProcess(synchronizing: true) } } }
                case .ValidationScreen:
                    NavigationStack { VerificationView() { Task { synchronizationManager.startupProcess(synchronizing: true) } } }
                case .LoadingScreen:
                    LoadingView()
                case .NoDataScreen:
                    NoDataView()
                case .ActivateEmail:
                    NavigationStack { ValidationView() }
                case .RegisterKeyView:
                    NavigationStack { RegisterKeyView() }
                case .ResetPasswordView:
                    NavigationStack { ResetPassword() }
                case .PrivacyPolicyView:
                    NavigationStack { PrivacyPolicy() }
                case .loginWithEmailView:
                    NavigationStack { LoginWithEmailView() }
                }
            }.environment(\.font, Font.system(.body, design: .rounded))
                .onOpenURL { url in
                    // First: check for your custom URL scheme
                    if url.scheme == "servicemaps", url.host == "openRecalls" {
                        // Switch to Recalls tab
                        NotificationCenter.default.post(name: .openRecallsTab, object: nil)
                        return
                    }

                    // Else: fallback to universal links
                    universalLinksManager.handleIncomingURL(url)
                }
            .animation(.easeIn(duration: 0.25), value: destination)
            .animation(.easeIn(duration: 0.25), value: synchronizationManager.startupState)
            .navigationTransition(
                .fade(.in)
            )
            .installToast(position: .bottom)
            .onAppear {
                Task {
                    do {
                        try await NotificationManager.shared.requestPermission()
                    } catch {
                        print("Error receiving Notification Permission")
                    }
                }
            }
            
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Task.detached {
                    if await isMoreThanFiveMinutesOld(date: StorageManager.shared.lastTime) {
                        Task {
                            await synchronizationManager
                                .startupProcess(synchronizing: true)
                        }
                    }
                    Task {
                        do {
                            // Always reinitialize connection when admin status changes
                            try await RealtimeManager.shared.initAblyConnection()
                            print("Ably connection initialized")
                            
                            // Subscribe to changes
                            await RealtimeManager.shared.subscribeToChanges { result in
                                switch result {
                                case .success:
                                    print("Subscribed to changes")
                                case .failure(let error):
                                    print("Error: \(error)")
                                }
                            }
                        } catch {
                            print("Error: \(error)")
                        }
                    }
                }
            } else if newPhase == .background {
                Task {
                    await RealtimeManager.shared.unsubscribeToChanges()
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


extension Notification.Name {
    static let openRecallsTab = Notification.Name("openRecallsTab")
}
