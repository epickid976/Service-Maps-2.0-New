//
//  SynchronizationManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/1/23.
//

import Foundation
import Combine
import GRDB



@globalActor actor SyncActor: GlobalActor {
    static var shared = SyncActor()
}

class SynchronizationManager: ObservableObject {
    // MARK: - Published Properties
    @Published private var grdbManager = GRDBManager.shared
    @Published private var dataStore = StorageManager.shared
    @Published private var authorizationLevelManager = AuthorizationLevelManager()
    @Published var startupState: StartupState = .Unknown
    @Published var back_from_verification = false
    private var syncTask: Task<Void, Never>? = nil // Track the current startup task
    
    // MARK: - Private Properties
    private var authenticationManager = AuthenticationManager()
    private var loaded = false
    private var timer: Timer?
    
    // MARK: - Start Synchronization with Haptics
    private var syncTimer: DispatchSourceTimer?
    
    
    @SyncActor
    func startSyncAndHaptics() {
        // Ensure haptic feedback and synchronization are non-blocking
        syncTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
        syncTimer?.schedule(deadline: .now(), repeating: 1)
        syncTimer?.setEventHandler { [weak self] in
            guard let self = self, !self.dataStore.synchronized else {
                self?.syncTimer?.cancel()
                return
            }
            DispatchQueue.main.async {
                HapticManager.shared.trigger(.lightImpact)  // Keep this non-blocking
            }
        }
        syncTimer?.resume()  // Start the timer
    }
    
    // MARK: - Startup Process
    func startupProcess(synchronizing: Bool, clearSynchronizing: Bool = false) {
        //allData()
        if clearSynchronizing {
            loaded = false
            dataStore.synchronized = false
        }
        
        syncTask = Task {
            Task {
                if synchronizing {
                    await self.synchronize()
                }
            }
            
            Task {
                DispatchQueue.main.async {
                    let newStartupState = self.loadStartupState()
                    self.startupState = newStartupState
                }
                
                if startupState == .Ready || startupState == .Empty {
                    if let verifiedCredentials = await verifyCredentials() {
                        DispatchQueue.main.async {
                            self.startupState = verifiedCredentials
                        }
                    }
                }
            }
        }
    }
    
    private func loadStartupState() -> StartupState {
        // Fetching data from GRDB synchronously using Result type handling
        let territoryEntitiesResult = grdbManager.fetchAll(Territory.self)
        let phoneTerritoryEntitiesResult = grdbManager.fetchAll(PhoneTerritory.self)
        
        // Unwrapping the Result values using .get()
        do {
            let territoryEntities = try territoryEntitiesResult.get()
            let phoneTerritoryEntities = try phoneTerritoryEntitiesResult.get()
            
            // Continue with the logic using territoryEntities and phoneTerritoryEntities
            if dataStore.userEmail == nil || back_from_verification {
                return .Welcome
            }
            
            if !authorizationLevelManager.userHasLogged() {
                return .Validate
            }
            
            // Checking if data is empty
            if territoryEntities.isEmpty {
                if dataStore.synchronized || loaded {
                    return authorizationLevelManager.existsAdminCredentials() ? .Ready : (phoneTerritoryEntities.isEmpty ? .Empty : .Ready)
                }
                
                loaded = true
                return .Loading
            }
            
            return .Ready
            
        } catch {
            // Handle errors in fetching data
            print("Failed to fetch data: \(error)")
            return .Loading // Default to loading state if there's an error
        }
    }
    
    // MARK: - Verify Credentials
    private func verifyCredentials() async -> StartupState? {
        if await authorizationLevelManager.userNeedLogin() {
            return .Welcome
        }
        
        if await authorizationLevelManager.adminNeedLogin() {
            return .AdminLogin
        }
        
        if await !authorizationLevelManager.existsAdminCredentials(), await authorizationLevelManager.phoneNeedLogin() {
            return .PhoneLogin
        }
        
        return nil
    }
    
