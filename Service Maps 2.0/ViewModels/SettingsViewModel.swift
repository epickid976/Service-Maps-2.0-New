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
}
