//
//  SettingsView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/7/23.
//

import SwiftUI
import NavigationTransitions
import AlertKit
import MijickPopupView
import Lottie

struct SettingsView: View {
    @State var loading = false
    @State var alwaysLoading = true
    @State var backingUp = false
    @StateObject private var preferencesViewModel = ColumnViewModel()
    
    
    
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
    
    @Environment(\.requestReview) var requestReview
    @StateObject var realtimeManager = RealtimeManager.shared
    
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
                viewModel.languageLinkView(mainWindowSize: mainWindowSize)
                Spacer().frame(height: 25)
                preferencesView(mainWindowSize: mainWindowSize)
                Spacer().frame(height: 25)
                backupView(mainWindowSize: mainWindowSize)
                Spacer().frame(height: 25)
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
            .onChange(of: viewModel.showSharePopup) { value in
                if value {
                    CentrePopup_ShareApp(viewModel: viewModel, usingLargeText: sizeCategory == .large || sizeCategory == .extraLarge ? false : true).showAndReplace()
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
                    Task {
                        do {
                            try await realtimeManager.initAblyConnection()
                            print("Ably connection initialized")
                            realtimeManager.subscribeToChanges {
                                switch $0 {
                                case .success:
                                    print("Subscribed to changes")
                                case .failure(let error):
                                    print("Error: \(error)")
                                }
                            }
                        } catch {
                            print("Error: \(error)")
                        }
                    }
                }
            }
            
