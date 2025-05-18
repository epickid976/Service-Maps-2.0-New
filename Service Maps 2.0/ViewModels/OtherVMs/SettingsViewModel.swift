//
//  SettingsViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/24/24.
//

import Foundation
import SwiftUI
import Nuke
import AlertKit
import StoreKit

// MARK: - SettingsViewModel

@MainActor
class SettingsViewModel: ObservableObject {
    
    // MARK: - Dependencies
    
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var authenticationManager = AuthenticationManager()
    @ObservedObject var authorizationProvider = AuthorizationProvider.shared
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    @ObservedObject private var viewModel = ColumnViewModel()
    
    // MARK: - Properties
    
    @Published var backAnimation = false
    @Published var progress: CGFloat = 0.0
    
    @Published var loading = false
    @Published var alwaysLoading = true
    @Published var backingUp = false
    @Published var errorText = ""
    @Published var deletionError = ""
    
    @Published var showSharePopup = false
    @Published var selectedAction: ExpandCollapseAction = .none // Track picker state
    
    @Published var syncAnimation = false
    @Published var syncAnimationprogress: CGFloat = 0.0
    
    @Published var presentSheet = false
    @Published var phoneBookLogin = false
    @Published var presentPolicy = false
    @Published var showAlert = false
    @Published var showDeletionAlert = false
    @Published var showDeletionConfirmationAlert = false
    
    @Published var showToast = false
    
    @Published var showUpdateToast = false
    @Published var showUpdateToastMessage = ""
    
    @Published var showEditNamePopup = false
    
    @Published var requestReview = false
    
    // MARK: - Get Functions
    func getCongregationName() -> String{
        return dataStore.congregationName ?? ""
    }
    
    func exitAdministrator() {
        authenticationManager.exitAdministrator()
    }
    
    func exitPhoneLogin() {
        authenticationManager.exitPhoneLogin()
    }
    
    // MARK: - Edit User
    func editUserName(name: String) async -> Result<Bool, Error> {
        let result = await authenticationManager.editUserName(userName: name)
        
        switch result {
        case .success:
            dataStore.userName = name
            return Result.success(true)
        case .failure(let failure):
            return Result.failure(failure)
        }
    }
    
    // MARK: - UI ViewBuilder Functions
    /// Settings View to deload actual view
    
    // MARK: - Profile View
    
