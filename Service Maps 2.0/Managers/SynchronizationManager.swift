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
@MainActor
class SynchronizationManager: ObservableObject {
    static let shared = SynchronizationManager()
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
    
    
//    @MainActor
//    func startSyncAndHaptics() {
//        // Ensure haptic feedback and synchronization are non-blocking
//        syncTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
//        syncTimer?.schedule(deadline: .now(), repeating: 1)
//        syncTimer?.setEventHandler { [weak self] in
//            guard let self = self, !self.dataStore.synchronized else {
//                self?.syncTimer?.cancel()
//                return
//            }
//            DispatchQueue.main.async {
//                HapticManager.shared.trigger(.lightImpact)  // Keep this non-blocking
//            }
//        }
//        syncTimer?.resume()  // Start the timer
//    }
    
    // MARK: - Startup Process
    @MainActor
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
    @MainActor
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
        
        if !authorizationLevelManager.existsAdminCredentials(), await authorizationLevelManager.phoneNeedLogin() {
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
        //await startSyncAndHaptics()
        
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
            
            let tokenApi = TokenService()
            
            // Fetch Tokens
            let ownedTokens = try await tokenApi.loadOwnedTokens().get()
            tokensApi.append(contentsOf: ownedTokens)
            
            let userTokens = try await tokenApi.loadUserTokens().get()
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
                        userTokensApi.append(UserToken(token: token.id, userId: String(user.id), name: user.name, blocked: user.blocked))
                    }
                case .failure(let error):
                    print("Failed to fetch users for token \(token.id): \(error)")
                }
            }
            //}
            
            // Fetch Territories, Houses, Visits, and Territory Addresses
            if await AuthorizationLevelManager().existsAdminCredentials() {
                let response = try await AdminService().allData().get()
                territoriesApi = response.territories
                housesApi = response.houses
                visitsApi = response.visits
                territoriesAddressesApi = response.addresses
            } else {
                let response = try await UserService().loadTerritories().get()
                territoriesApi = response.territories
                housesApi = response.houses
                visitsApi = response.visits
                territoriesAddressesApi = response.addresses
            }
            
            // Fetch Token Territories
            for token in tokensApi {
                let response = try await tokenApi.getTerritoriesOfToken(token: token.id).get()
                tokenTerritoriesApi.append(contentsOf: response)
            }
            
            
            
            // Fetch Phone Territories, Phone Numbers, and Phone Calls
            if await authorizationLevelManager.existsAdminCredentials() {
                let result = await AdminService().allPhoneData()
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
                
            } else if await authorizationLevelManager.existsPhoneCredentials() {
                let result = await UserService().allPhoneData()
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
            recallsApi = try await UserService().getRecalls().get()
            
            // Fetch local data from the database (GRDB)
            let tokensDb = try await handleResult(await grdbManager.fetchAllAsync(Token.self))
            let userTokensDb = try await handleResult(await grdbManager.fetchAllAsync(UserToken.self))
            let territoriesDb = try await  handleResult(await grdbManager.fetchAllAsync(Territory.self))
            let housesDb = try await  handleResult(await grdbManager.fetchAllAsync(House.self))
            let visitsDb = try await  handleResult(await grdbManager.fetchAllAsync(Visit.self))
            let territoriesAddressesDb = try await  handleResult(await grdbManager.fetchAllAsync(TerritoryAddress.self))
            let tokenTerritoriesDb = try await  handleResult(await grdbManager.fetchAllAsync(TokenTerritory.self))
            let phoneTerritoriesDb = try await  handleResult(await grdbManager.fetchAllAsync(PhoneTerritory.self))
            let phoneCallsDb = try await  handleResult(await grdbManager.fetchAllAsync(PhoneCall.self))
            let phoneNumbersDb = try await  handleResult(await grdbManager.fetchAllAsync(PhoneNumber.self))
            let recallsDb = try await  handleResult(await grdbManager.fetchAllAsync(Recalls.self))
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
            // Finalize synchronization
            await startupProcess(synchronizing: false)
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
    // Helper Functions for Fetching Data from Server]
    @SyncActor
    private func fetchTokensFromServer() async throws -> ([Token], [UserToken], [TokenTerritory]) {
        var tokensApi = [Token]()
        var userTokensApi = [UserToken]()
        var tokenTerritoriesApi = [TokenTerritory]()
        
        let tokenApi = TokenService()
        let ownedTokens = try await tokenApi.loadOwnedTokens().get()
        tokensApi.append(contentsOf: ownedTokens)
        
        let userTokens = try await tokenApi.loadUserTokens().get()
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
                        userTokensApi.append(UserToken( token: token.id, userId: String(user.id), name: user.name, blocked: user.blocked))
                    }
                case .failure(let error):
                    print("Failed to fetch users for token \(token.id): \(error)")
                    // Optionally handle the error or log it
                }
            }
        }
        for token in tokensApi {
            let response = try await tokenApi.getTerritoriesOfToken(token: token.id).get()
            tokenTerritoriesApi.append(contentsOf: response)
        }
        
        return (tokensApi, userTokensApi, tokenTerritoriesApi)
    }
    @SyncActor
    private func fetchTerritoriesFromServer() async throws -> ([Territory], [House], [Visit], [TerritoryAddress]) {
        if await authorizationLevelManager.existsAdminCredentials() {
            let response = try await AdminService().allData().get()
            
            return (response.territories, response.houses, response.visits, response.addresses)
        } else {
            let response = try await UserService().loadTerritories().get()
            return (response.territories, response.houses, response.visits, response.addresses)
        }
    }
    @SyncActor
    private func fetchPhoneTerritoryDataFromServer() async throws -> ( [PhoneTerritory], [PhoneNumber], [PhoneCall]) {
        if await authorizationLevelManager.existsAdminCredentials() {
            let result = await AdminService().allPhoneData()
            switch result {
            case .success(let response):
                return (response.territories, response.numbers, response.calls)
            case .failure(let error):
                throw error
            }
        } else if await authorizationLevelManager.existsPhoneCredentials() {
            let result = await UserService().allPhoneData()
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
        return try await UserService().getRecalls().get()
    }

    @SyncActor
    private func comparingAndSynchronize<T: Identifiable & Equatable & Sendable>(
        apiList: [T],
        dbList: [T],
        updateMethod: @Sendable @escaping ([T]) async -> Result<String, Error>,
        addMethod: @Sendable @escaping ([T]) async -> Result<String, Error>,
        deleteMethod: @Sendable @escaping ([T]) async -> Result<String, Error>
    ) async {
        // Initialize the OperationQueue for background batching
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 3  // Adjust based on performance needs

        // Prepare lists for batching
        var updates: [T] = []
        var additions: [T] = []
        
        // Dictionary setup for identifying updates, additions, and deletions
        var dbDict = Dictionary(dbList.map { ($0.id, $0) }, uniquingKeysWith: { (_, new) in new })
        for apiModel in apiList {
            if let dbModel = dbDict[apiModel.id] {
                if dbModel != apiModel {
                    updates.append(apiModel)
                }
                dbDict.removeValue(forKey: apiModel.id)
            } else {
                additions.append(apiModel)
            }
        }
        let deletions = Array(dbDict.values)

        // Helper functions for batch processing in the background
        func handleUpdates(_ updates: [T]) -> Operation {
            let operation = BlockOperation {
                Task {
                    let result = await updateMethod(updates)
                    switch result {
                    case .success(let message):
                        print("Batch Update Success: \(message)")
                    case .failure(let error):
                        print("Batch Update Error: \(error)")
                    }
                }
            }
            operationQueue.addOperation(operation)
            return operation
        }

        func handleAdditions(_ additions: [T]) -> Operation {
            let operation = BlockOperation {
                Task {
                    let result = await addMethod(additions)
                    switch result {
                    case .success(let message):
                        print("Batch Addition Success: \(message)")
                    case .failure(let error):
                        print("Batch Addition Error: \(error)")
                    }
                }
            }
            operationQueue.addOperation(operation)
            return operation
        }

        func handleDeletions(_ deletions: [T]) -> Operation {
            let operation = BlockOperation {
                Task {
                    let result = await deleteMethod(deletions)
                    switch result {
                    case .success(let message):
                        print("Batch Deletion Success: \(message)")
                    case .failure(let error):
                        print("Batch Deletion Error: \(error)")
                    }
                }
            }
            operationQueue.addOperation(operation)
            return operation
        }

        // Trigger batch operations
        let updateOp = !updates.isEmpty ? handleUpdates(updates) : nil
        let additionOp = !additions.isEmpty ? handleAdditions(additions) : nil
        let deletionOp = !deletions.isEmpty ? handleDeletions(deletions) : nil

        // Add a completion barrier block that runs after all operations are finished
        operationQueue.addBarrierBlock {
            Task { @MainActor in
                print("All batch operations completed.")
                // Perform any final actions that require main thread access
            }
        }

        // Optional: Ensure completion by adding dependencies
        if let updateOp = updateOp, let additionOp = additionOp {
            additionOp.addDependency(updateOp)
        }
        if let deletionOp = deletionOp, let updateOp = updateOp {
            deletionOp.addDependency(updateOp)
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
}

struct UserAction {
    var userToken: UserToken
    var isBlocked: Bool
}