            .padding()
            .onChange(of: viewModel.presentPolicy) { value in
                if value {
                    BottomPopup_Document(viewModel: viewModel).showAndStack()
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
            .onChange(of: preferencesViewModel.isColumnViewEnabled) { value in
                HapticManager.shared.trigger(.lightImpact)
            }
            .onChange(of: preferencesViewModel.hapticFeedback) { value in
                HapticManager.shared.trigger(.lightImpact)
            }
        }
        .scrollIndicators(.never)
        .navigationBarTitle("Settings", displayMode: .automatic)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                if showBackButton {
                    HStack {
                        Button("", action: {withAnimation { viewModel.backAnimation.toggle(); HapticManager.shared.trigger(.lightImpact) };
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                dismissAll()
                                presentationMode.wrappedValue.dismiss()
                            }
                        })
                        //.keyboardShortcut(.delete, modifiers: .command)
                        .buttonStyle(CircleButtonStyle(imageName: "arrow.backward", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.backAnimation))
                        
                    }
                }
                
            }
            
            ToolbarItemGroup(placement: .topBarTrailing) {
                HStack {
                    Button("", action: { viewModel.syncAnimation.toggle();  print("Syncing") ; synchronizationManager.startupProcess(synchronizing: true) })//.keyboardShortcut("s", modifiers: .command)
                        .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $viewModel.dataStore.synchronized, lastTime: $viewModel.dataStore.lastTime))
                        .disabled(self.viewModel.showEditNamePopup || self.viewModel.presentPolicy || self.viewModel.showDeletionConfirmationAlert || self.viewModel.showDeletionAlert || self.viewModel.showSharePopup || self.viewModel.presentSheet || self.viewModel.showAlert)
                    
                    Button {
                        HapticManager.shared.trigger(.lightImpact)
                        self.viewModel.showEditNamePopup = true
                    } label: {
                        Circle()
                            .fill(Material.ultraThin)
                            .overlay(Image(systemName: "pencil")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.primary)
                                .padding(12)
                            )
                            .frame(width: 40, height: 40)
                    }.disabled(self.viewModel.showEditNamePopup || self.viewModel.presentPolicy || self.viewModel.showDeletionConfirmationAlert || self.viewModel.showDeletionAlert || self.viewModel.showSharePopup || self.viewModel.presentSheet || self.viewModel.showAlert)
                }
            }
        }
        .navigationTransition(viewModel.presentSheet ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
        .navigationViewStyle(StackNavigationViewStyle())
        .onChange(of: viewModel.requestReview) { value in
            if value {
                requestReview()
                self.viewModel.requestReview = false
            }
        }
    }
    
    @ViewBuilder
    func preferencesView(mainWindowSize: CGSize) -> some View {
        VStack(spacing: 16) {
            
            if UIDevice().userInterfaceIdiom == .pad {
                Button(action: {}) {
                    HStack {
                        HStack {
                            Image(systemName: "text.word.spacing")
                                .imageScale(.large)
                                .padding(.horizontal)
                                .foregroundColor(.blue)
                            Text("iPad Column View")
                                .font(.title3)
                                .lineLimit(2)
                                .foregroundColor(.primary)
                                .fontWeight(.heavy)
                        }
                        .hSpacing(.leading)
                        
                        HStack {
                            Toggle(isOn: $preferencesViewModel.isColumnViewEnabled) {}
                                .toggleStyle(CheckmarkToggleStyle(color: .blue))
                        }
                        .hSpacing(.trailing)
                        .frame(maxWidth: 100)
                    }
                }
                .frame(minHeight: 50)
            }
            
            if !(UIDevice().userInterfaceIdiom == .pad) {
                Button(action: {}) {
                    HStack {
                        HStack {
                            Image(systemName: "iphone.homebutton.radiowaves.left.and.right")
                                .imageScale(.large)
                                .padding(.horizontal)
                                .foregroundColor(.blue)
                            Text("Haptics")
                                .font(.title3)
                                .lineLimit(2)
                                .foregroundColor(.primary)
                                .fontWeight(.heavy)
                        }
                        .hSpacing(.leading)
                        
                        HStack {
                            Toggle(isOn: $preferencesViewModel.hapticFeedback) {}
                                .toggleStyle(CheckmarkToggleStyle(color: .blue))
                        }
                        .hSpacing(.trailing)
                        .frame(maxWidth: 100)
                    }
                }
                .frame(minHeight: 50)
            }
        }
        .padding(10)
        .frame(minWidth: mainWindowSize.width * 0.95)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    func backupView(mainWindowSize: CGSize) -> some View {
        VStack(spacing: 16) {
            Button {
                HapticManager.shared.trigger(.lightImpact)
                CentrePopup_Backup(viewModel: viewModel, backingUp: $backingUp).showAndStack()
            } label: {
                HStack {
                    HStack {
                        Image(systemName: "folder.fill")
                            .imageScale(.large)
                            .padding(.horizontal)
                        Text("Backup")
                            .font(.title3)
                            .lineLimit(2)
                            .foregroundColor(.primary)
                            .fontWeight(.heavy)
                    }
                    .hSpacing(.leading)
                }
            }//.keyboardShortcut("j", modifiers: .command)
            .frame(minHeight: 50)
        }
        .padding(10)
        .frame(minWidth: mainWindowSize.width * 0.95)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
            .lineLimit(20)
            .foregroundColor(.primary)
            .fontWeight(.bold)
            CustomBackButton(showImage: false, text: "Dismiss") {
                HapticManager.shared.trigger(.lightImpact)
                withAnimation {
                    self.viewModel.showAlert = false
                    dismiss()
                }
            }.hSpacing(.trailing)//.keyboardShortcut("\r", modifiers: [.command, .shift])
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

struct CentrePopup_Backup: CentrePopup {
    @ObservedObject var viewModel: SettingsViewModel
    @State var error = ""
    @Binding var backingUp: Bool
    @State var backupUrl: URL?
    @State var shareBackup: Bool = false
    
    @ObservedObject var backupManager = BackupManager.shared
    
    func createContent() -> some View {
        VStack {
            Text("Backup")
                .font(.title2)
                .lineLimit(1)
                .foregroundColor(.primary)
                .fontWeight(.heavy)
            Spacer().frame(height: 10)
            if backingUp {
                LottieView(animation: .named("compresing"))
                    .playing(loopMode: .loop)
                    .resizable()
                    .frame(width: 200, height: 200)
                Text("Creating Backup...")
                    .font(.headline)
                    .lineLimit(10)
                    .foregroundColor(.primary)
                    .fontWeight(.heavy)
                ProgressView(value: backupManager.progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
                    .frame(height: 20)
            } else {
                if let backupUrl {
                    HStack {
                            Image(systemName: "doc.zipper")  // File icon
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                            
                            Text(backupUrl.lastPathComponent)  // Display the file name from the URL
                                .font(.headline)
                                .lineLimit(1)
                                .foregroundColor(.primary)
                                .fontWeight(.heavy)
                        }
                        .padding(.vertical, 10)
                } else {
                    Text("A backup copy of all the territories, addresses, houses, and visits that are in the app will be made. A zip file will be generated that will contain the folders and forms for each address. Please note that only the last visit will be exported. The process may take some time.")
                        .font(.headline)
                        .lineLimit(10)
                        .foregroundColor(.primary)
                        .fontWeight(.heavy)
                }
            }
            
            if !error.isEmpty {
                Text(error)
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .lineLimit(10)
                    .multilineTextAlignment(.center)
            }
            
            HStack {
                CustomBackButton(showImage: true, text: "Cancel") {
                    HapticManager.shared.trigger(.lightImpact)
                    withAnimation {
                        self.viewModel.showDeletionConfirmationAlert = false
                        DispatchQueue.main.async {
                            BackupManager.shared.cancelBackup()  // Call cancel
                        }
                        backingUp = false  // Stop backing up UI
                        PopupManager.dismissAll()
                    }
                }.hSpacing(.trailing)
                
                if let backupUrl {
                    CustomButton(loading: shareBackup, alwaysExpanded: true,  title: NSLocalizedString("Share Backup", comment: ""), active: !viewModel.loading, action: {
                        HapticManager.shared.trigger(.lightImpact)
                        presentActivityViewController(with: backupUrl)
                    })
                    .hSpacing(.trailing)
                } else {
                    CustomButton(loading: backingUp, alwaysExpanded: true,  title: NSLocalizedString("Back up", comment: ""), active: !viewModel.loading, action: {
                        HapticManager.shared.trigger(.lightImpact)
                        backingUp = true
                        self.backingUp = true
                        BackupManager.shared.backupTask = Task {
                            let result = await BackupManager.shared.backupFiles()
                            
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let url):
                                    self.error = ""
                                    self.backingUp = false
                                    self.backupUrl = url
                                    presentActivityViewController(with: url)
                                    
                                case .failure(let error):
                                    self.error = error.localizedDescription
                                    self.backingUp = false
                                }
                                self.viewModel.loading = false
                            }
                        }
                    })
                    .hSpacing(.trailing)
                }
                //.frame(width: 100)
            }
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
    
    func presentActivityViewController(with url: URL) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
            rootVC.present(activityViewController, animated: true, completion: nil)
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                activityViewController.popoverPresentationController?.sourceView = UIApplication.shared.windows.first
                activityViewController.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2.1, y: UIScreen.main.bounds.height / 1.3, width: 200, height: 200)
            }
        }
    }
}

