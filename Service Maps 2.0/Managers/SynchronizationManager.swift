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
        
        // Begin fetching and syncing data
        do {
            // Periodically check if credentials have changed
            try await periodicCheckForCredentialChanges(
                initialIsAdmin: initialIsAdmin,
                initialHasPhoneCredentials: initialHasPhoneCredentials
            )
            
            // Fetch server data
            var tokensApi = [Token]()
            var userTokensApi = [UserToken]()
            var tokenTerritoriesApi = [TokenTerritory]()
            var territoriesApi = [Territory]()
            var housesApi = [House]()
            var visitsApi = [Visit]()
            var territoriesAddressesApi = [TerritoryAddress]()
            var phoneTerritoriesApi = [PhoneTerritory]()
            var phoneNumbersApi = [PhoneNumber]()
            var phoneCallsApi = [PhoneCall]()
            var recallsApi = [Recalls]()
            
            let tokenApi = TokenAPI()
            
            // Fetch Tokens
            let ownedTokens = try await tokenApi.loadOwnedTokens()
            tokensApi.append(contentsOf: ownedTokens)
            
            let userTokens = try await tokenApi.loadUserTokens()
            for token in userTokens {
                if !tokensApi.contains(token) {
                    tokensApi.append(token)
                }
            }
            
            // Fetch User Tokens if Admin Credentials exist
            //if await AuthorizationLevelManager().existsAdminCredentials() {
            for token in tokensApi {
                let usersResult = await tokenApi.usersOfToken(token: token.id)
                switch usersResult {
                case .success(let users):
                    for user in users {
                        userTokensApi.append(UserToken(id: UUID().uuidString, token: token.id, userId: String(user.id), name: user.name, blocked: user.blocked))
                    }
                case .failure(let error):
                    print("Failed to fetch users for token \(token.id): \(error)")
                }
            }
            //}
            
            // Fetch Territories, Houses, Visits, and Territory Addresses
            if await AuthorizationLevelManager().existsAdminCredentials() {
                let response = try await AdminAPI().allData()
                territoriesApi = response.territories
                housesApi = response.houses
                visitsApi = response.visits
                territoriesAddressesApi = response.addresses
            } else {
                let response = try await UserAPI().loadTerritories()
                territoriesApi = response.territories
                housesApi = response.houses
                visitsApi = response.visits
                territoriesAddressesApi = response.addresses
            }
            
            // Fetch Token Territories
            for token in tokensApi {
                let response = try await tokenApi.getTerritoriesOfToken(token: token.id)
                tokenTerritoriesApi.append(contentsOf: response)
            }
            
            
            
            // Fetch Phone Territories, Phone Numbers, and Phone Calls
            if await authorizationLevelManager.existsAdminCredentials() {
                let result = await AdminAPI().allPhoneData()
                switch result {
                case .success(let response):
                    phoneTerritoriesApi.append(contentsOf: response.territories)
                    phoneCallsApi.append(contentsOf: response.calls)
                    phoneNumbersApi.append(contentsOf: response.numbers)
                case .failure(let error):
                    print(error)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.dataStore.synchronized = true
                    }
                }
                
            } else {
                let result = await UserAPI().allPhoneData()
                switch result {
                case .success(let response):
                    phoneTerritoriesApi.append(contentsOf: response.territories)
                    phoneCallsApi.append(contentsOf: response.calls)
                    phoneNumbersApi.append(contentsOf: response.numbers)
                case .failure(_):
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.dataStore.synchronized = true
                    }
                }
            }
            
            // Fetch Recalls
            recallsApi = try await UserAPI().getRecalls()
            
            // Fetch local data from the database (GRDB)
            let tokensDb = try handleResult(await grdbManager.fetchAllAsync(Token.self))
            let userTokensDb = try handleResult(await grdbManager.fetchAllAsync(UserToken.self))
            let territoriesDb = try handleResult(await grdbManager.fetchAllAsync(Territory.self))
            let housesDb = try handleResult(await grdbManager.fetchAllAsync(House.self))
            let visitsDb = try handleResult(await grdbManager.fetchAllAsync(Visit.self))
            let territoriesAddressesDb = try handleResult(await grdbManager.fetchAllAsync(TerritoryAddress.self))
            let tokenTerritoriesDb = try handleResult(await grdbManager.fetchAllAsync(TokenTerritory.self))
            let phoneTerritoriesDb = try handleResult(await grdbManager.fetchAllAsync(PhoneTerritory.self))
            let phoneCallsDb = try handleResult(await grdbManager.fetchAllAsync(PhoneCall.self))
            let phoneNumbersDb = try handleResult(await grdbManager.fetchAllAsync(PhoneNumber.self))
            let recallsDb = try handleResult(await grdbManager.fetchAllAsync(Recalls.self))
            print("TokenTerritoriesApi \(tokenTerritoriesApi)")
            // Synchronize Tokens
            await comparingAndSynchronize(apiList: tokensApi, dbList: tokensDb, updateMethod: grdbManager.editBulkAsync, addMethod: grdbManager.addBulkAsync, deleteMethod: grdbManager.deleteBulkAsync)
            
            // Synchronize User Tokens
            await comparingAndSynchronize(apiList: userTokensApi, dbList: userTokensDb, updateMethod: grdbManager.editBulkAsync, addMethod: grdbManager.addBulkAsync, deleteMethod: grdbManager.deleteBulkAsync)
            
            // Synchronize Territories
            await comparingAndSynchronize(apiList: territoriesApi, dbList: territoriesDb, updateMethod: grdbManager.editBulkAsync, addMethod: grdbManager.addBulkAsync, deleteMethod: grdbManager.deleteBulkAsync)
            
            // Synchronize Houses
            await comparingAndSynchronize(apiList: housesApi, dbList: housesDb, updateMethod: grdbManager.editBulkAsync, addMethod: grdbManager.addBulkAsync, deleteMethod: grdbManager.deleteBulkAsync)
            
            // Synchronize Visits
            await comparingAndSynchronize(apiList: visitsApi, dbList: visitsDb, updateMethod: grdbManager.editBulkAsync, addMethod: grdbManager.addBulkAsync, deleteMethod: grdbManager.deleteBulkAsync)
            
            // Synchronize Territory Addresses
            await comparingAndSynchronize(apiList: territoriesAddressesApi, dbList: territoriesAddressesDb, updateMethod: grdbManager.editBulkAsync, addMethod: grdbManager.addBulkAsync, deleteMethod: grdbManager.deleteBulkAsync)
            
            // Synchronize Phone Territories
            await comparingAndSynchronize(apiList: phoneTerritoriesApi, dbList: phoneTerritoriesDb, updateMethod: grdbManager.editBulkAsync, addMethod: grdbManager.addBulkAsync, deleteMethod: grdbManager.deleteBulkAsync)
            
            // Synchronize Phone Calls
            await comparingAndSynchronize(apiList: phoneCallsApi, dbList: phoneCallsDb, updateMethod: grdbManager.editBulkAsync, addMethod: grdbManager.addBulkAsync, deleteMethod: grdbManager.deleteBulkAsync)
            
            // Synchronize Phone Numbers
            await comparingAndSynchronize(apiList: phoneNumbersApi, dbList: phoneNumbersDb, updateMethod: grdbManager.editBulkAsync, addMethod: grdbManager.addBulkAsync, deleteMethod: grdbManager.deleteBulkAsync)
            
            // Synchronize Token Territories
            await comparingAndSynchronizeTokenTerritories(apiList: tokenTerritoriesApi, dbList: tokenTerritoriesDb)
            
            // Synchronize Recalls
            await comparingAndSynchronize(apiList: recallsApi, dbList: recallsDb, updateMethod: grdbManager.editBulkAsync, addMethod: grdbManager.addBulkAsync, deleteMethod: grdbManager.deleteBulkAsync)
            print("TokenTerritoriesDbAfter \(try handleResult(await grdbManager.fetchAllAsync(TokenTerritory.self)))")
            // Finalize synchronization
            startupProcess(synchronizing: false)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.dataStore.synchronized = true
            }
        }
    }
    
    @BackgroundActor
    private func comparingAndSynchronize<T: Identifiable & Equatable>(
        apiList: [T],
        dbList: [T],
        updateMethod: @escaping ([T]) async -> Result<String, Error>, // Batch updates
        addMethod: @escaping ([T]) async -> Result<String, Error>,    // Batch additions
        deleteMethod: @escaping ([T]) async -> Result<String, Error>  // Batch deletions
    ) async {
        var updates: [T] = []
        var additions: [T] = []
        
        var dbDict = Dictionary(dbList.map { ($0.id, $0) }, uniquingKeysWith: { (_, new) in new })
        
        // Collect updates and additions
        for apiModel in apiList {
            if let dbModel = dbDict[apiModel.id] {
                if dbModel != apiModel {
                    updates.append(apiModel)
                }
                // Remove from dbDict to identify models that need deletion later
                dbDict.removeValue(forKey: apiModel.id)
            } else {
                additions.append(apiModel)
            }
        }
        
        // Remaining models in dbDict are those that need deletion
        let deletions = Array(dbDict.values)
        
        // Perform batch operations
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                if !updates.isEmpty {
                    let result = await updateMethod(updates)
                    switch result {
                    case .success(let message):
                        print("Batch Update Success: \(message)")
                    case .failure(let error):
                        print("Batch Update Error: \(error)")
                    }
                }
            }
            
            group.addTask {
                if !additions.isEmpty {
                    let result = await addMethod(additions)
                    switch result {
                    case .success(let message):
                        print("Batch Addition Success: \(message)")
                    case .failure(let error):
                        print("Batch Addition Error: \(error)")
                    }
                }
            }
            
            group.addTask {
                if !deletions.isEmpty {
                    let result = await deleteMethod(deletions)
                    switch result {
                    case .success(let message):
                        print("Batch Deletion Success: \(message)")
                    case .failure(let error):
                        print("Batch Deletion Error: \(error)")
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
    
    @BackgroundActor
    private func comparingAndSynchronizeTokenTerritories(apiList: [TokenTerritory], dbList: [TokenTerritory]) async {
        
        // Arrays to hold updates, additions, and deletions
        var updates: [TokenTerritory] = []
        var additions: [TokenTerritory] = []
        var deletions: [TokenTerritory] = []
        
        // 1. Find additions and updates
        for apiTokenTerritory in apiList {
            if let dbTokenTerritory = dbList.first(where: { $0.token == apiTokenTerritory.token && $0.territory == apiTokenTerritory.territory }) {
                // Found in DB, check for differences
                if dbTokenTerritory != apiTokenTerritory {
                    updates.append(apiTokenTerritory)
                }
            } else {
                // Not in DB, so it must be added
                additions.append(apiTokenTerritory)
            }
        }

        // 2. Find deletions (exists in DB but not in API)
        for dbTokenTerritory in dbList {
            if !apiList.contains(where: { $0.token == dbTokenTerritory.token && $0.territory == dbTokenTerritory.territory }) {
                deletions.append(dbTokenTerritory)
            }
        }

        // 3. Perform Updates
        if !updates.isEmpty {
            print("Updating \(updates.count) token territories")
            for tokenTerritory in updates {
                switch await grdbManager.editAsync(tokenTerritory) {
                case .success(let success):
                    print("Successfully updated: \(success)")
                case .failure(let error):
                    print("Update failed for \(tokenTerritory): \(error)")
                }
            }
        }

        // 4. Perform Additions
        if !additions.isEmpty {
            print("Adding \(additions.count) token territories")
            for tokenTerritory in additions {
                switch await grdbManager.addAsync(tokenTerritory) {
                case .success(let success):
                    print("Successfully added: \(success)")
                case .failure(let error):
                    print("Addition failed for \(tokenTerritory): \(error)")
                }
            }
        }

        // 5. Perform Deletions
        if !deletions.isEmpty {
            print("Deleting \(deletions.count) token territories")
            for tokenTerritory in deletions {
                switch await grdbManager.deleteAsync(tokenTerritory) {
                case .success(let success):
                    print("Successfully deleted: \(success)")
                case .failure(let error):
                    print("Deletion failed for \(tokenTerritory): \(error)")
                }
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
