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
import MijickPopupView

struct HomeTabView: View {
    
    @State private var selectedTab = 0
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var authorizationLevelManager = AuthorizationLevelManager()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if selectedTab == 0 {
                    TerritoryView()
                        .tag(0)
                        .tabItem {
                            Image(systemName: "1.circle")
                            Text("Tab 1")
                        }
                } else if selectedTab == 1 && (authorizationLevelManager.existsPhoneCredentials() || authorizationLevelManager.existsAdminCredentials()) {
                        PhoneTerritoriesScreen()
                        .tag(1)
                        .tabItem {
                            Image(systemName: "2.circle")
                            Text("Tab 2")
                        }
                } else if selectedTab == 2 {
                    AccessView()
                        .tag(1)
                        .tabItem {
                            Image(systemName: "2.circle")
                            Text("Tab 2")
                        }
                } else if selectedTab == 3 {
                    SettingsView()
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
                            Image(systemName: selectedTab == 2 ? "person.badge.key.fill" : "person.badge.key")
                                .imageScale(.large)
                                .foregroundColor(selectedTab == 2 ? .blue : .gray)
                                .scaleEffect(selectedTab == 2 ? 1.2 : 1.0) // Add scale effect
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
                            selectedTab = 3
                            HapticManager.shared.trigger(.lightImpact)
                        }
                    }) {
                        Image(systemName: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                            .imageScale(.large)
                            .scaleEffect(selectedTab == 3 ? 1.2 : 1.0) // Add scale effect
                            .foregroundColor(selectedTab == 3 ? .blue : .gray)
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
            }.ignoresSafeArea(.keyboard)
                .onAppear {
                    do {
                         try isUpdateAvailable(completion: { [self] (update, error) in
                            if let update {
                                if update {
                                    DispatchQueue.main.async {
                                        CentrePopup_Update().showAndStack()
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

struct CentrePopup_Update: CentrePopup {
    @State var loading = false
    
    func createContent() -> some View {
        VStack {
            Text("A new update for the app is available!")
                .font(.title3)
                .fontWeight(.heavy)
                .hSpacing(.leading)
                .padding(.leading)
                .padding(.bottom, 3)
            Text("Please update the app as soon as possible to access the latest features and improvements. \nWould you like to update now?")
                .font(.subheadline)
                .fontWeight(.heavy)
                .hSpacing(.leading)
                .padding(.leading)
            
            HStack {
                if !loading {
                    CustomBackButton(text: "Later") {
                        withAnimation {
                            //self.viewModel.showAlert = false
                            dismiss()
                        }
                    }
                }
                //.padding([.top])
                
                CustomButton(loading: loading, title: "Update Now") {
                    withAnimation {
                        loading = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        UIApplication.shared.open(URL(string: "https://apps.apple.com/us/app/service-maps/id1664309103")!)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        dismiss()
                    }
                    
                }
            }
            .padding([.horizontal, .bottom])
        }.padding()
    }
    
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup
            .horizontalPadding(24)
            .cornerRadius(15)
            .backgroundColour(Color(UIColor.systemGray6).opacity(85))
    }
}

