//
//  ContentView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/27/23.
//

import SwiftUI
import CoreData
import UIKit
import NavigationTransitions
import MijickPopups
import Toasts

// MARK: - Home Tab View
struct HomeTabView: View {
    
    @State private var selectedTab = 0
    
    // MARK: - Environment
    
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Dependencies
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var authorizationLevelManager = AuthorizationLevelManager()
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if selectedTab == 0 {
                    TerritoryView().installToast(position: .bottom)
                        .tag(0)
                        .tabItem {
                            Image(systemName: "1.circle")
                            Text("Tab 1")
                        }
                } else if selectedTab == 1 && (authorizationLevelManager.existsPhoneCredentials() || authorizationLevelManager.existsAdminCredentials()) {
                        PhoneTerritoriesScreen().installToast(position: .bottom)
                        .tag(1)
                        .tabItem {
                            Image(systemName: "2.circle")
                            Text("Tab 2")
                        }
                } else if selectedTab == 2 {
                    RecallsView().installToast(position: .bottom)
                        .tag(1)
                        .tabItem {
                            Image(systemName: "2.circle")
                            Text("Tab 2")
                        }
                } else if selectedTab == 3 {
                    AccessView().installToast(position: .bottom)
                        .tag(1)
                        .tabItem {
                            Image(systemName: "2.circle")
                            Text("Tab 2")
                        }
                } else if selectedTab == 4 {
                    SettingsView().installToast(position: .bottom)
                        .tag(2)
                        .tabItem {
                            Image(systemName: "3.circle")
                            Text("Tab 3")
                        }
                }
                
