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
    
    init(showBackButton: Bool = false) {
        self.showBackButton = showBackButton
    }
    //MARK: API
    let authenticationManager = AuthenticationManager()
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel = SettingsViewModel()
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    var showBackButton = false
    @Environment(\.sizeCategory) var sizeCategory
    
    let alertViewDeleted = AlertAppleMusic17View(title: "Cache Deleted", subtitle: nil, icon: .custom(UIImage(systemName: "trash")!))
    
    @Environment(\.mainWindowSize) var mainWindowSize
    var body: some View {
        let alertUpdate = AlertAppleMusic17View(title: viewModel.showUpdateToastMessage, subtitle: nil, icon: .custom(UIImage(systemName: "arrow.triangle.2.circlepath.circle")!))
        ScrollView {
            VStack {
                viewModel.profile(showBack: showBackButton) {
                    presentationMode.wrappedValue.dismiss()
                }
                Spacer().frame(height: 25)
                if !AuthorizationLevelManager().existsAdminCredentials() {
                    viewModel.phoneLoginInfoCell(mainWindowSize: mainWindowSize, showBack: showBackButton) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                viewModel.administratorInfoCell(mainWindowSize: mainWindowSize, showBack: showBackButton) {
                    presentationMode.wrappedValue.dismiss()
                }
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
            .alert(isPresent: $viewModel.showUpdateToast, view: alertUpdate)
            .onChange(of: viewModel.showDeletionConfirmationAlert) { value in
                if value {
                    CentrePopup_DeletionConfirmation(viewModel: viewModel, usingLargeText: sizeCategory == .large || sizeCategory == .extraLarge ? false : true, showBack: showBackButton, onDone: { presentationMode.wrappedValue.dismiss() }).showAndReplace()
                }
            }
            .onChange(of: viewModel.showDeletionAlert) { value in
                if value {
                    CentrePopup_Deletion(viewModel: viewModel, usingLargeText: sizeCategory == .large || sizeCategory == .extraLarge ? false : true).showAndReplace()
                }
            }
            
            .onChange(of: viewModel.showEditNamePopup) { value in
                if value {
                    CentrePopup_EditUsername(viewModel: viewModel).showAndReplace()
                }
            }
            
            .fullScreenCover(isPresented: $viewModel.presentSheet) {
                AdminLoginView {
                    if showBackButton {
                        presentationMode.wrappedValue.dismiss()
                    }
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
                    if showBackButton {
                        presentationMode.wrappedValue.dismiss()
                    }
                    synchronizationManager.startupProcess(synchronizing: true)
                    viewModel.phoneBookLogin = false
                    
                }
            }
        }
        .scrollIndicators(.hidden)
        .navigationBarTitle("Settings", displayMode: .automatic)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                if showBackButton {
                    HStack {
                        Button("", action: {withAnimation { viewModel.backAnimation.toggle() };
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }).keyboardShortcut(.delete, modifiers: .command)
                            .buttonStyle(CircleButtonStyle(imageName: "arrow.backward", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.backAnimation))
                    }
                }
            }
            
            ToolbarItemGroup(placement: .topBarTrailing) {
                HStack {
                    Button("", action: { viewModel.syncAnimation.toggle();  print("Syncing") ; synchronizationManager.startupProcess(synchronizing: true) }).keyboardShortcut("s", modifiers: .command)
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
            }.hSpacing(.trailing).keyboardShortcut("\r", modifiers: [.command, .shift])
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
    var showBack: Bool
    var onDone: () -> Void
    
    func createContent() -> some View {
        VStack {
            Text("Are you sure you want to delete your account?")
                .font(.title3)
                .lineLimit(2)
                .foregroundColor(.primary)
                .fontWeight(.heavy)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
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
                }.hSpacing(.trailing).keyboardShortcut("\r", modifiers: [.command, .shift])
                CustomButton(loading: viewModel.loading, title: "Delete", color: .red, action: {
                    withAnimation { self.viewModel.loading = true }
                    Task {
                        switch await AuthenticationManager().deleteAccount() {
                        case .success(_):
                            withAnimation { self.viewModel.loading = false }
                            
                            self.viewModel.showDeletionConfirmationAlert = false
                            dismiss()
                            if showBack {
                                onDone()
                            }
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
                }.hSpacing(.trailing).keyboardShortcut("\r", modifiers: [.command, .shift])
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

struct CentrePopup_EditUsername: CentrePopup {
    @ObservedObject var viewModel: SettingsViewModel
    @FocusState private var usernameFocus: Bool
    @State var username = StorageManager.shared.userName ?? ""
    
    @State var error = ""
    @State var loading = false
    func createContent() -> some View {
        VStack {
            Text("Edit Username")
                .font(.title3)
                .fontWeight(.bold)
                .padding()
            
            CustomField(text: $username, isFocused: $usernameFocus, textfield: true, textfieldAxis: .vertical, placeholder: "New Username")
                .padding(.bottom)
            
            Text(error)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            HStack {
                if !loading {
                    CustomBackButton() {
                        dismiss()
                        self.viewModel.showEditNamePopup = false
                    }
                }
                
                CustomButton(loading: loading, title: "Edit") {
                    if !username.isEmpty {
                        withAnimation { loading = true }
                        
                        Task {
                            let result = await viewModel.editUserName(name: username)
                            
                            switch result {
                            case .success(_):
                                withAnimation { loading = false }
                                dismiss()
                                self.viewModel.showEditNamePopup = false
                            case .failure(let error):
                                withAnimation {
                                    loading = false
                                    self.error = NSLocalizedString("Error updating username", comment: "")
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .padding()
        .onAppear {
            usernameFocus = true // Focus on the text field when the view appears
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    usernameFocus = false // Dismiss the keyboard when "Done" is tapped
                }
                .tint(.primary)
                .fontWeight(.bold)
            }
        }
        .padding(.top, 5)
        .padding(.bottom, 5)
        .padding(.horizontal, 5)
        .background(Material.thin).cornerRadius(15, corners: .allCorners)
    }
    
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup
            .horizontalPadding(24)
            .cornerRadius(15)
            .backgroundColour(Color(UIColor.systemGray6).opacity(85))
    }
}

