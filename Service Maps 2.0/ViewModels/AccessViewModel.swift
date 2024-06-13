//
//  AccessViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/9/24.
//

import Foundation
import SwiftUI
import CoreData
import Combine
import NavigationTransitions
import SwipeActions
import RealmSwift

@MainActor
class AccessViewModel: ObservableObject {
    
    init() {
        getKeys()
        getKeyUsers()
    }
    
    @ObservedObject var universalLinksManager = UniversalLinksManager.shared
    
    @ObservedObject var authenticationManager = AuthenticationManager()
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var dataUploaderManager = DataUploaderManager()
    
    private var cancellables = Set<AnyCancellable>()
    private var cancellablesTwo = Set<AnyCancellable>()
    
    @Published var keyData: Optional<[KeyData]> = nil
    @Published var keyUsers: Optional<[UserTokenModel]> = nil
    @Published var blockedUsers: Optional<[UserTokenModel]> = nil
    
    @Published var currentKey: MyTokenModel? = nil {
        didSet {
            if currentKey != nil {
                getKeyUsers()
            }
        }
    }
    @Published var backAnimation = false
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    
    @Published var currentToken: MyTokenModel?
    @Published var presentSheet = false {
        didSet {
            if presentSheet == false {
                currentToken = nil
            }
        }
    }
    
    @State var showUserBlockAlert = false
    @State var showUserUnblockAlert = false
    
    @Published var optionsAnimation = false
    @Published var progress: CGFloat = 0.0
    
    @Published var syncAnimation = false
    @Published var syncAnimationprogress: CGFloat = 0.0
    
    @Published var restartAnimation = false
    @Published var animationProgress: Bool = false {
        didSet {
            print(animationProgress)
        }
    }
    
    @Published var showAlert = false
    @Published var ifFailed = false
    @Published var loading = false
    @Published var keyToDelete: (String?,String?)
    @Published var userToDelete: (String?,String?)
    
    @Published var showToast = false
    @Published var showAddedToast = false
    @Published var showUserDeleteToast = false
    
    func deleteKey(key: String) async -> Result<Bool, Error> {
        if !isAdmin {
            switch await dataUploaderManager.unregisterToken(myToken: key) {
            case .success(_):
                synchronizationManager.startupProcess(synchronizing: true)
                return Result.success(true)
            case .failure(let error):
                return Result.failure(error)
            }
        } else {
            return await dataUploaderManager.deleteToken(myToken: key)
        }
    }
    
    func deleteUser(user: String) async -> Result<Bool, Error> {
        return await dataUploaderManager.deleteUserFromToken(userToken: user)
    }
    
    
    @Published var search: String = "" {
        didSet {
            getKeys()
        }
    }
    
    @Published var searchActive = false
    
    @MainActor
    func registerKey() async -> Result<Bool, Error> {
        return await dataUploaderManager.registerToken(myToken: universalLinksManager.dataFromUrl ?? "")
    }
    
    @MainActor
    func removeUserFromToken() async -> Result<Bool, Error> {
        return await dataUploaderManager.deleteUserFromToken(userToken: userToDelete.0!)
    }
    
    @MainActor
    func blockUnblockUserFromToken() async -> Result<Bool, Error> {
        return await dataUploaderManager.blockUnblockUserFromToken(userToken: userToDelete.0!, blocked: Bool(userToDelete.1!)!)
    }
    
}

@MainActor
extension AccessViewModel {
    func getKeys() {
        RealmManager.shared.getKeyData()
            .receive(on: DispatchQueue.main) // Update on main thread
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Handle errors here
                    print("Error retrieving territory data: \(error)")
                }
            }, receiveValue: { keyData in
                if self.search.isEmpty {
                    DispatchQueue.main.async {
                        self.keyData = keyData
                    }
                } else {
                    DispatchQueue.main.async {
                        self.keyData = keyData.filter { keyData in
                            keyData.key.name.lowercased().contains(self.search.lowercased()) ||
                              keyData.territories.contains { territory in
                                  String(territory.number).lowercased().contains(self.search.lowercased())
                              } ||
                            keyData.key.owner.lowercased().contains(self.search.lowercased())
                          }
                    }
                }
               
            })
            .store(in: &cancellables)
    }
    
    func getKeyUsers() {
        if currentKey != nil {
            RealmManager.shared.getKeyUsers(token: currentKey!)
                .receive(on: DispatchQueue.main) // Update on main thread
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        // Handle errors here
                        print("Error retrieving territory data: \(error)")
                    }
                }, receiveValue: { keyUsers in
                    var blockedUsers = keyUsers.filter { $0.blocked }
                    var unblockedUsers = keyUsers.filter { !$0.blocked }
                    DispatchQueue.main.async {
                        self.keyUsers = unblockedUsers
                        self.blockedUsers = blockedUsers
                    }
                })
                .store(in: &cancellablesTwo)
        }
    }
}
