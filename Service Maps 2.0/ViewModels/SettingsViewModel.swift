//
//  SettingsViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/24/24.
//

import Foundation
import SwiftUI


@MainActor
class SettingsViewModel: ObservableObject {
    
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var authenticationManager = AuthenticationManager()
    @ObservedObject var authorizationProvider = AuthorizationProvider.shared
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    @State var loading = false
    @State var alwaysLoading = true
    
    @Published var errorText = ""
    
    func getCongregationName() -> String{
        return dataStore.congregationName ?? ""
    }
    
    func exitAdministrator() {
        authenticationManager.exitAdministrator()
    }
    
    @Published var syncAnimation = false
    @Published var syncAnimationprogress: CGFloat = 0.0
    
    @Published var presentSheet = false
    @Published var showAlert = false
    
    @ViewBuilder
    func profile() -> some View {
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
    }
    
    @ViewBuilder
    func administratorInfoCell() -> some View {
        HStack {
            if dataStore.congregationName != nil {
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
                    
                    CustomButton(loading: loading, title: "Exit", color: Color(UIColor.lightGray)) {
                        self.exitAdministrator()
                        self.synchronizationManager.startupProcess(synchronizing: true)
                    }
                    .frame(maxWidth: 120)
                    .hSpacing(.trailing)
                    
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
    }
    
    @ViewBuilder
    func infosView() -> some View {
        VStack {
            Button {
                let url = URL(string: "https://apps.apple.com/us/app/service-maps/id1664309103?l=fr-FR")
                let av = UIActivityViewController(activityItems: [url!], applicationActivities: nil)

                UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
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
            CustomBackButton() {
                withAnimation {
                    self.showAlert = false
                }
            }.hSpacing(.trailing)
                .frame(width: 100)
        }
        .padding()
    }
}
