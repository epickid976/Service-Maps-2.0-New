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

// MARK: - Search Zoom Namespace Environment Key
struct SearchZoomNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var searchZoomNamespace: Namespace.ID? {
        get { self[SearchZoomNamespaceKey.self] }
        set { self[SearchZoomNamespaceKey.self] = newValue }
    }
}

// MARK: - Matched Transition Source Modifier (iOS 18+)
struct MatchedTransitionSourceModifier: ViewModifier {
    let id: String
    let namespace: Namespace.ID?
    
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *), let namespace = namespace {
            content
                .matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

// MARK: - Home Tab View
struct HomeTabView: View {
    
    @State private var selectedTab = 0
    
    // MARK: - Environment
    
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Dependencies
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var authorizationLevelManager = AuthorizationLevelManager()
    @ObservedObject var tabBarSearchManager = TabBarSearchManager.shared
    
    // MARK: - Namespace for zoom transition
    @Namespace private var searchZoomNamespace
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Group {
                if #available(iOS 26.0, *) {
                    nativeTabView
                } else {
                    customTabView
                }
            }
            .environment(\.searchZoomNamespace, searchZoomNamespace)
            
            // iOS 18+: Use fullScreenCover with native zoom transition
            // iOS 17 and below: Use ZStack overlay with custom animation
            if #available(iOS 18.0, *) {
                Color.clear
                    .fullScreenCover(isPresented: $tabBarSearchManager.isSearchActive) {
                        NavigationStack {
                            SearchView(searchMode: tabBarSearchManager.searchMode) {
                                tabBarSearchManager.deactivateSearch()
                            }
                        }
                        .navigationTransition(.zoom(sourceID: "searchButton", in: searchZoomNamespace))
                    }
            } else {
                // Custom zoom-like animation for iOS 17 and below
                if tabBarSearchManager.isSearchActive {
                    NavigationStack {
                        SearchView(searchMode: tabBarSearchManager.searchMode) {
                            tabBarSearchManager.deactivateSearch()
                        }
                    }
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.5).combined(with: .opacity).animation(.spring(response: 0.4, dampingFraction: 0.75)),
                            removal: .scale(scale: 0.5).combined(with: .opacity).animation(.spring(response: 0.3, dampingFraction: 0.8))
                        )
                    )
                    .zIndex(1)
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: tabBarSearchManager.isSearchActive)
        .navigationTransition(
            .slide.combined(with: .fade(.in))
        )
    }
    
    // MARK: - iOS 26+ Native TabView
    @available(iOS 26.0, *)
    private var nativeTabView: some View {
        TabView(selection: $selectedTab) {
            Tab("Territories", systemImage: "map", value: 0) {
                TerritoryView()
                    .installToast(position: .bottom)
            }
            
            if authorizationLevelManager.existsPhoneCredentials() || authorizationLevelManager.existsAdminCredentials() {
                Tab("Phone", systemImage: "phone.connection", value: 1) {
                    PhoneTerritoriesScreen()
                        .installToast(position: .bottom)
                }
            }
            
            Tab("Recalls", systemImage: "person.2", value: 2) {
                RecallsView()
                    .installToast(position: .bottom)
            }
            
            Tab("Access", systemImage: "key.horizontal", value: 3) {
                AccessView()
                    .installToast(position: .bottom)
            }
            
            Tab("Settings", systemImage: "gearshape", value: 4) {
                SettingsView()
                    .installToast(position: .bottom)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openRecallsTab)) { _ in
            withAnimation {
                if authorizationLevelManager.existsPhoneCredentials() || authorizationLevelManager.existsAdminCredentials() {
                    selectedTab = 2
                } else {
                    selectedTab = 1
                }
            }
        }
        .onAppear {
            checkForUpdates()
        }
    }
    
    // MARK: - iOS 25 and below Custom TabView
    private var customTabView: some View {
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
                            .scaleEffect(selectedTab == 0 ? 1.2 : 1.0)
                    }
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
                                .scaleEffect(selectedTab == 1 ? 1.2 : 1.0)
                        }
                        .frame(maxWidth: .infinity)
                        .optionalViewModifier { content in
                            if (authorizationLevelManager.existsPhoneCredentials() || authorizationLevelManager.existsAdminCredentials()) {
                                content
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
                            .scaleEffect(selectedTab == 2 ? 1.2 : 1.0)
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
                            .scaleEffect(selectedTab == 3 ? 1.2 : 1.0)
                    }
                    .frame(maxWidth: .infinity)
                    .optionalViewModifier { content in
                        if (authorizationLevelManager.existsPhoneCredentials() || authorizationLevelManager.existsAdminCredentials()) {
                            content
                        } else {
                            content
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
                            .scaleEffect(selectedTab == 4 ? 1.2 : 1.0)
                            .foregroundColor(selectedTab == 4 ? .blue : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .optionalViewModifier { content in
                        if (authorizationLevelManager.existsPhoneCredentials() || authorizationLevelManager.existsAdminCredentials()) {
                            content
                        } else {
                            content
                        }
                    }
                    .hoverEffect()
                }
                .padding(.vertical, 8)
                .background(colorScheme == .dark ? .black : .white)
            }
            .onReceive(NotificationCenter.default.publisher(for: .openRecallsTab)) { _ in
                withAnimation {
                    if authorizationLevelManager.existsPhoneCredentials() || authorizationLevelManager.existsAdminCredentials() {
                        selectedTab = 2
                    } else {
                        selectedTab = 1
                    }
                }
            }
            .ignoresSafeArea(.keyboard)
            .onAppear {
                checkForUpdates()
            }
            .navigationBarBackButtonHidden(true)
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
    // MARK: - Helper Methods
    private func checkForUpdates() {
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
                .multilineTextAlignment(.center)
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