    @ViewBuilder
    func profile(showBack: Bool, onDone: @escaping () -> Void?) -> some View {
        VStack(spacing: 16) {
            // MARK: - User Icon + Info
            HStack(spacing: 16) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 75, height: 75)
                    .foregroundColor(.blue)
                    .padding(6)
                    .background(Material.ultraThin)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(dataStore.userName ?? "NO USERNAME")
                        .font(.title3)
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(dataStore.userEmail ?? "NO EMAIL")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // MARK: - Logout Button
            CustomButton(loading: loading, title: NSLocalizedString("Logout", comment: "")) {
                HapticManager.shared.trigger(.lightImpact)
                Task {
                    let result = await self.authenticationManager.logout()
                    switch result {
                    case .success:
                        HapticManager.shared.trigger(.success)
                        self.exitAdministrator()
                        if showBack {
                            onDone()
                        }
                        SynchronizationManager.shared.startupProcess(synchronizing: false)
                        
                    case .failure(let error):
                        HapticManager.shared.trigger(.error)
                        self.errorText = error.asAFError?.localizedDescription ?? ""
                    }
                }
            }
            
            // MARK: - Error Message
            if !errorText.isEmpty {
                Text(errorText)
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Material.thin)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 5)
    }
    
    // MARK: - Phone Login Cell
    
    @ViewBuilder
    func phoneLoginInfoCell(mainWindowSize: CGSize, showBack: Bool, onDone: @escaping () -> Void?) -> some View {
        Button {
            HapticManager.shared.trigger(.lightImpact)
            self.phoneBookLogin = true
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                // Title with Icon
                HStack(spacing: 8) {
                    Image(systemName: AuthorizationLevelManager().existsPhoneCredentials() ? "book.pages.fill" : "book.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blue)
                    
                    Text("Phone Book")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                // Content below title – either info or tap prompt
                Group {
                    if AuthorizationLevelManager().existsPhoneCredentials(),
                       let name = dataStore.phoneCongregationName {
                        HStack(spacing: 8) {
                            Image(systemName: "house.lodge.fill")
                                .foregroundColor(.secondary)
                                .imageScale(.small)
                            
                            Text(name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            CustomBackButton(showImage: false, text: NSLocalizedString("Exit", comment: "")) {
                                HapticManager.shared.trigger(.success)
                                Task {
                                    await MainActor.run { self.exitPhoneLogin() }
                                    DispatchQueue.main.async {
                                        self.synchronizationManager.startupProcess(synchronizing: true)
                                    }
                                }
                            }
                            .frame(maxWidth: 100)
                        }
                    } else {
                        Text("Tap to log in")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading) // Consistent width
            }
            .padding()
            .frame(minWidth: mainWindowSize.width * 0.95, minHeight: 75)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .animation(.spring(), value: AuthorizationLevelManager().existsPhoneCredentials())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Administrator Info Cell
    
    @ViewBuilder
    func administratorInfoCell(mainWindowSize: CGSize, showBack: Bool, onDone: @escaping () -> Void?) -> some View {
        Button {
            HapticManager.shared.trigger(.lightImpact)
            self.presentSheet = true
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                // Title with Icon
                HStack(spacing: 8) {
                    Image(systemName: dataStore.congregationName != nil ? "shield.lefthalf.filled.badge.checkmark" : "shield.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blue)
                    
                    Text("Administrator")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                // Content below title – either info or tap prompt
                Group {
                    if let name = dataStore.congregationName {
                        HStack(spacing: 8) {
                            Image(systemName: "house.lodge.fill")
                                .foregroundColor(.secondary)
                                .imageScale(.small)
                            
                            Text(name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            CustomBackButton(showImage: false, text: NSLocalizedString("Exit", comment: "")) {
                                HapticManager.shared.trigger(.success)
                                Task {
                                    await MainActor.run {
                                        self.exitAdministrator()
                                    }
                                    DispatchQueue.main.async {
                                        self.synchronizationManager.startupProcess(synchronizing: true)
                                    }
                                }
                                if showBack {
                                    onDone()
                                }
                            }
                            .frame(maxWidth: 100)
                        }
                    } else {
                        Text("Tap to become administrator")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading) // <-- Ensures layout stays stable
            }
            .padding()
            .frame(minWidth: mainWindowSize.width * 0.95, minHeight: 75)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .animation(
                .spring(),
                value: AuthorizationLevelManager().existsAdminCredentials()
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Infos View
    
    @ViewBuilder
    func infosView(mainWindowSize: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Info")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
                .padding(.leading, 5)
            
            VStack(spacing: 0) {
                infoRow(
                    icon: "square.and.arrow.up",
                    title: "Share App"
                ) {
                    self.showSharePopup = true
                }
                
                infoRow(
                    icon: "hand.raised.circle",
                    title: "Privacy Policy"
                ) {
                    self.presentPolicy = true
                }
                
                infoRow(
                    icon: "star.fill",
                    title: "Review App"
                ) {
                    self.requestReview = true
                }
                
                infoRow(
                    icon: "info.circle",
                    title: "About App"
                ) {
                    self.showAlert = true
                }
                
                infoRowWithTrailing(
                    icon: "app",
                    title: "App Version",
                    trailingText: getAppVersion()
                ) {
                    do {
                        try isUpdateAvailable { update, error in
                            if let update {
                                DispatchQueue.main.async {
                                    self.showUpdateToastMessage = update
                                    ? NSLocalizedString("Update available. Redirecting to App Store...", comment: "")
                                    : NSLocalizedString("App is up to date!", comment: "")
                                    self.showUpdateToast = true
                                }
                                
                                if update {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        UIApplication.shared.open(
                                            URL(string: "https://apps.apple.com/us/app/service-maps/id1664309103")!
                                        )
                                    }
                                }
                            }
                            
                            if let error {
                                let message = error.localizedDescription == NSLocalizedString("The operation couldn’t be completed. (NSURLErrorDomain error -1009.)", comment: "")
                                ? NSLocalizedString("No internet connection", comment: "")
                                : error.localizedDescription
                                
                                DispatchQueue.main.async {
                                    self.showUpdateToastMessage = message
                                    self.showUpdateToast = true
                                }
                            }
                        }
                    } catch {
                        self.showUpdateToastMessage = error.localizedDescription
                        self.showUpdateToast = true
                    }
                }
            }
            .padding(10)
            .frame(minWidth: mainWindowSize.width * 0.95)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .frame(minWidth: mainWindowSize.width * 0.95)
    }
    
    // MARK: - Delete Cache Menu
    
    @ViewBuilder
    func deleteCacheMenu(mainWindowSize: CGSize) -> some View {
        VStack {
            Button {
                HapticManager.shared.trigger(.success)
                ImagePipeline.shared.cache.removeAll()
                DataLoader.sharedUrlCache.removeAllCachedResponses()
                self.showToast = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "trash.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.red)
                    
                    Text("Delete Cache")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(10)
        .frame(minWidth: mainWindowSize.width * 0.95)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Delete Account Menu
    
    @ViewBuilder
    func deleteAccount(mainWindowSize: CGSize) -> some View {
        VStack {
            Button {
                HapticManager.shared.trigger(.lightImpact)
                self.showDeletionAlert = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.red)
                    
                    Text("Delete Account")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(10)
        .frame(minWidth: mainWindowSize.width * 0.95)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private func infoRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.shared.trigger(.lightImpact)
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.blue)
                
                Text(NSLocalizedString(title, comment: ""))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .imageScale(.small)
            }
            .padding(.vertical, 15)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func infoRowWithTrailing(icon: String, title: String, trailingText: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.shared.trigger(.lightImpact)
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.blue)
                
                Text(NSLocalizedString(title, comment: ""))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(trailingText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 15)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Expand Enum
enum ExpandCollapseAction: String, CaseIterable, Identifiable {
    case expandAll = "Expand"
    case collapseAll = "Collapse"
    case none = ""
    
    var id: String { self.rawValue }
}
