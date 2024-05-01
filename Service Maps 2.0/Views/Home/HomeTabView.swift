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
                } else if selectedTab == 1  {
                    //&& (authorizationLevelManager.existsPhoneCredentials() || authorizationLevelManager.existsAdminCredentials())
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
                        }
                    }) {
                        Image(systemName: selectedTab == 0 ? "map.fill" : "map")
                            .imageScale(.large)
                            .foregroundColor(selectedTab == 0 ? .blue : .gray)
                            .scaleEffect(selectedTab == 0 ? 1.2 : 1.0) // Add scale effect
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        withAnimation(.default) {
                            selectedTab = 1
                        }
                    }) {
                        Image(systemName: selectedTab == 1 ? "phone.connection.fill" : "phone.connection")
                            .imageScale(.large)
                            .foregroundColor(selectedTab == 1 ? .blue : .gray)
                            .scaleEffect(selectedTab == 1 ? 1.2 : 1.0) // Add scale effect
                    }
                    .frame(maxWidth: .infinity)
                    
                    //if authorizationLevelManager.existsPhoneCredentials() || authorizationLevelManager.existsAdminCredentials() {
                        Button(action: {
                            withAnimation(.default) {
                                selectedTab = 2
                            }
                        }) {
                            Image(systemName: selectedTab == 2 ? "person.badge.key.fill" : "person.badge.key")
                                .imageScale(.large)
                                .foregroundColor(selectedTab == 2 ? .blue : .gray)
                                .scaleEffect(selectedTab == 2 ? 1.2 : 1.0) // Add scale effect
                        }
                        .frame(maxWidth: .infinity)
                    //}
                    
                    Button(action: {
                        withAnimation(.default) {
                            selectedTab = 3
                        }
                    }) {
                        Image(systemName: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                            .imageScale(.large)
                            .scaleEffect(selectedTab == 3 ? 1.2 : 1.0) // Add scale effect
                            .foregroundColor(selectedTab == 3 ? .blue : .gray)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 8)
                .background(colorScheme == .dark ? .black : .white)
            }
            .navigationBarBackButtonHidden(true)
        }
        .animation(.easeIn(duration: 0.25), value: synchronizationManager.startupState)
        .navigationTransition(
            .slide.combined(with: .fade(.in))
        )
    }
}