                Spacer()
                HStack(alignment: .center) {
                    Button(action: {
                        withAnimation(.spring) {
                            selectedTab = 0
                            HapticManager.shared.trigger(.lightImpact)
                        }
                    }) {
                        Image(systemName: selectedTab == 0 ? "map.fill" : "map")
                            .imageScale(.large)
                            .foregroundColor(selectedTab == 0 ? .blue : .gray)
                            .scaleEffect(selectedTab == 0 ? 1.2 : 1.0) // Add scale effect
                    }
                   // //.keyboardShortcut("1", modifiers: .command)
                    .frame(maxWidth: .infinity)
                    .hoverEffect()
                    
                    if authorizationLevelManager.existsPhoneCredentials() || authorizationLevelManager.existsAdminCredentials() {
                        Button(action: {
                            withAnimation(.default) {
                                selectedTab = 1
                                HapticManager.shared.trigger(.lightImpact)
                            }
                        }) {
                            Image(systemName: selectedTab == 1 ? "phone.connection.fill" : "phone.connection")
                                .imageScale(.large)
                                .foregroundColor(selectedTab == 1 ? .blue : .gray)
                                .scaleEffect(selectedTab == 1 ? 1.2 : 1.0) // Add scale effect
                        }
                        .frame(maxWidth: .infinity)
                        .optionalViewModifier { content in
                            if (authorizationLevelManager.existsPhoneCredentials() || authorizationLevelManager.existsAdminCredentials()) {
                                content
                                   // //.keyboardShortcut("2", modifiers: .command)
                            }
                        }
                        .hoverEffect()
                        
                    }
                    
                    Button(action: {
                        withAnimation(.default) {
                            selectedTab = 2
                            HapticManager.shared.trigger(.lightImpact)
                        }
                    }) {
                        Image(systemName: selectedTab == 2 ? "person.2.fill" : "person.2")
                            .imageScale(.large)
                            .foregroundColor(selectedTab == 2 ? .blue : .gray)
                            .scaleEffect(selectedTab == 2 ? 1.2 : 1.0) // Add scale effect
                    }.frame(maxWidth: .infinity).hoverEffect()
                   
                        Button(action: {
                            withAnimation(.default) {
                                selectedTab = 3
                                HapticManager.shared.trigger(.lightImpact)
                            }
                        }) {
                            Image(systemName: selectedTab == 3 ? "key.horizontal.fill" : "key.horizontal")
                                .imageScale(.large)
                                .foregroundColor(selectedTab == 3 ? .blue : .gray)
                                .scaleEffect(selectedTab == 3 ? 1.2 : 1.0) // Add scale effect
                        }
                        .frame(maxWidth: .infinity)
                        .optionalViewModifier { content in
                            if (authorizationLevelManager.existsPhoneCredentials() || authorizationLevelManager.existsAdminCredentials()) {
                                content
                                   // //.keyboardShortcut("3", modifiers: .command)
                            } else {
                                content
                                   // //.keyboardShortcut("2", modifiers: .command)
                            }
                        }
                        .hoverEffect()
                    
                    Button(action: {
                        withAnimation(.default) {
                            selectedTab = 4
                            HapticManager.shared.trigger(.lightImpact)
                        }
                    }) {
                        Image(systemName: selectedTab == 4 ? "gearshape.fill" : "gearshape")
                            .imageScale(.large)
                            .scaleEffect(selectedTab == 4 ? 1.2 : 1.0) // Add scale effect
                            .foregroundColor(selectedTab == 4 ? .blue : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .optionalViewModifier { content in
                        if (authorizationLevelManager.existsPhoneCredentials() || authorizationLevelManager.existsAdminCredentials()) {
                            content
                                //.keyboardShortcut("4", modifiers: .command)
                        } else {
                            content
                              //  //.keyboardShortcut("3", modifiers: .command)
                        }
                    }
                    .hoverEffect()
                    
                }
                .padding(.vertical, 8)
                .background(colorScheme == .dark ? .black : .white)
            }
            .onReceive(NotificationCenter.default.publisher(for: .openRecallsTab)) { _ in
                withAnimation {
                    // If admin/phone tab is present, Recalls is index 2
                    // Otherwise, it's index 1
                    if authorizationLevelManager.existsPhoneCredentials() || authorizationLevelManager.existsAdminCredentials() {
                        selectedTab = 2
                    } else {
                        selectedTab = 1
                    }
                }
            }
            .ignoresSafeArea(.keyboard)
                .onAppear {
                    do {
                         try isUpdateAvailable(completion: { (update, error) in
                            if let update {
                                if update {
                                    Task {
                                        await CenterPopup_Update().present()
                                    }
                                }
                            }
                        })
                    } catch {
                        print("Error checking for updates: \(error)")
                    }
                }
            .navigationBarBackButtonHidden(true)
            .navigationViewStyle(StackNavigationViewStyle())
            
        }
        .navigationTransition(
            .slide.combined(with: .fade(.in))
        )
    }
}

// MARK: - Update Check Popup

struct CenterPopup_Update: CenterPopup {
    @State var loading = false

    var body: some View {
        VStack(spacing: 16) {
            // MARK: - Icon
            Image(systemName: "arrow.down.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(.blue)

            // MARK: - Title
            Text("Update Available")
                .font(.title2)
                .fontWeight(.heavy)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            // MARK: - Description
            Text("""
A new update for the app is available! Please update the app as soon as possible to access the latest features and improvements.

Would you like to update now?
""")
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineSpacing(5)

            // MARK: - Buttons
            HStack(spacing: 12) {
                if !loading {
                    CustomBackButton(showImage: true, text: "Later") {
                        Task {
                            await dismissLastPopup()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                CustomButton(
                    loading: loading,
                    title: "Update Now",
                    active: true
                ) {
                    withAnimation { loading = true }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        UIApplication.shared.open(URL(string: "https://apps.apple.com/us/app/service-maps/id1664309103")!)
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        Task {
                            await dismissLastPopup()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Material.thin)
        .cornerRadius(20)
    }

    func configurePopup(config: CenterPopupConfig) -> CenterPopupConfig {
        config.popupHorizontalPadding(24)
    }
}

