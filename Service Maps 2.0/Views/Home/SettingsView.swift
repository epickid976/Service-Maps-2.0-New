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
import MijickPopupView

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
            .onChange(of: viewModel.showAlert) { value in
                if value {
                    CentrePopup_AboutApp(viewModel: viewModel, usingLargeText: sizeCategory == .large || sizeCategory == .extraLarge ? false : true).showAndStack()
                }
            }
//            .popup(isPresented: $viewModel.showAlert) {
//                viewModel.aboutApp(usingLargeText: sizeCategory == .large || sizeCategory == .extraLarge ? false : true)
//                    .frame(width: 400, height: 400)
//                    .background(Material.thin).cornerRadius(16, corners: .allCorners)
//            } customize: {
//                $0
//                    .type(.default)
//                    .closeOnTapOutside(false)
//                    .dragToDismiss(false)
//                    .isOpaque(true)
//                    .animation(.spring())
//                    .closeOnTap(false)
//                    .backgroundColor(.black.opacity(0.8))
//            }
//            .popup(isPresented: $viewModel.showDeletionConfirmationAlert) {
//                viewModel.accountDeletionAlertConfirmation()
//                    .frame(width: 400, height: 250)
//                    .background(Material.thin).cornerRadius(16, corners: .allCorners)
//            } customize: {
//                $0
//                    .type(.default)
//                    .closeOnTapOutside(false)
//                    .dragToDismiss(false)
//                    .isOpaque(true)
//                    .animation(.spring())
//                    .closeOnTap(false)
//                    .backgroundColor(.black.opacity(0.8))
//            }
//            .popup(isPresented: $viewModel.showDeletionAlert) {
//                viewModel.accountDeletionAlert(usingLargeText: sizeCategory == .large || sizeCategory == .extraLarge ? false : true)
//                    .frame(width: 400, height: 400)
//                    .background(Material.thin).cornerRadius(16, corners: .allCorners)
//            } customize: {
//                $0
//                    .type(.default)
//                    .closeOnTapOutside(false)
//                    .dragToDismiss(false)
//                    .isOpaque(true)
//                    .animation(.spring())
//                    .closeOnTap(false)
//                    .backgroundColor(.black.opacity(0.8))
//            }
            
            .onChange(of: viewModel.showDeletionConfirmationAlert) { value in
                if value {
                    CentrePopup_DeletionConfirmation(viewModel: viewModel, usingLargeText: sizeCategory == .large || sizeCategory == .extraLarge ? false : true).showAndReplace()
                }
            }
            .onChange(of: viewModel.showDeletionAlert) { value in
                if value {
                    CentrePopup_Deletion(viewModel: viewModel, usingLargeText: sizeCategory == .large || sizeCategory == .extraLarge ? false : true).showAndReplace()
                }
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

struct CentrePopup_AboutApp: CentrePopup {
    @ObservedObject var viewModel: SettingsViewModel
    var usingLargeText: Bool
    
    func createContent() -> some View {
        VStack {
            Text("About App")
                .font(.title3)
                .lineLimit(1)
                .foregroundColor(.primary)
                .fontWeight(.heavy)
            Spacer().frame(height: 10)
            Text("""
            Service Maps has been created with the purpose of streamlining and facilitating the control and registration of the public preaching of Jehovah's Witnesses.
            This tool is not part of JW.ORG nor is it an official app of the organization. It is simply the result of the effort and love of some brothers. We hope it is useful. Thank you for using Service Maps.
            """)
            .font(usingLargeText ? .caption2 : .body)
            .lineLimit(10)
            .foregroundColor(.primary)
            .fontWeight(.bold)
            CustomBackButton(showImage: false, text: "Dismiss") {
                withAnimation {
                    self.viewModel.showAlert = false
                    dismiss()
                }
            }.hSpacing(.trailing)
            //.frame(width: 100)
        }
        .padding()
            .padding(.top, 10)
            .padding(.bottom, 10)
            .padding(.horizontal, 10)
            .background(Material.thin).cornerRadius(15, corners: .allCorners)
    }
    
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup
            .horizontalPadding(24)
            .cornerRadius(15)
            .backgroundColour(Color(UIColor.systemGray6).opacity(85))
    }
}
#Preview {
    SettingsView()
}