    @SyncActor
    func synchronize() async {
        // Store initial admin and phone credentials at the start
            let initialIsAdmin = await AuthorizationLevelManager().existsAdminCredentials()
            let initialHasPhoneCredentials = await AuthorizationLevelManager().existsPhoneCredentials()
        
        // Mark synchronization as not completed
        DispatchQueue.main.async {
            self.dataStore.synchronized = false
        }
        
        // Start sync with haptics feedback
        startSyncAndHaptics()
        
        // Fetch server data
        do {
            
            // Periodically check if credentials have changed
                    try await periodicCheckForCredentialChanges(
                        initialIsAdmin: initialIsAdmin,
                        initialHasPhoneCredentials: initialHasPhoneCredentials
                    )
            
            
            let (tokensApi, userTokensApi, tokenTerritoriesApi) = try await fetchTokensFromServer()
            let (territoriesApi, housesApi, visitsApi, territoriesAddressesApi) = try await fetchTerritoriesFromServer()
            let (phoneTerritoriesApi, phoneNumbersApi, phoneCallsApi) = try await fetchPhoneTerritoryDataFromServer()
            let recallsApi = try await fetchRecallsFromServer()
            
            // Fetch local data from database (GRDB)
            let tokensDb = try await handleResult(grdbManager.fetchAllAsync(Token.self))
            let userTokensDb = try await handleResult(grdbManager.fetchAllAsync(UserToken.self))
            let territoriesDb = try await handleResult(grdbManager.fetchAllAsync(Territory.self))
            let housesDb = try await handleResult(grdbManager.fetchAllAsync(House.self))
            let visitsDb = try await handleResult(grdbManager.fetchAllAsync(Visit.self))
            let territoriesAddressesDb = try await handleResult(grdbManager.fetchAllAsync(TerritoryAddress.self))
            let tokenTerritoriesDb = try await handleResult(grdbManager.fetchAllAsync(TokenTerritory.self))
            let phoneTerritoriesDb = try await handleResult(grdbManager.fetchAllAsync(PhoneTerritory.self))
            let phoneCallsDb = try await handleResult(grdbManager.fetchAllAsync(PhoneCall.self))
            let phoneNumbersDb = try await handleResult(grdbManager.fetchAllAsync(PhoneNumber.self))
            let recallsDb = try await handleResult(grdbManager.fetchAllAsync(Recalls.self))
            
            // Comparing and Synchronizing with generalized function
            await comparingAndSynchronize(
                apiList: tokensApi,
                dbList: tokensDb,
                updateMethod: grdbManager.editBulkAsync,
                addMethod: grdbManager.addBulkAsync,
                deleteMethod: grdbManager.deleteBulkAsync
            )
            
            await comparingAndSynchronize(
                apiList: userTokensApi,
                dbList: userTokensDb,
                updateMethod: grdbManager.editBulkAsync,
                addMethod: grdbManager.addBulkAsync,
                deleteMethod: grdbManager.deleteBulkAsync
            )
            
            await comparingAndSynchronize(
                apiList: territoriesApi,
                dbList: territoriesDb,
                updateMethod: grdbManager.editBulkAsync,
                addMethod: grdbManager.addBulkAsync,
                deleteMethod: grdbManager.deleteBulkAsync
            )
            
            await comparingAndSynchronize(
                apiList: housesApi,
                dbList: housesDb,
                updateMethod: grdbManager.editBulkAsync,
                addMethod: grdbManager.addBulkAsync,
                deleteMethod: grdbManager.deleteBulkAsync
            )
            
            await comparingAndSynchronize(
                apiList: visitsApi,
                dbList: visitsDb,
                updateMethod: grdbManager.editBulkAsync,
                addMethod: grdbManager.addBulkAsync,
                deleteMethod: grdbManager.deleteBulkAsync
            )
            
            await comparingAndSynchronize(
                apiList: territoriesAddressesApi,
                dbList: territoriesAddressesDb,
                updateMethod: grdbManager.editBulkAsync,
                addMethod: grdbManager.addBulkAsync,
                deleteMethod: grdbManager.deleteBulkAsync
            )
            
            await comparingAndSynchronize(
                apiList: phoneTerritoriesApi,
                dbList: phoneTerritoriesDb,
                updateMethod: grdbManager.editBulkAsync,
                addMethod: grdbManager.addBulkAsync,
                deleteMethod: grdbManager.deleteBulkAsync
            )
            
            await comparingAndSynchronize(
                apiList: phoneCallsApi,
                dbList: phoneCallsDb,
                updateMethod: grdbManager.editBulkAsync,
                addMethod: grdbManager.addBulkAsync,
                deleteMethod: grdbManager.deleteBulkAsync
            )
            
            await comparingAndSynchronize(
                apiList: phoneNumbersApi,
                dbList: phoneNumbersDb,
                updateMethod: grdbManager.editBulkAsync,
                addMethod: grdbManager.addBulkAsync,
                deleteMethod: grdbManager.deleteBulkAsync
            )
            
            await comparingAndSynchronize(
                apiList: tokenTerritoriesApi,
                dbList: tokenTerritoriesDb,
                updateMethod: grdbManager.editBulkAsync,
                addMethod: grdbManager.addBulkAsync,
                deleteMethod: grdbManager.deleteBulkAsync
            )
            
            await comparingAndSynchronize(
                apiList: recallsApi,
                dbList: recallsDb,
                updateMethod: grdbManager.editBulkAsync,
                addMethod: grdbManager.addBulkAsync,
                deleteMethod: grdbManager.deleteBulkAsync
            )
            
            // Finalize synchronization
            DispatchQueue.main.async {
                self.dataStore.lastTime = Date.now
                self.dataStore.synchronized = true
            }
            
        } catch SynchronizationError.credentialsChanged {
            // Resynchronize if the credentials changed
            print("Credentials changed during sync, restarting synchronization.")
            await synchronize() // Restart the synchronization with the updated credentials
        } catch {
            // Handle other synchronization errors
            print("Synchronization failed with error: \(error.localizedDescription)")
            await MainActor.run {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.dataStore.synchronized = true
                }
            }
        }
    }
    
    // Helper Functions for Fetching Data from Server]
    @SyncActor
    private func fetchTokensFromServer() async throws -> ([Token], [UserToken], [TokenTerritory]) {
        var tokensApi = [Token]()
        var userTokensApi = [UserToken]()
        var tokenTerritoriesApi = [TokenTerritory]()
        
        let tokenApi = TokenAPI()
        let ownedTokens = try await tokenApi.loadOwnedTokens()
        tokensApi.append(contentsOf: ownedTokens)
        
        let userTokens = try await tokenApi.loadUserTokens()
        for token in userTokens {
            if !tokensApi.contains(token) {
                tokensApi.append(token)
            }
        }
        if await AuthorizationLevelManager().existsAdminCredentials() {
            for token in tokensApi {
                let usersResult = await tokenApi.usersOfToken(token: token.id)
                
                switch usersResult {
                case .success(let users):
                    for user in users {
                        userTokensApi.append(UserToken(id: UUID().uuidString, token: token.id, userId: String(user.id), name: user.name, blocked: user.blocked))
                    }
                case .failure(let error):
                    print("Failed to fetch users for token \(token.id): \(error)")
                    // Optionally handle the error or log it
                }
            }
        }
        for token in tokensApi {
            let response = try await tokenApi.getTerritoriesOfToken(token: token.id)
            tokenTerritoriesApi.append(contentsOf: response)
        }
        
        return (tokensApi, userTokensApi, tokenTerritoriesApi)
    }
    @SyncActor
    private func fetchTerritoriesFromServer() async throws -> ([Territory], [House], [Visit], [TerritoryAddress]) {
        if await authorizationLevelManager.existsAdminCredentials() {
            let response = try await AdminAPI().allData()
            return (response.territories, response.houses, response.visits, response.addresses)
        } else {
            let response = try await UserAPI().loadTerritories()
            return (response.territories, response.houses, response.visits, response.addresses)
        }
    }
    @SyncActor
    private func fetchPhoneTerritoryDataFromServer() async throws -> ( [PhoneTerritory], [PhoneNumber], [PhoneCall]) {
        if await authorizationLevelManager.existsAdminCredentials() {
            let result = await AdminAPI().allPhoneData()
            switch result {
            case .success(let response):
                return (response.territories, response.numbers, response.calls)
            case .failure(let error):
                throw error
            }
        } else if await authorizationLevelManager.existsPhoneCredentials() {
            let result = await UserAPI().allPhoneData()
            switch result {
            case .success(let response):
                return (response.territories, response.numbers, response.calls)
            case .failure(let error):
                throw error
            }
        } else {
            return ([], [], [])
        }
    }
    @SyncActor
    private func fetchRecallsFromServer() async throws -> [Recalls] {
        return try await UserAPI().getRecalls()
    }
    
    @SyncActor
    private func comparingAndSynchronize<T: Identifiable & Equatable>(
        apiList: [T],
        dbList: [T],
        updateMethod: @escaping ([T]) async -> Result<String, Error>, // Accept array for batching
        addMethod: @escaping ([T]) async -> Result<String, Error>,    // Accept array for batching
        deleteMethod: @escaping ([T]) async -> Result<String, Error>  // Accept array for batching
    ) async {
        let dbDict = Dictionary(uniqueKeysWithValues: dbList.map { ($0.id, $0) })
        
        var updates: [T] = []
        var additions: [T] = []
        
        for apiModel in apiList {
            if let dbModel = dbDict[apiModel.id] {
                if dbModel != apiModel {
                    updates.append(apiModel) // Collect updates
                }
            } else {
                additions.append(apiModel) // Collect additions
            }
        }
        
        let apiSet = Set(apiList.map { $0.id })
        let dbSet = Set(dbList.map { $0.id }).subtracting(apiSet)
        
        let deletions = dbSet.compactMap { dbDict[$0] }
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                if !updates.isEmpty {
                    let result = await updateMethod(updates) // Batch updates
                    switch result {
                    case .success(let successMessage):
                        print("Batch Update Success: \(successMessage)")
                    case .failure(let error):
                        print("Error updating models: \(error)")
                    }
                }
            }
            
            group.addTask {
                if !additions.isEmpty {
                    let result = await addMethod(additions) // Batch additions
                    switch result {
                    case .success(let successMessage):
                        print("Batch Addition Success: \(successMessage)")
                    case .failure(let error):
                        print("Error adding models: \(error)")
                    }
                }
            }
            
            group.addTask {
                if !deletions.isEmpty {
                    let result = await deleteMethod(deletions) // Batch deletions
                    switch result {
                    case .success(let successMessage):
                        print("Batch Deletion Success: \(successMessage)")
                    case .failure(let error):
                        print("Error deleting models: \(error)")
                    }
                }
            }
        }
    }
    
    @SyncActor
    private func periodicCheckForCredentialChanges(initialIsAdmin: Bool, initialHasPhoneCredentials: Bool) async throws {
        for _ in 0..<5 { // Periodically check 5 times (adjust as needed)
            try await Task.sleep(nanoseconds: 1_000_000_000) // Check every 1 second
            
            let currentIsAdmin = await AuthorizationLevelManager().existsAdminCredentials()
            let currentHasPhoneCredentials = await AuthorizationLevelManager().existsPhoneCredentials()
            
            // If credentials changed, throw an error to restart sync
            if currentIsAdmin != initialIsAdmin || currentHasPhoneCredentials != initialHasPhoneCredentials {
                throw SynchronizationError.credentialsChanged
            }
        }
    }

    // Custom error for when the credentials change during sync
    enum SynchronizationError: Error {
        case credentialsChanged
    }
    
    func handleResult<T>(_ result: Result<[T], Error>) throws -> [T] {
        switch result {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        }
    }
    
    class var shared: SynchronizationManager {
        struct Static {
            static let instance = SynchronizationManager()
        }
        
        return Static.instance
    }
}

struct UserAction {
    var id: String
    var isBlocked: Bool
}
