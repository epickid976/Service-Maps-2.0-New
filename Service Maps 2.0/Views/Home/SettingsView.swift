//
//  SettingsView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/7/23.
//

import SwiftUI
import NavigationTransitions

struct SettingsView: View {
    @State var loading = false
    @State var alwaysLoading = true
    
    //MARK: API
    let authenticationManager = AuthenticationManager()
    
    @ObservedObject var viewModel = SettingsViewModel()
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    var body: some View {
        ScrollView {
            VStack {
                viewModel.profile()
                viewModel.administratorInfoCell()
            }
            .padding(.vertical)
            .fullScreenCover(isPresented: $viewModel.presentSheet) {
                AdminLoginView {
                    synchronizationManager.startupProcess(synchronizing: true)
                    viewModel.presentSheet = false
                }
            }
            .padding()
        }
        .navigationBarTitle("Settings", displayMode: .automatic)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                HStack {
                    Button("", action: { viewModel.syncAnimation.toggle();  print("Syncing") ; synchronizationManager.startupProcess(synchronizing: true) })
                        .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $viewModel.dataStore.synchronized, lastTime: $viewModel.dataStore.lastTime))
                }
            }
        }
        .navigationTransition(viewModel.presentSheet ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    SettingsView()
}
