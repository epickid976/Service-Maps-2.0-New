//
//  ContentView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/27/23.
//

import SwiftUI
import CoreData
import UIKit


struct HomeTabView: View {
    
    @State private var selectedTab = 0
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authorizationProvider: AuthorizationProvider
    
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
                } else if selectedTab == 1 {
                    AccessView()
                        .tag(1)
                        .tabItem {
                            Image(systemName: "2.circle")
                            Text("Tab 2")
                        }
                } else if selectedTab == 2 {
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
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
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
                        Image(systemName: selectedTab == 1 ? "person.badge.key.fill" : "person.badge.key")
                            .imageScale(.large)
                            .foregroundColor(selectedTab == 1 ? .blue : .gray)
                            .scaleEffect(selectedTab == 1 ? 1.2 : 1.0) // Add scale effect
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        withAnimation(.default) {
                            selectedTab = 2
                        }
                    }) {
                        Image(systemName: selectedTab == 2 ? "gearshape.fill" : "gearshape")
                            .imageScale(.large)
                            .scaleEffect(selectedTab == 2 ? 1.2 : 1.0) // Add scale effect
                            .foregroundColor(selectedTab == 2 ? .blue : .gray)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 8)
                .background(colorScheme == .dark ? .black : .white)
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    HomeTabView().environment(\.managedObjectContext, DataController.preview.container.viewContext)
}

