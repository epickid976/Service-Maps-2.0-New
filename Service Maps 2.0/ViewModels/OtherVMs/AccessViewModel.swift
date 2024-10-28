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
    
    @ObservedObject var grdbManager = GRDBManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    private var cancellablesTwo = Set<AnyCancellable>()
    
    @Published var keyData: Optional<[KeyData]> = nil
    @Published var keyUsers: Optional<[UserToken]> = nil
    @Published var blockedUsers: Optional<[UserToken]> = nil
    
    @Published var currentKey: Token? = nil {
        didSet {
            if currentKey != nil {
                getKeyUsers()
            }
        }
    }
    @Published var backAnimation = false
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    
    @Published var currentToken: Token?
    @Published var presentSheet = false {
        didSet {
            if presentSheet == false {
                currentToken = nil
            }
        }
    }
    
    @Published var showUserBlockAlert = false
    @Published var showUserUnblockAlert = false
    
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
    @Published var userToDelete: (id: String?, name: String?)?
    @Published var blockUnblockAction: UserAction? 
    
    @Published var showToast = false
    @Published var showAddedToast = false
    @Published var showUserDeleteToast = false
    
    @MainActor
    func deleteKey(key: String) async -> Result<Void, Error> {
        if !isAdmin {
            switch await dataUploaderManager.unregisterToken(myToken: key) {
            case .success(_):
                // Fetch token territories from GRDB
                let tokenTerritoryResult = grdbManager.fetchAll(TokenTerritory.self)
                
                // Fetch the token by ID
                let tokenResult = grdbManager.fetchById(Token.self, id: key)
                
                switch (tokenTerritoryResult, tokenResult) {
                case (.success(let tokenTerritoryEntities), .success(let keyToDelete)):
                    if let keyToDelete = keyToDelete {
                        // Delete associated token territories
                        for tokenTerritory in tokenTerritoryEntities where tokenTerritory.token == keyToDelete.id {
                            _ = grdbManager.delete(tokenTerritory)
                        }
                        
                        // Delete the token
                        _ = grdbManager.delete(keyToDelete)
                    }
                    return .success(())
                    
                case (.failure(let territoryError), _):
                    return .failure(territoryError)
                    
                case (_, .failure(let tokenError)):
                    return .failure(tokenError)
                }
                
            case .failure(let error):
                return .failure(error)
            }
        } else {
            return await dataUploaderManager.deleteToken(tokenId: key)
        }
    }
    
    @MainActor
    func deleteUser(user: String) async -> Result<Void, Error> {
        return await dataUploaderManager.deleteUserFromToken(userToken: user)
    }
    
    
    @Published var search: String = "" {
        didSet {
            getKeys()
        }
    }
    
    @Published var searchActive = false
    
    @MainActor
    func registerKey() async -> Result<Void, Error> {
        return await dataUploaderManager.registerToken(myToken: universalLinksManager.dataFromUrl ?? "")
    }
    
    
    func removeUserFromToken() async -> Result<Void, Error> {
        return await dataUploaderManager.deleteUserFromToken(userToken: userToDelete?.0 ?? "")
    }
    
    
    // Function to handle blocking/unblocking users
    func blockUnblockUserFromToken(user: UserAction) async -> Result<Void, Error> {
        // Use the 'user' struct to pass the necessary information (id and isBlocked)
        return await dataUploaderManager.blockUnblockUserFromToken(userToken: user.userToken, blocked: !user.isBlocked)
    }
    
}

@MainActor
extension AccessViewModel {
    func getKeys() {
        GRDBManager.shared.getKeyData()
            .subscribe(on: DispatchQueue.main)
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
            GRDBManager.shared.getKeyUsers(token: currentKey!)
                .subscribe(on: DispatchQueue.main)
                .receive(on: DispatchQueue.main) // Update on main thread
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        // Handle errors here
                        print("Error retrieving territory data: \(error)")
                    }
                }, receiveValue: { keyUsers in
                    let uniqueKeyUsers = Array(Set(keyUsers)) // Use Set to remove duplicates
                    let blockedUsers = uniqueKeyUsers.filter { $0.blocked }
                    let unblockedUsers = uniqueKeyUsers.filter { !$0.blocked }
                    DispatchQueue.main.async {
                        self.keyUsers = unblockedUsers.sorted { $0.name < $1.name }
                        self.blockedUsers = blockedUsers.sorted { $0.name < $1.name }
                    }
                })
                .store(in: &cancellablesTwo)
        }
    }
}