struct CentrePopup_ShareApp: CentrePopup {
    @ObservedObject var viewModel: SettingsViewModel
    var usingLargeText: Bool
    
    func createContent() -> some View {
        VStack {
            Text("Share App")
                .font(.title2)
                .lineLimit(1)
                .foregroundColor(.primary)
                .fontWeight(.heavy)
            Spacer().frame(height: 10)
            Text("Android")
                .font(.title3)
                .lineLimit(10)
                .foregroundColor(.primary)
                .fontWeight(.heavy)
            
            Button {
                HapticManager.shared.trigger(.lightImpact)
                
                let url = URL(string: "https://play.google.com/store/apps/details?id=com.smartsolutions.servicemaps")
                let av = UIActivityViewController(activityItems: [url!], applicationActivities: nil)
                
                UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    av.popoverPresentationController?.sourceView = UIApplication.shared.windows.first
                    av.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2.1, y: UIScreen.main.bounds.height / 1.3, width: 200, height: 200)
                }
            } label: {
                Image("android")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(.vertical, -70)
                
            }
            
            Text("iOS")
                .font(.title3)
                .lineLimit(10)
                .foregroundColor(.primary)
                .fontWeight(.heavy)
            
            Button {
                HapticManager.shared.trigger(.lightImpact)
                let url = URL(string: "https://apps.apple.com/us/app/service-maps/id1664309103?l=fr-FR")
                let av = UIActivityViewController(activityItems: [url!], applicationActivities: nil)
                
                UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    av.popoverPresentationController?.sourceView = UIApplication.shared.windows.first
                    av.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2.1, y: UIScreen.main.bounds.height / 1.3, width: 200, height: 200)
                }
            } label: {
                Image("ios")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(.vertical, -70)
            }
            
            CustomBackButton(showImage: false, text: "Dismiss") {
                HapticManager.shared.trigger(.lightImpact)
                withAnimation {
                    self.viewModel.showSharePopup = false
                    dismiss()
                }
            }.hSpacing(.trailing)
                .padding(.top, 10)//.keyboardShortcut("\r", modifiers: [.command, .shift])
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
                    HapticManager.shared.trigger(.lightImpact)
                    withAnimation {
                        self.viewModel.showDeletionConfirmationAlert = false
                        PopupManager.dismissAll()
                    }
                }.hSpacing(.trailing)//.keyboardShortcut("\r", modifiers: [.command, .shift])
                CustomButton(loading: viewModel.loading, title: NSLocalizedString("Delete", comment: ""), color: .red, action: {
                    HapticManager.shared.trigger(.lightImpact)
                    withAnimation { self.viewModel.loading = true }
                    Task {
                        switch await AuthenticationManager().deleteAccount() {
                        case .success(_):
                            HapticManager.shared.trigger(.success)
                            withAnimation { self.viewModel.loading = false }
                            
                            self.viewModel.showDeletionConfirmationAlert = false
                            dismiss()
                            if showBack {
                                onDone()
                            }
                        case .failure(_):
                            HapticManager.shared.trigger(.error)
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
                    HapticManager.shared.trigger(.lightImpact)
                    self.viewModel.showDeletionAlert = false
                    dismiss()
                }.hSpacing(.trailing)//.keyboardShortcut("\r", modifiers: [.command, .shift])
                CustomButton(loading: viewModel.loading, title: NSLocalizedString("Delete", comment: ""), color: .red, action: {
                    HapticManager.shared.trigger(.lightImpact)
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
            
            if !error.isEmpty {
                Text(error)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
            
            HStack {
                if !loading {
                    CustomBackButton() {
                        HapticManager.shared.trigger(.lightImpact)
                        dismiss()
                        self.viewModel.showEditNamePopup = false
                    }
                }
                
                CustomButton(loading: loading, title: "Edit") {
                    HapticManager.shared.trigger(.lightImpact)
                    if !username.isEmpty {
                        withAnimation { loading = true }
                        
                        Task {
                            let result = await viewModel.editUserName(name: username)
                            
                            switch result {
                            case .success(_):
                                HapticManager.shared.trigger(.success)
                                withAnimation { loading = false }
                                dismiss()
                                self.viewModel.showEditNamePopup = false
                            case .failure(let error):
                                HapticManager.shared.trigger(.error)
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
        .onAppear {
            usernameFocus = true // Focus on the text field when the view appears
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    HapticManager.shared.trigger(.lightImpact)
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

struct BottomPopup_Document: BottomPopup {
    @ObservedObject var viewModel: SettingsViewModel
    
    func configurePopup(popup: BottomPopupConfig) -> BottomPopupConfig {
        popup
            .contentFillsWholeHeigh(true)
            .dragGestureEnabled(false)
    }
    func createContent() -> some View {
        VStack(spacing: 0) {
            createBar()
            Spacer.height(24)
            createScrollView()
            Spacer()
            createConfirmButton()
        }
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
}

private extension BottomPopup_Document {
    func createBar() -> some View {
        Capsule()
            .fill(Color.onBackgroundTertiary)
            .frame(width: 32, height: 6)
            .hSpacing(.center)
    }
    func createScrollView() -> some View {
        //VStack {
        PrivacyPolicy(sheet: true)
        //}
    }
    func createConfirmButton() -> some View {
        Button {
            HapticManager.shared.trigger(.lightImpact)
            dismiss()
            viewModel.presentPolicy = false
        } label: {
            Text("Dismiss")
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundColor(.white)
                .frame(height: 44)
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(40)
                .padding(.horizontal, 28)
        }
    }
}

private extension BottomPopup_Document {
    func createScrollViewText(_ text: String) -> some View {
        Text(text)
            .font(.interRegular(16))
            .foregroundColor(.onBackgroundPrimary)
    }
}
