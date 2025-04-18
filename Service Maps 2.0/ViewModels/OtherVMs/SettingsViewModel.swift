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
        VStack {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 75, height: 75)
                
                VStack {
                    Text(dataStore.userName ?? "NO USERNAME")
                        .font(.headline)
                        .lineLimit(4)
                        .foregroundColor(.primary)
                        .fontWeight(.heavy)
                        .hSpacing(.leading)
                        
                    Text(dataStore.userEmail ?? "NO EMAIL")
                        .font(.subheadline)
                        .lineLimit(4)
                        .foregroundColor(.primary)
                        .fontWeight(.heavy)
                        .hSpacing(.leading)
                }
            }
            
            CustomButton(loading: loading, title: NSLocalizedString("Logout", comment: "")) {
                HapticManager.shared.trigger(.lightImpact)
                Task {
                    let result = await self.authenticationManager.logout()
                    switch result {
                    case .success(_):
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
            
            if errorText != "" {
                Text(errorText)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .vSpacing(.bottom)
            }
        }.padding(.bottom)
            .frame(maxWidth: .infinity)
    }
    
    // MARK: - Phone Login Cell
    
    @ViewBuilder
    func phoneLoginInfoCell(mainWindowSize: CGSize, showBack: Bool, onDone: @escaping () -> Void?) -> some View {
        VStack {
            HStack {
                if AuthorizationLevelManager().existsPhoneCredentials() {
                    VStack {
                        HStack {
                            VStack {
                                Text("Phone Book")
                                    .font(.title3)
                                    .lineLimit(4)
                                    .foregroundColor(.primary)
                                    .fontWeight(.heavy)
                                    .hSpacing(.leading)
                                HStack {
                                    Image(systemName: "house.lodge.fill")
                                    
                                    Text("\(dataStore.phoneCongregationName!)")
                                        .font(.headline)
                                        .lineLimit(4)
                                        .foregroundColor(.primary)
                                        .fontWeight(.heavy)
                                        .hSpacing(.leading)
                                    CustomBackButton(showImage: false, text: NSLocalizedString("Exit", comment: "")) {
                                        HapticManager.shared.trigger(.success)

                                        // Immediate log and UI update
                                        Task {
                                            await MainActor.run {
                                                self.exitPhoneLogin() // Immediate UI update
                                            }
                                            Task {
                                                DispatchQueue.main.async {
                                                    self.synchronizationManager.startupProcess(synchronizing: true)
                                                }
                                            }
                                        }
                                    }
                                    .frame(maxWidth: 120)
                                    .hSpacing(.trailing)
                                }
                            }
                        }
                    }
                } else {
                    HStack {
                        HStack {
                            Image(systemName: "book.pages.fill")
                                .imageScale(.large)
                                .padding(.horizontal)
                            Text("Log into Phone Book")
                                .font(.title3)
                                .lineLimit(2)
                                .foregroundColor(.primary)
                                .fontWeight(.heavy)
                        }
                        .hSpacing(.leading)
                        Spacer()
                        Image(systemName: "arrowshape.right.circle.fill")
                            .imageScale(.large)
                            .padding(.horizontal)
                    }
                }
            }.onTapGesture {
                HapticManager.shared.trigger(.lightImpact)
                self.phoneBookLogin = true
            }
            .padding(10)
            .frame(minWidth: mainWindowSize.width * 0.95, minHeight: 75)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }.padding(.bottom).frame(maxWidth: .infinity)
    }
    
    // MARK: - Administrator Info Cell
    
    @ViewBuilder
    func administratorInfoCell(mainWindowSize: CGSize, showBack: Bool, onDone: @escaping () -> Void?) -> some View {
        VStack {
            HStack {
                if dataStore.congregationName != nil {
                    VStack {
                        HStack {
                            VStack {
                                Text("Administrator")
                                    .font(.title3)
                                    .lineLimit(2)
                                    .foregroundColor(.primary)
                                    .fontWeight(.heavy)
                                    .hSpacing(.leading)
                                HStack {
                                    Image(systemName: "house.lodge.fill")
                                    
                                    Text("\(dataStore.congregationName!)")
                                        .font(.headline)
                                        .lineLimit(2)
                                        .foregroundColor(.primary)
                                        .fontWeight(.heavy)
                                        .hSpacing(.leading)
                                    CustomBackButton(showImage: false, text: NSLocalizedString("Exit", comment: "")) {
                                        HapticManager.shared.trigger(.success)
                                        Task {
                                            await MainActor.run {
                                                self.exitAdministrator() // Immediate UI update
                                            }
                                            Task {
                                                DispatchQueue.main.async {
                                                    self.synchronizationManager.startupProcess(synchronizing: true)
                                                }
                                            }
                                        }
                                        if showBack {
                                            onDone()
                                        }
                                    }
                                    .frame(maxWidth: 120)
                                    .hSpacing(.trailing)
                                }
                            }
                            
                            
                        }
                    }
                } else {
                    HStack {
                        HStack {
                            Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                                .imageScale(.large)
                                .padding(.horizontal)
                            Text("Become Administrator")
                                .font(.title3)
                                .lineLimit(2)
                                .foregroundColor(.primary)
                                .fontWeight(.heavy)
                        }
                        .hSpacing(.leading)
                        Spacer()
                        Image(systemName: "arrowshape.right.circle.fill")
                            .imageScale(.large)
                            .padding(.horizontal)
                    }
                    //.padding(.horizontal)
                }
            }.onTapGesture {
                HapticManager.shared.trigger(.lightImpact)
                self.presentSheet = true
            }
            .padding(10)
            .frame(minWidth: mainWindowSize.width * 0.95, minHeight: 75)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }.padding(.bottom).frame(maxWidth: .infinity)
    }
    
    // MARK: - Infos View
    
    @ViewBuilder
    func infosView(mainWindowSize: CGSize) -> some View {
        VStack {
            
            Button {
                HapticManager.shared.trigger(.lightImpact)
                self.showSharePopup = true
            } label: {
                HStack {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .imageScale(.large)
                            .padding(.horizontal)
                        Text("Share App")
                            .font(.title3)
                            .lineLimit(2)
                            .foregroundColor(.primary)
                            .fontWeight(.heavy)
                    }
                    .hSpacing(.leading)
                }
            }
            .frame(minHeight: 50)
            
            Button {
                HapticManager.shared.trigger(.lightImpact)
                self.presentPolicy = true
            } label: {
                HStack {
                    HStack {
                        Image(systemName: "hand.raised.circle")
                            .imageScale(.large)
                            .padding(.horizontal)
                        Text("Privacy Policy")
                            .font(.title3)
                            .lineLimit(2)
                            .foregroundColor(.primary)
                            .fontWeight(.heavy)
                    }
                    .hSpacing(.leading)
                }
            }
            .frame(minHeight: 50)
            
            
            Button {
                HapticManager.shared.trigger(.lightImpact)
                self.requestReview = true
            } label: {
                HStack {
                    HStack {
                        Image(systemName: "star.fill")
                            .imageScale(.large)
                            .padding(.horizontal)
                        Text("Review App")
                            .font(.title3)
                            .lineLimit(2)
                            .foregroundColor(.primary)
                            .fontWeight(.heavy)
                    }
                    .hSpacing(.leading)
                }
            }
            .frame(minHeight: 50)
            
            Button {
                HapticManager.shared.trigger(.lightImpact)
                self.showAlert = true
                
            } label: {
                HStack {
                    HStack {
                        Image(systemName: "info.circle")
                            .imageScale(.large)
                            .padding(.horizontal)
                        Text("About App")
                            .font(.title3)
                            .lineLimit(2)
                            .foregroundColor(.primary)
                            .fontWeight(.heavy)
                    }
                    .hSpacing(.leading)
                }
            }
            .frame(minHeight: 50)
            
            Button {
                HapticManager.shared.trigger(.lightImpact)
                do {
                    try isUpdateAvailable { [self] (update, error) in
                        if let update {
                            if update {
                                DispatchQueue.main.async {
                                    self.showUpdateToastMessage = NSLocalizedString("Update available. Redirecting to App Store...", comment: "")
                                    self.showUpdateToast = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    UIApplication.shared.open(URL(string: "https://apps.apple.com/us/app/service-maps/id1664309103")!)
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.showUpdateToastMessage = NSLocalizedString("App is up to date!", comment: "")
                                    self.showUpdateToast = true
                                }
                            }
                        }
                       
                       if let error {
                           if error.localizedDescription == NSLocalizedString("The operation couldn’t be completed. (NSURLErrorDomain error -1009.)", comment: "") {
                               DispatchQueue.main.async {
                                   self.showUpdateToastMessage = NSLocalizedString("No internet connection", comment: "")
                                   self.showUpdateToast = true
                               }
                           } else {
                               DispatchQueue.main.async {
                                   self.showUpdateToastMessage = error.localizedDescription
                                   self.showUpdateToast = true
                               }
                           }
                       }
                    }
                } catch {
                    HapticManager.shared.trigger(.error)
                        self.showUpdateToastMessage = error.localizedDescription
                        self.showUpdateToast = true
                }
                
            } label: {
                HStack {
                    HStack {
                        Image(systemName: "app")
                            .imageScale(.large)
                            .padding(.horizontal)
                        Text("App Version")
                            .font(.title3)
                            .lineLimit(2)
                            .foregroundColor(.primary)
                            .fontWeight(.heavy)
                    }
                    .hSpacing(.leading)
                    
                    
                    HStack {
                        Text("\(getAppVersion())")
                            .font(.headline)
                            .lineLimit(2)
                            .foregroundColor(.primary)
                            .fontWeight(.heavy)
                            .padding(.trailing)
                    }
                    .hSpacing(.trailing)
                    .frame(maxWidth: 70)
                }
            }
            .frame(minHeight: 50)
        }
        .padding(10)
        .frame(minWidth: mainWindowSize.width * 0.95)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                HStack {
                    HStack {
                        Image(systemName: "trash.circle")
                            .imageScale(.large)
                            .padding(.horizontal)
                        Text("Delete Cache")
                            .font(.title3)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                            .fontWeight(.heavy)
                    }
                    .hSpacing(.leading)
                }
            }
            .frame(minHeight: 50)
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
                HStack {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.xmark")
                            .imageScale(.large)
                            .padding(.horizontal)
                            .foregroundColor(.red)
                        Text("Delete Account")
                            .font(.title3)
                            .lineLimit(1)
                            .fontWeight(.heavy)
                            .foregroundColor(.red)
                    }
                    .hSpacing(.leading)
                }
            }
            .frame(minHeight: 50)
        }
        .padding(10)
        .frame(minWidth: mainWindowSize.width * 0.95)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Expand Enum
enum ExpandCollapseAction: String, CaseIterable, Identifiable {
    case expandAll = "Expand"
    case collapseAll = "Collapse"
    case none = ""
    
    var id: String { self.rawValue }
}
