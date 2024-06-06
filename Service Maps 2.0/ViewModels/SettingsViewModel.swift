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

@MainActor
class SettingsViewModel: ObservableObject {
    
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var authenticationManager = AuthenticationManager()
    @ObservedObject var authorizationProvider = AuthorizationProvider.shared
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    @Published var backAnimation = false
    @Published var progress: CGFloat = 0.0
    
    @State var loading = false
    @State var alwaysLoading = true
    
    @Published var errorText = ""
    @Published var deletionError = ""
    
    func getCongregationName() -> String{
        return dataStore.congregationName ?? ""
    }
    
    func exitAdministrator() {
        authenticationManager.exitAdministrator()
    }
    
    func exitPhoneLogin() {
        authenticationManager.exitPhoneLogin()
    }
    
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
            
            Text(errorText)
                .fontWeight(.bold)
                .foregroundColor(.red)
                .vSpacing(.bottom)
            
            
            CustomButton(loading: loading, title: NSLocalizedString("Logout", comment: "")) {
                Task {
                    let result = await self.authenticationManager.logout()
                    switch result {
                    case .success(_):
                        self.exitAdministrator()
                        if showBack {
                            onDone()
                        }
                        SynchronizationManager.shared.startupProcess(synchronizing: false)
                        
                        
                    case .failure(let error):
                        print("logout failed")
                        self.errorText = error.asAFError?.localizedDescription ?? ""
                    }
                }
            }
        }.padding(.bottom)
            .frame(maxWidth: .infinity)
    }
    
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
                                        self.exitPhoneLogin()
                                        if showBack {
                                            onDone()
                                        }
                                        self.synchronizationManager.startupProcess(synchronizing: true)
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
                    }.onTapGesture {
                        self.phoneBookLogin = true
                    }
                    //.padding(.horizontal)
                }
            }
            .padding(10)
            .frame(minWidth: mainWindowSize.width * 0.95, minHeight: 75)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }.padding(.bottom).frame(maxWidth: .infinity)
    }
    
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
                                        self.exitAdministrator()
                                        self.synchronizationManager.startupProcess(synchronizing: true)
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
                    }.onTapGesture {
                        self.presentSheet = true
                    }
                    //.padding(.horizontal)
                }
            }
            .padding(10)
            .frame(minWidth: mainWindowSize.width * 0.95, minHeight: 75)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }.padding(.bottom).frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    func infosView(mainWindowSize: CGSize) -> some View {
        VStack {
            Button {
                let url = URL(string: "https://apps.apple.com/us/app/service-maps/id1664309103?l=fr-FR")
                let av = UIActivityViewController(activityItems: [url!], applicationActivities: nil)
                
                UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    av.popoverPresentationController?.sourceView = UIApplication.shared.windows.first
                    av.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2.1, y: UIScreen.main.bounds.height / 1.3, width: 200, height: 200)
                }
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
            }.keyboardShortcut("j", modifiers: .command)
            .frame(minHeight: 50)
            
            Button {
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
            }.keyboardShortcut("p", modifiers: .command)
            .frame(minHeight: 50)
            
            Button {
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
            }.keyboardShortcut("a", modifiers: [.command, .shift])
            .frame(minHeight: 50)
            
            Button {
                do {
                    try isUpdateAvailable { [self] (update, error) in
                        if let update {
                            if update {
                                self.showUpdateToastMessage = NSLocalizedString("Update available. Redirecting to App Store...", comment: "")
                                self.showUpdateToast = true
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    UIApplication.shared.open(URL(string: "https://apps.apple.com/us/app/service-maps/id1664309103")!)
                                }
                            } else {
                                self.showUpdateToastMessage = NSLocalizedString("App is up to date!", comment: "")
                                self.showUpdateToast = true
                            }
                        }
                       
                       if let error {
                           if error.localizedDescription == NSLocalizedString("The operation couldn’t be completed. (NSURLErrorDomain error -1009.)", comment: "") {
                               self.showUpdateToastMessage = NSLocalizedString("No internet connection", comment: "")
                               self.showUpdateToast = true
                           } else {
                               self.showUpdateToastMessage = error.localizedDescription
                               self.showUpdateToast = true
                           }
                       }
                    }
                } catch {
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
            }.keyboardShortcut("u", modifiers: [.command, .shift])
            .frame(minHeight: 50)
        }
        .padding(10)
        .frame(minWidth: mainWindowSize.width * 0.95)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    func deleteCacheMenu(mainWindowSize: CGSize) -> some View {
        VStack {
            Button {
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
    
    @ViewBuilder
    func deleteAccount(mainWindowSize: CGSize) -> some View {
        VStack {
            Button {
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
