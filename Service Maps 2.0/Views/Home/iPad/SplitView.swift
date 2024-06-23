//
//  SplitView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 6/20/24.
//

import SwiftUI
import MijickPopupView

struct SplitView: View {
    @State var selection: Set<Int> = [0]
    
    var body: some View {
        
        NavigationSplitView {
            List(selection: $selection) {
                Label("Territories", systemImage: "map").tag(0)
                Label("Phone Territories", systemImage: "info.circle").tag(1)
                Label("Keys", systemImage: "info.circle").tag(2)
                Label("Settings", systemImage: "info.circle").tag(3)
            }
            .listStyle(.sidebar)
            .navigationTitle("Menu") // Optional: Add a title to the sidebar
        } detail: {
            switch selection.first ?? 0 {
                case 0:
                TerritoryView().implementPopupView()
                case 1:
                    PhoneTerritoriesScreen().implementPopupView()
                case 2:
                    AccessView().implementPopupView()
                case 3:
                    SettingsView().implementPopupView()
                default:
                    TerritoryView().implementPopupView()
            }
        }
    }
}

#Preview {
    SplitView()
}