struct CentrePopup_DeletionConfirmation: CentrePopup {
    @ObservedObject var viewModel: SettingsViewModel
    var usingLargeText: Bool
    
    func createContent() -> some View {
        VStack {
            Text("Are you sure you want to delete your account?")
                .font(.title3)
                .lineLimit(2)
                .foregroundColor(.primary)
                .fontWeight(.heavy)
                .multilineTextAlignment(.center)
            Text("This is nonreversible")
                .font(.headline)
                .lineLimit(10)
                .foregroundColor(.primary)
                .fontWeight(.heavy)
            
            Text(viewModel.deletionError)
                .fontWeight(.bold)
                .foregroundColor(.red)
            //.vSpacing(.bottom)
            
            HStack {
                CustomBackButton(showImage: true, text: "Cancel") {
                    withAnimation {
                        self.viewModel.showDeletionConfirmationAlert = false
                        PopupManager.dismissAll()
                    }
                }.hSpacing(.trailing)
                CustomButton(loading: viewModel.loading, title: "Delete", color: .red, action: {
                    withAnimation { self.viewModel.loading = true }
                    Task {
                        switch await AuthenticationManager().deleteAccount() {
                        case .success(_):
                            withAnimation { self.viewModel.loading = false }
                            
                            self.viewModel.showDeletionConfirmationAlert = false
                            dismiss()
                        case .failure(_):
                            withAnimation { self.viewModel.loading = true }
                            self.viewModel.deletionError = "Error deleting account"
                        }
                    }
                })
                .hSpacing(.trailing)
                //.frame(width: 100)
            }
        }
            .padding(.top, 10)
            .padding(.bottom, 10)
            .padding(.horizontal, 10)
            .background(Material.thin).cornerRadius(15, corners: .allCorners)
    }
    
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup
            .horizontalPadding(24)
            .cornerRadius(15)
            .backgroundColour(Color(UIColor.systemGray6).opacity(85))
    }
}

struct CentrePopup_Deletion: CentrePopup {
    @ObservedObject var viewModel: SettingsViewModel
    var usingLargeText: Bool
    
    func createContent() -> some View {
        VStack {
            Text("Delete Account")
                .font(.title3)
                .lineLimit(1)
                .foregroundColor(.primary)
                .fontWeight(.heavy)
            Spacer().frame(height: 10)
            Text("""
                Are you sure about deleting your account? This action can not be undone. If you decide to delete your account, your account and all access granted to you will be deleted, but the information you have previously provided will remain on the server. The email used in this account cannot be reused again.
                """)
            .font(usingLargeText ? .caption2 : .headline)
            .lineLimit(10)
            .foregroundColor(.primary)
            .fontWeight(.heavy)
            .multilineTextAlignment(.center)
            
            HStack {
                CustomBackButton(showImage: true, text: "Cancel") {
                    self.viewModel.showDeletionAlert = false
                    dismiss()
                }.hSpacing(.trailing)
                CustomButton(loading: viewModel.loading, title: "Delete", color: .red, action: {
                    self.viewModel.showDeletionAlert = false
                        self.viewModel.showDeletionConfirmationAlert = true
                    
                })
                .hSpacing(.trailing)
                //.frame(width: 100)
            }
        }
            .padding(.top, 10)
            .padding(.bottom, 10)
            .padding(.horizontal, 10)
            .background(Material.thin).cornerRadius(15, corners: .allCorners)
    }
    
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup
            .horizontalPadding(24)
            .cornerRadius(15)
            .backgroundColour(Color(UIColor.systemGray6).opacity(85))
    }
}
