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

//ORIGINAL NEW

@main
struct Service_Maps_2_0App: App {
    
    @Environment(\.scenePhase) var scenePhase
    @StateObject var synchronizationManager = SynchronizationManager.shared
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject var universalLinksManager = UniversalLinksManager.shared
    @StateObject var realtimeManager = RealtimeManager.shared
    
    @StateObject private var navigationHistoryManager = NavigationHistoryManager()
    
    @Environment(\.presentationMode) var presentationMode
    
    init() {
        SynchronizationManager.shared.startupProcess(synchronizing: true)
    }
    
    

    var body: some Scene {
        WindowGroup {
            
            var destination: DestinationEnum = instantiateDestination()
            
            
            //GeometryReader { proxy in
            NavigationStack {
                switch destination {
                case .SplashScreen:
                    SplashScreenView()
                case .HomeScreen:
                    HomeTabView().implementPopupView()
                case .WelcomeScreen:
                    WelcomeView() {
                        DispatchQueue.main.async {
                            synchronizationManager.startupProcess(synchronizing: true)
                            synchronizationManager.startupProcess(synchronizing: true)
                        }
                    }
                case .LoginScreen:
                    LoginView() {
                        DispatchQueue.main.async {
                            synchronizationManager.startupProcess(synchronizing: true)
                        }
                    }
                case .AdministratorLoginScreen:
                    AdminLoginView() {
                        DispatchQueue.main.async {
                            synchronizationManager.startupProcess(synchronizing: true)
                        }
                    }
                case .PhoneLoginScreen:
                    PhoneLoginScreen() {
                        DispatchQueue.main.async {
                            synchronizationManager.startupProcess(synchronizing: true)
                        }
                    }
                    
                case .ValidationScreen:
                    VerificationView() {
                        DispatchQueue.main.async {
                            synchronizationManager.startupProcess(synchronizing: true)
                        }
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
                    
                case .loginWithEmailView:
                    LoginWithEmailView()
                    
                }
            }.environment(\.font, Font.system(.body, design: .rounded))
            .onOpenURL(perform: { url in
                universalLinksManager.handleIncomingURL(url)
            })
            .animation(.easeIn(duration: 0.25), value: destination)
            .animation(.easeIn(duration: 0.25), value: synchronizationManager.startupState)
            .navigationTransition(
                .fade(.in)
            )
            //}
            
            
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                if isMoreThanFiveMinutesOld(date: StorageManager.shared.lastTime) {
                    synchronizationManager.startupProcess(synchronizing: true)
                }
                Task {
                    do {
                        try await realtimeManager.initAblyConnection()
                        print("Ably connection initialized")
                        realtimeManager.subscribeToChanges {
                            switch $0 {
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
            } else if newPhase == .background {
                realtimeManager.unsubscribeToChanges()
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

private struct ColumnViewPreferenceKey: EnvironmentKey {
    static let defaultValue = true // Default to column view on
}

extension EnvironmentValues {
    var columnViewPreference: Bool {
        get { self[ColumnViewPreferenceKey.self] }
        set { self[ColumnViewPreferenceKey.self] = newValue }
    }
}

class ColumnViewModel: ObservableObject {
    @AppStorage("columnViewPreference") var isColumnViewEnabled = true // Use @AppStorage for UserDefaults

    @AppStorage("hapticFeedback") var hapticFeedback = true // Use @AppStorage for UserDefaults
    // Add any other relevant view logic here
}
