//
//  SettingsView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/7/23.
//

import SwiftUI
import NavigationTransitions
import AlertKit
import MijickPopups
import Lottie

//MARK: - SettingsView

struct SettingsView: View {
    
    //MARK: - Environment
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.sizeCategory) var sizeCategory
    @Environment(\.requestReview) var requestReview
    @Environment(\.mainWindowSize) var mainWindowSize
    
    //MARK: - Dependencies
    
    @ObservedObject var viewModel = SettingsViewModel()
    let authenticationManager = AuthenticationManager()
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @StateObject private var preferencesViewModel = ColumnViewModel()
    
    //MARK: - Properties
    
    @State var loading = false
    @State var alwaysLoading = true
    @State var backingUp = false
    var showBackButton = false
    @State private var isExpanding = false
    @State private var isCollapsing = false
    
    //MARK: - Alert Views
    
    let alertViewDeleted = AlertAppleMusic17View(title: "Cache Deleted", subtitle: nil, icon: .custom(UIImage(systemName: "trash")!))
    
    //MARK: - Initializers
    
    init(showBackButton: Bool = false) {
        self.showBackButton = showBackButton
    }
    
    //MARK: - Body
    
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
                //viewModel.languageLinkView(mainWindowSize: mainWindowSize)
                //Spacer().frame(height: 25)
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
                    Task {
                        await CenterPopup_AboutApp(viewModel: viewModel, usingLargeText: sizeCategory == .large || sizeCategory == .extraLarge ? false : true).present()
                    }
                }
            }
            .alert(isPresent: $viewModel.showUpdateToast, view: alertUpdate)
            .onChange(of: viewModel.showDeletionConfirmationAlert) { value in
                if value {
                    Task {
                        await CenterPopup_DeletionConfirmation(viewModel: viewModel, usingLargeText: sizeCategory == .large || sizeCategory == .extraLarge ? false : true, showBack: showBackButton, onDone: { presentationMode.wrappedValue.dismiss() }).present()
                    }
                }
            }
            .onChange(of: viewModel.showSharePopup) { value in
                if value {
                    Task {
                        await CenterPopup_ShareApp(viewModel: viewModel, usingLargeText: sizeCategory == .large || sizeCategory == .extraLarge ? false : true).present()
                    }
                }
            }
            .onChange(of: viewModel.showDeletionAlert) { value in
                if value {
                    Task {
                        await  CenterPopup_Deletion(viewModel: viewModel, usingLargeText: sizeCategory == .large || sizeCategory == .extraLarge ? false : true).present()
                    }
                }
            }
            
            .onChange(of: viewModel.showEditNamePopup) { value in
                if value {
                    Task {
                        await CenterPopup_EditUsername(viewModel: viewModel).present()
                    }
                }
            }
            
            .fullScreenCover(isPresented: $viewModel.presentSheet) {
                AdminLoginView {
                    if showBackButton {
                        presentationMode.wrappedValue.dismiss()
                    }
                    Task {
                        // First complete startup process
                        synchronizationManager.startupProcess(synchronizing: true)
                        viewModel.presentSheet = false
                    }
                }
            }
            .sheet(isPresented: $viewModel.presentPolicy) {
                PrivacyPolicy(sheet: true)
                    .presentationDragIndicator(.visible)
                    .optionalViewModifier { content in
                        if #available(iOS 16.4, *) {
                            content
                                .presentationCornerRadius(25)
                        }
                    }
            }
            .padding()
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
                                Task {
                                    await dismissAllPopups()
                                }
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
                    Button("", action: { viewModel.syncAnimation = true;  print("Syncing") ; synchronizationManager.startupProcess(synchronizing: true) })//.keyboardShortcut("s", modifiers: .command)
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
    
    //MARK: - Preferences View
    
    @ViewBuilder
    func preferencesView(mainWindowSize: CGSize) -> some View {
        VStack(spacing: 16) {
            // MARK: Language
            Button {
                HapticManager.shared.trigger(.lightImpact)
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            } label: {
                HStack {
                    // Icon container with consistent width
                    HStack(spacing: 0) {
                        Image(systemName: "globe")
                            .imageScale(.large)
                            .foregroundColor(.blue)
                            .frame(width: 30)
                    }
                    
                    // Title container
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Language")
                            .font(.title3)
                            .foregroundColor(.primary)
                            .fontWeight(.heavy)
                    }

                    Spacer()

                    // Action indicator (consistent width)
                    Image(systemName: "arrowshape.right.circle.fill")
                        .imageScale(.large)
                        .foregroundColor(.primary)
                        .frame(width: 44)
                }
                .padding(.horizontal)
            }
            .frame(minHeight: 50)

            // MARK: iPad Column View (Only for iPad)
            if UIDevice().userInterfaceIdiom == .pad {
                Button(action: {}) {
                    HStack {
                        // Icon container with consistent width
                        HStack(spacing: 0) {
                            Image(systemName: "text.word.spacing")
                                .imageScale(.large)
                                .foregroundColor(.blue)
                                .frame(width: 30)
                        }
                        
                        // Title container
                        VStack(alignment: .leading, spacing: 4) {
                            Text("iPad Column View")
                                .font(.title3)
                                .fontWeight(.heavy)
                                .foregroundColor(.primary)
                        }

                        Spacer()

                        // Toggle with fixed width
                        Toggle("", isOn: $preferencesViewModel.isColumnViewEnabled)
                            .labelsHidden()
                            .toggleStyle(CheckmarkToggleStyle(color: .blue))
                            .frame(width: 44)
                    }
                    .padding(.horizontal)
                }
                .frame(minHeight: 50)
            }

            // MARK: Haptics (Only for iPhone)
            if UIDevice().userInterfaceIdiom != .pad {
                Button(action: {}) {
                    HStack {
                        // Icon container with consistent width
                        HStack(spacing: 0) {
                            Image(systemName: "iphone.radiowaves.left.and.right")
                                .imageScale(.large)
                                .foregroundColor(.blue)
                                .frame(width: 30)
                        }
                        
                        // Title container
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Haptics")
                                .font(.title3)
                                .fontWeight(.heavy)
                                .foregroundColor(.primary)
                        }

                        Spacer()

                        // Toggle with fixed width
                        Toggle("", isOn: $preferencesViewModel.hapticFeedback)
                            .labelsHidden()
                            .toggleStyle(CheckmarkToggleStyle(color: .blue))
                            .frame(width: 44)
                    }
                    .padding(.horizontal)
                }
                .frame(minHeight: 50)
            }

            // MARK: Disclosure Groups
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    // Icon container with consistent width
                    HStack(spacing: 0) {
                        Image(systemName: "rectangle.stack.fill.badge.plus")
                            .imageScale(.large)
                            .foregroundColor(.blue)
                            .frame(width: 30)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Disclosure Groups")
                            .font(.title3)
                            .fontWeight(.heavy)
                            .foregroundColor(.primary)

                        Text("Expand or collapse all territory sections")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal)

                HStack(spacing: 12) {
                    // Expand Button
                    Button {
                        HapticManager.shared.trigger(.lightImpact)
                        viewModel.selectedAction = .expandAll
                        expandAllDisclosureGroups()
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isExpanding = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                isExpanding = false
                            }
                        }
                    } label: {
                        Text("Expand")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                            .opacity(isExpanding ? 0.5 : 1)
                            .scaleEffect(isExpanding ? 0.97 : 1)
                    }

                    // Collapse Button
                    Button {
                        HapticManager.shared.trigger(.lightImpact)
                        viewModel.selectedAction = .collapseAll
                        collapseAllDisclosureGroups()
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isCollapsing = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                isCollapsing = false
                            }
                        }
                    } label: {
                        Text("Collapse")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                            .opacity(isCollapsing ? 0.5 : 1)
                            .scaleEffect(isCollapsing ? 0.97 : 1)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(10)
        .frame(minWidth: mainWindowSize.width * 0.95)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    //MARK: - Backup View
    
    @ViewBuilder
    func backupView(mainWindowSize: CGSize) -> some View {
        VStack(spacing: 16) {
            Button {
                HapticManager.shared.trigger(.lightImpact)
                Task {
                    await CenterPopup_Backup(viewModel: viewModel, backingUp: $backingUp).present()
                }
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
    
    
    //MARK: - Helper Methods
    
    func expandAllDisclosureGroups() {
        // Fetch tokens (or other items) from your database
        let tokens = GRDBManager.shared.fetchAll(Token.self).getOrElse([])

        // Save expanded state for each token
        for token in tokens {
            let safeKey = token.name.replacingOccurrences(of: " ", with: "_")
            let storageKey = "expanded_\(safeKey)"
            UserDefaults.standard.set(true, forKey: storageKey)
        }

        // Save expanded state for "Other Territories"
        UserDefaults.standard.set(true, forKey: "expanded_OtherTerritories")
        UserDefaults.standard.synchronize()
    }

    func collapseAllDisclosureGroups() {
        let tokens = GRDBManager.shared.fetchAll(Token.self).getOrElse([])

        for token in tokens {
            let safeKey = token.name.replacingOccurrences(of: " ", with: "_")
            let storageKey = "expanded_\(safeKey)"
            UserDefaults.standard.set(false, forKey: storageKey)
        }

        UserDefaults.standard.set(false, forKey: "expanded_OtherTerritories")
        UserDefaults.standard.synchronize()
    }
    
    func handlePickerAction(action: ExpandCollapseAction) {
        switch action {
        case .expandAll:
            expandAllDisclosureGroups()
        case .collapseAll:
            collapseAllDisclosureGroups()
        case .none:
            break // No action for the "none" case
        }
    }
}

//MARK: - About App Popup

struct CenterPopup_AboutApp: CenterPopup {
    @ObservedObject var viewModel: SettingsViewModel
    var usingLargeText: Bool

    var body: some View {
        createContent()
    }

    func createContent() -> some View {
        VStack(spacing: 16) {
            // MARK: - Icon
            Image(systemName: "info.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundColor(.blue)

            // MARK: - Title
            Text("About App")
                .font(.title2)
                .fontWeight(.heavy)
                .foregroundColor(.primary)

            // MARK: - Description
            Text("""
Service Maps has been created with the purpose of streamlining and facilitating the control and registration of the public preaching of Jehovah's Witnesses.

This tool is not part of JW.ORG nor is it an official app of the organization. It is simply the result of the effort and love of some brothers. We hope it is useful. Thank you for using Service Maps.
""")
            .font(usingLargeText ? .caption2 : .body)
            .foregroundColor(.primary)
            .lineSpacing(5)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 6)
            .frame(maxWidth: 500)

            // MARK: - Dismiss Button
            HStack {
                Spacer()
                CustomBackButton(showImage: false, text: "Dismiss") {
                    HapticManager.shared.trigger(.lightImpact)
                    withAnimation {
                        self.viewModel.showAlert = false
                    }
                    Task {
                        await dismissLastPopup()
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .padding(.vertical, 10)
        .background(Material.thin)
        .cornerRadius(20)
    }

    func configurePopup(config: CenterPopupConfig) -> CenterPopupConfig {
        config
            .popupHorizontalPadding(24)
    }
}

//MARK: - Backup Popup
struct CenterPopup_Backup: CenterPopup {
    @ObservedObject var viewModel: SettingsViewModel
    @State var error = ""
    @Binding var backingUp: Bool
    @State var backupUrl: URL?
    @State var shareBackup: Bool = false

    @ObservedObject var backupManager = BackupManager.shared

    var body: some View {
        createContent()
    }

    func createContent() -> some View {
        VStack(spacing: 16) {
            // MARK: - Header Icon
            if backupUrl != nil {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .foregroundColor(.green)
            } else if backingUp {
                Image(systemName: "gearshape.2.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .foregroundColor(.blue)
            } else {
                Image(systemName: "tray.and.arrow.down.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .foregroundColor(.blue)
            }

            Text("Backup")
                .font(.title2)
                .fontWeight(.heavy)
                .foregroundColor(.primary)

            // MARK: - Content
            if backingUp {
                LottieView(animation: .named("compresing"))
                    .playing(loopMode: .loop)
                    .resizable()
                    .frame(width: 200, height: 200)

                Text("Creating Backup...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ProgressView(value: backupManager.progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(height: 20)
                    .padding(.horizontal)
            } else if let backupUrl {
                HStack(spacing: 10) {
                    Image(systemName: "doc.zipper")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("File Created", comment: ""))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(backupUrl.lastPathComponent)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .fontWeight(.medium)
                    }
                }
                .padding(.vertical, 4)
            } else {
                Text("A backup copy of all the territories, addresses, houses, and visits that are in the app will be made. A zip file will be generated that will contain the folders and forms for each address. Please note that only the last visit will be exported. The process may take some time.")
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineSpacing(5)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)
                    .frame(maxWidth: 500)
            }

            // MARK: - Error Message
            if !error.isEmpty {
                Text(error)
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            // MARK: - Buttons
            HStack(spacing: 12) {
                CustomBackButton(showImage: true, text: NSLocalizedString("Cancel", comment: "")) {
                    HapticManager.shared.trigger(.lightImpact)
                    withAnimation {
                        self.viewModel.showDeletionConfirmationAlert = false
                        DispatchQueue.main.async {
                            BackupManager.shared.cancelBackup()
                        }
                        backingUp = false
                    }
                        Task {
                            await dismissAllPopups()
                        }
                    
                }
                .frame(maxWidth: .infinity)

                if let backupUrl {
                    CustomButton(
                        loading: shareBackup,
                        alwaysExpanded: true,
                        title: NSLocalizedString("Share Backup", comment: ""),
                        active: !viewModel.loading,
                        action: {
                            HapticManager.shared.trigger(.lightImpact)
                            presentActivityViewController(with: backupUrl)
                        }
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    CustomButton(
                        loading: backingUp,
                        alwaysExpanded: true,
                        title: NSLocalizedString("Back up", comment: ""),
                        active: !viewModel.loading,
                        action: {
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
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .padding(.vertical, 10)
        .background(Material.thin)
        .cornerRadius(20)
    }

    func configurePopup(config: CenterPopupConfig) -> CenterPopupConfig {
        config.popupHorizontalPadding(24)
    }

    func presentActivityViewController(with url: URL) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {

            rootVC.present(activityViewController, animated: true, completion: nil)

            if UIDevice.current.userInterfaceIdiom == .pad {
                activityViewController.popoverPresentationController?.sourceView = windowScene.windows.first
                activityViewController.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2.1, y: UIScreen.main.bounds.height / 1.3, width: 200, height: 200)
            }
        }
    }
}

//MARK: - Share Popup

struct CenterPopup_ShareApp: CenterPopup {
    @ObservedObject var viewModel: SettingsViewModel
    var usingLargeText: Bool
    
    var body: some View {
        createContent()
    }
    
    func createContent() -> some View {
        VStack(spacing: 16) {
            Text("Share Service Maps")
                .font(.title2)
                .fontWeight(.heavy)
                .foregroundColor(.primary)

            Divider()

            VStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image("androidLogo")
                        .resizable()
                        .frame(width: 24, height: 24)
                    Text("Android")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Button {
                    HapticManager.shared.trigger(.lightImpact)
                    shareApp(url: "https://play.google.com/store/apps/details?id=com.smartsolutions.servicemaps")
                } label: {
                    Image("android")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                }
            }

            VStack(spacing: 12) {
                Label("iOS", systemImage: "apple.logo")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Button {
                    HapticManager.shared.trigger(.lightImpact)
                    shareApp(url: "https://apps.apple.com/us/app/service-maps/id1664309103?l=fr-FR")
                } label: {
                    Image("ios")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                }
            }

            Divider()

            CustomBackButton(showImage: false, text: NSLocalizedString("Dismiss", comment: "")) {
                HapticManager.shared.trigger(.lightImpact)
                withAnimation {
                    self.viewModel.showSharePopup = false
                }
                Task {
                    await dismissLastPopup()
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top)
        }
        .padding()
        .background(Material.thin)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    func configurePopup(config: CenterPopupConfig) -> CenterPopupConfig {
        config
            .popupHorizontalPadding(24)
        
        
    }
    
    private func shareApp(url: String) {
        guard let link = URL(string: url) else { return }
        let av = UIActivityViewController(activityItems: [link], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            
            rootVC.present(av, animated: true, completion: nil)
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                av.popoverPresentationController?.sourceView = windowScene.windows.first
                av.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2.1, y: UIScreen.main.bounds.height / 1.3, width: 200, height: 200)
            }
        }
    }
}

//MARK: - Deletion Confirmation Popup

struct CenterPopup_DeletionConfirmation: CenterPopup {
    @ObservedObject var viewModel: SettingsViewModel
    var usingLargeText: Bool
    var showBack: Bool
    var onDone: () -> Void

    var body: some View {
        createContent()
    }

    func createContent() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "trash.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundColor(.red)

            Text("Are you sure you want to delete your account?")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text("This is irreversible.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if !viewModel.deletionError.isEmpty {
                Text(viewModel.deletionError)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .fontWeight(.semibold)
            }

            HStack(spacing: 12) {
                CustomBackButton(showImage: true, text: NSLocalizedString("Cancel", comment: "")) {
                    HapticManager.shared.trigger(.lightImpact)
                    withAnimation {
                        self.viewModel.showDeletionConfirmationAlert = false
                       
                    }
                    Task {
                        await dismissAllPopups()
                    }
                }
                .frame(maxWidth: .infinity)

                CustomButton(
                    loading: viewModel.loading,
                    title: NSLocalizedString("Delete", comment: ""),
                    color: .red
                ) {
                    HapticManager.shared.trigger(.lightImpact)
                    withAnimation { self.viewModel.loading = true }

                    Task {
                        switch await AuthenticationManager().deleteAccount() {
                        case .success(_):
                            HapticManager.shared.trigger(.success)
                            self.viewModel.loading = false
                            self.viewModel.showDeletionConfirmationAlert = false
                            await dismissAllPopups()
                            if showBack {
                                onDone()
                            }
                        case .failure(_):
                            HapticManager.shared.trigger(.error)
                            self.viewModel.loading = false
                            self.viewModel.deletionError = NSLocalizedString("Error deleting account", comment: "")
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

//MARK: - Deletion Popup

struct CenterPopup_Deletion: CenterPopup {
    @ObservedObject var viewModel: SettingsViewModel
    var usingLargeText: Bool

    var body: some View {
        createContent()
    }

    func createContent() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundColor(.orange)

            Text("Delete Account")
                .font(.title2)
                .fontWeight(.heavy)
                .foregroundColor(.primary)

            Text("""
Are you sure about deleting your account? This action cannot be undone. If you decide to delete your account, your account and all access granted to you will be deleted, but the information you have previously provided will remain on the server. The email used in this account cannot be reused again.
""")
                .font(usingLargeText ? .caption2 : .body)
                .foregroundColor(.primary)
                .lineSpacing(5)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 6)
                .frame(maxWidth: 500)

            HStack(spacing: 12) {
                CustomBackButton(showImage: true, text: NSLocalizedString("Cancel", comment: "")) {
                    HapticManager.shared.trigger(.lightImpact)
                    self.viewModel.showDeletionAlert = false
                    Task {
                        await dismissLastPopup()
                    }
                }
                .frame(maxWidth: .infinity)

                CustomButton(
                    loading: viewModel.loading,
                    title: NSLocalizedString("Delete", comment: ""),
                    color: .red
                ) {
                    HapticManager.shared.trigger(.lightImpact)
                    self.viewModel.showDeletionAlert = false
                    self.viewModel.showDeletionConfirmationAlert = true
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

//MARK: - Edit Username Popup

struct CenterPopup_EditUsername: CenterPopup {
    @ObservedObject var viewModel: SettingsViewModel
    @FocusState private var usernameFocus: Bool
    @State var username = StorageManager.shared.userName ?? ""
    
    @State var error = ""
    @State var loading = false
    
    init(
        viewModel: SettingsViewModel,
        usernameFocus: Bool = true,
        username: String = StorageManager.shared.userName ?? "",
        error: String = "",
        loading: Bool = false
    ) {
        self.viewModel = viewModel
        self.usernameFocus = usernameFocus
        self.username = username
        self.error = error
        self.loading = loading
    }

    var body: some View {
        createContent()
    }

    func createContent() -> some View {
        VStack(spacing: 16) {
            // MARK: - Icon
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundColor(.blue)

            // MARK: - Title
            Text("Edit Username")
                .font(.title2)
                .fontWeight(.heavy)
                .foregroundColor(.primary)

            // MARK: - Input Field
            CustomField(
                text: $username,
                isFocused: $usernameFocus,
                textfield: true,
                textfieldAxis: .vertical,
                placeholder: NSLocalizedString("New Username", comment: "")
            )

            if !error.isEmpty {
                Text(error)
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            // MARK: - Buttons
            HStack(spacing: 12) {
                if !loading {
                    CustomBackButton(showImage: true, text: NSLocalizedString("Cancel", comment: "")) {
                        HapticManager.shared.trigger(.lightImpact)
                        Task {
                            await dismissLastPopup()
                        }
                        self.viewModel.showEditNamePopup = false
                    }
                    .frame(maxWidth: .infinity)
                }

                CustomButton(
                    loading: loading,
                    title: NSLocalizedString("Edit", comment: ""),
                    active: !username.isEmpty
                ) {
                    HapticManager.shared.trigger(.lightImpact)
                    if !username.isEmpty {
                        withAnimation { loading = true }
                        Task {
                            let result = await viewModel.editUserName(name: username)
                            switch result {
                            case .success(_):
                                HapticManager.shared.trigger(.success)
                                withAnimation { loading = false }
                                await dismissLastPopup()
                                self.viewModel.showEditNamePopup = false
                            case .failure(_):
                                HapticManager.shared.trigger(.error)
                                withAnimation {
                                    loading = false
                                    self.error = NSLocalizedString("Error updating username", comment: "")
                                }
                            }
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

//MARK: - Privacy Policy Sheet

struct BottomPopup_Document: BottomPopup {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        createContent()
            .frame(height: 500)
    }
    func configurePopup(popup: BottomPopupConfig) -> BottomPopupConfig {
        popup
            .heightMode(.auto)
            .tapOutsideToDismissPopup(false)
            .enableDragGesture(false)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        ScrollView {
            VStack {
                PrivacyPolicy(sheet: true)
            }
            .padding(.horizontal, 16)
        }
        .frame(maxHeight: .infinity)  // Allow the ScrollView to take the available space
    }
    func createConfirmButton() -> some View {
        Button {
            HapticManager.shared.trigger(.lightImpact)
            Task {
                await dismissLastPopup()
            }
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

//MARK: - Preview

#Preview {
    SettingsView()
}
