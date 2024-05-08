//
//  SettingsView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/7/23.
//

import SwiftUI
import NavigationTransitions
import PopupView
import AlertKit

struct SettingsView: View {
    @State var loading = false
    @State var alwaysLoading = true
    
    //MARK: API
    let authenticationManager = AuthenticationManager()
    
    @ObservedObject var viewModel = SettingsViewModel()
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    @Environment(\.sizeCategory) var sizeCategory
    
    let alertViewDeleted = AlertAppleMusic17View(title: "Cache Deleted", subtitle: nil, icon: .custom(UIImage(systemName: "trash")!))
    @Environment(\.mainWindowSize) var mainWindowSize
    var body: some View {
        ScrollView {
            VStack {
                viewModel.profile()
                Spacer().frame(height: 25)
                if !AuthorizationLevelManager().existsAdminCredentials() {
                    viewModel.phoneLoginInfoCell(mainWindowSize: mainWindowSize)
                }
                viewModel.administratorInfoCell(mainWindowSize: mainWindowSize)
                viewModel.infosView(mainWindowSize: mainWindowSize)
                Spacer().frame(height: 25)
                viewModel.deleteCacheMenu(mainWindowSize: mainWindowSize)
                Spacer().frame(height: 25)
                viewModel.deleteAccount(mainWindowSize: mainWindowSize)
            }
            .padding(.vertical)
            .alert(isPresent: $viewModel.showToast, view: alertViewDeleted)
            .popup(isPresented: $viewModel.showAlert) {
                viewModel.aboutApp(usingLargeText: sizeCategory == .large || sizeCategory == .extraLarge ? false : true)
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
            .popup(isPresented: $viewModel.showDeletionConfirmationAlert) {
                viewModel.accountDeletionAlertConfirmation()
                    .frame(width: 400, height: 250)
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
            .popup(isPresented: $viewModel.showDeletionAlert) {
                viewModel.accountDeletionAlert(usingLargeText: sizeCategory == .large || sizeCategory == .extraLarge ? false : true)
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
            .fullScreenCover(isPresented: $viewModel.presentPolicy) {
                NavigationStack {
                    PrivacyPolicy(sheet: true)
                }
            }
            .fullScreenCover(isPresented: $viewModel.phoneBookLogin) {
                PhoneLoginScreen {
                    synchronizationManager.startupProcess(synchronizing: true)
                    viewModel.phoneBookLogin = false
                }
            }
        }
        .scrollIndicators(.hidden)
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
