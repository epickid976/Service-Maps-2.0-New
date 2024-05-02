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
    
    
    
    @ViewBuilder
    func profile() -> some View {
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
            
            
            CustomButton(loading: loading, title: "Logout") {
                Task {
                    let result = await self.authenticationManager.logout()
                    switch result {
                    case .success(_):
                        self.exitAdministrator()
                        SynchronizationManager.shared.startupProcess(synchronizing: false)
                    case .failure(let error):
                        print("logout failed")
                        self.errorText = error.asAFError?.localizedDescription ?? ""
                    }
                }
            }
        }.padding(.bottom)
    }
    
    @ViewBuilder
    func phoneLoginInfoCell() -> some View {
        VStack {
            HStack {
                if dataStore.phoneCongregationName != nil {
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
                                }
                            }
                            CustomBackButton(showImage: false, text: "Exit") {
                                self.exitPhoneLogin()
                                self.synchronizationManager.startupProcess(synchronizing: true)
                            }
                            .frame(maxWidth: 120)
                            .hSpacing(.trailing)
                            
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
                                .lineLimit(1)
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
            .frame(minWidth: UIScreen.main.bounds.width * 0.95, minHeight: 75)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }.padding(.bottom)
    }
    
    @ViewBuilder
    func administratorInfoCell() -> some View {
        VStack {
            HStack {
                if dataStore.congregationName != nil {
                    VStack {
                        HStack {
                            VStack {
                                Text("Administrator")
                                    .font(.title3)
                                    .lineLimit(4)
                                    .foregroundColor(.primary)
                                    .fontWeight(.heavy)
                                    .hSpacing(.leading)
                                HStack {
                                    Image(systemName: "house.lodge.fill")
                                    
                                    Text("\(dataStore.congregationName!)")
                                        .font(.headline)
                                        .lineLimit(4)
                                        .foregroundColor(.primary)
                                        .fontWeight(.heavy)
                                        .hSpacing(.leading)
                                }
                            }
                            CustomBackButton(showImage: false, text: "Exit") {
                                self.exitAdministrator()
                                self.synchronizationManager.startupProcess(synchronizing: true)
                            }
                            .frame(maxWidth: 120)
                            .hSpacing(.trailing)
                            
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
                                .lineLimit(1)
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
            .frame(minWidth: UIScreen.main.bounds.width * 0.95, minHeight: 75)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }.padding(.bottom)
    }
    
    @ViewBuilder
    func infosView() -> some View {
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
                            .lineLimit(1)
                            .foregroundColor(.primary)
                            .fontWeight(.heavy)
                    }
                    .hSpacing(.leading)
                }
            }
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
                            .lineLimit(1)
                            .foregroundColor(.primary)
                            .fontWeight(.heavy)
                    }
                    .hSpacing(.leading)
                }
            }
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
        .frame(minWidth: UIScreen.main.bounds.width * 0.95)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    func deleteCacheMenu() -> some View {
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
        .frame(minWidth: UIScreen.main.bounds.width * 0.95)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    func deleteAccount() -> some View {
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
        .frame(minWidth: UIScreen.main.bounds.width * 0.95)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    func aboutApp() -> some View {
        VStack {
            Text("About App")
                .font(.title)
                .lineLimit(1)
                .foregroundColor(.primary)
                .fontWeight(.heavy)
            Text("""
            Service Maps has been created with the purpose of streamlining and facilitating the control and registration of the public preaching of Jehovah's Witnesses.
            This tool is not part of JW.ORG nor is it an official app of the organization. It is simply the result of the effort and love of some brothers. We hope it is useful. Thank you for using Service Maps.
            """)
            .font(.headline)
            .lineLimit(10)
            .foregroundColor(.primary)
            .fontWeight(.heavy)
            CustomBackButton(showImage: false, text: "Dismiss") {
                withAnimation {
                    self.showAlert = false
                }
            }.hSpacing(.trailing)
            //.frame(width: 100)
        }
        .padding()
    }
    
    @ViewBuilder
    func accountDeletionAlertConfirmation() -> some View {
        VStack {
            Text("Are you sure you want to delete your account?")
                .font(.title)
                .lineLimit(2)
                .foregroundColor(.primary)
                .fontWeight(.heavy)
                .multilineTextAlignment(.center)
            Text("This is nonreversible")
                .font(.headline)
                .lineLimit(10)
                .foregroundColor(.primary)
                .fontWeight(.heavy)
            
            Text(deletionError)
                .fontWeight(.bold)
                .foregroundColor(.red)
            //.vSpacing(.bottom)
            
            HStack {
                CustomBackButton(showImage: true, text: "Cancel") {
                    withAnimation {
                        self.showDeletionConfirmationAlert = false
                    }
                }.hSpacing(.trailing)
                CustomButton(loading: loading, title: "Delete", color: .red, action: {
                    withAnimation { self.loading = true }
                    Task {
                        switch await AuthenticationManager().deleteAccount() {
                        case .success(_):
                            withAnimation { self.loading = false }
                            
                            self.showDeletionConfirmationAlert = false
                        case .failure(_):
                            withAnimation { self.loading = true }
                            self.deletionError = "Error deleting account"
                        }
                    }
                })
                .hSpacing(.trailing)
                //.frame(width: 100)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    func accountDeletionAlert() -> some View {
        VStack {
            Text("Delete Account")
                .font(.title)
                .lineLimit(1)
                .foregroundColor(.primary)
                .fontWeight(.heavy)
            Text("""
                Are you sure about deleting your account? This action can not be undone. If you decide to delete your account, your account and all access granted to you will be deleted, but the information you have previously provided will remain on the server. The email used in this account cannot be reused again.
                """)
            .font(.headline)
            .lineLimit(10)
            .foregroundColor(.primary)
            .fontWeight(.heavy)
            .multilineTextAlignment(.center)
            
            HStack {
                CustomBackButton(showImage: true, text: "Cancel") {
                    self.showDeletionAlert = false
                }.hSpacing(.trailing)
                CustomButton(loading: loading, title: "Delete", color: .red, action: {
                    self.showDeletionAlert = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        self.showDeletionConfirmationAlert = true
                    }
                })
                .hSpacing(.trailing)
                //.frame(width: 100)
            }
        }
        .padding()
    }
}
