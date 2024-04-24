//
//  SettingsView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/7/23.
//

import SwiftUI
import NavigationTransitions
import PopupView

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
                viewModel.infosView()
                //App Info (Clear Cache, Share App, Privacy Policy, About App)
//                ImagePipeline.shared.cache.removeAll()
//                DataLoader.sharedUrlCache.removeAllCachedResponses()
                //Delete Account
            }
            .padding(.vertical)
            .popup(isPresented: $viewModel.showAlert) {
                viewModel.aboutApp()
                    .frame(width: 400, height: 400)
                    .background(Material.thin).cornerRadius(16, corners: .allCorners)
            } customize: {
                $0
                    .type(.default)
                    .closeOnTapOutside(false)
                    .dragToDismiss(false)
                    .isOpaque(true)
                    .animation(.spring())
                    .closeOnTap(false)
                    .backgroundColor(.black.opacity(0.8))
            }
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
