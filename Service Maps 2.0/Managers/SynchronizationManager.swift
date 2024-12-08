//
//  SynchronizationManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/1/23.
//

import Foundation
import Combine
import GRDB

//MARK: - Global Actor

@globalActor actor SyncActor: GlobalActor {
    static var shared = SyncActor()
}

//MARK: - Synchronization Manager

@MainActor
class SynchronizationManager: ObservableObject {
    //MARK: - Shared Instance
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
    
    //MARK: - Synchronization
    
    @SyncActor
    func synchronize() async {
        let startSync = Date()
        print("Synchronization started at \(startSync)")
        
        // Store initial admin and phone credentials at the start
        let startInitialCreds = Date()
        let initialIsAdmin = await AuthorizationLevelManager().existsAdminCredentials()
        let initialHasPhoneCredentials = await AuthorizationLevelManager().existsPhoneCredentials()
        let endInitialCreds = Date()
        print(initialIsAdmin ? "Admin credentials found" : "No admin credentials found")
        print("Initial credential check completed in \(endInitialCreds.timeIntervalSince(startInitialCreds)) seconds")
        
        
        // Mark synchronization as not completed
        DispatchQueue.main.async {
            self.dataStore.synchronized = false
        }
        
        do {
            //MARK: Start API Fetch
            // Fetch all data concurrently
            let startFetchApi = Date()
            async let tokenData = fetchTokensFromServer()
            async let territoryData = fetchTerritoriesFromServer()
            async let phoneData = fetchPhoneTerritoryDataFromServer()
            async let recallsData = fetchRecallsFromServer()
            
            let ((tokens, userTokens, tokenTerritories),
                 (territories, houses, visits, territoryAddresses),
                 (phoneTerritories, phoneNumbers, phoneCalls),
                 recalls) = try await (tokenData, territoryData, phoneData, recallsData)
            let endFetchApi = Date()
            print("API data fetch completed in \(endFetchApi.timeIntervalSince(startFetchApi)) seconds")
            
            //MARK: Start Database Fetch
            // Fetch local data concurrently
            let startFetchDb = Date()
            async let tokensDb = handleResult(await grdbManager.fetchAllAsync(Token.self))
            async let userTokensDb = handleResult(await grdbManager.fetchAllAsync(UserToken.self))
            async let territoriesDb = handleResult(await grdbManager.fetchAllAsync(Territory.self))
            async let housesDb = handleResult(await grdbManager.fetchAllAsync(House.self))
            async let visitsDb = handleResult(await grdbManager.fetchAllAsync(Visit.self))
            async let territoryAddressesDb = handleResult(await grdbManager.fetchAllAsync(TerritoryAddress.self))
            async let tokenTerritoriesDb = handleResult(await grdbManager.fetchAllAsync(TokenTerritory.self))
            async let phoneTerritoriesDb = handleResult(await grdbManager.fetchAllAsync(PhoneTerritory.self))
            async let phoneCallsDb = handleResult(await grdbManager.fetchAllAsync(PhoneCall.self))
            async let phoneNumbersDb = handleResult(await grdbManager.fetchAllAsync(PhoneNumber.self))
            async let recallsDb = handleResult(await grdbManager.fetchAllAsync(Recalls.self))
            
            let dbResults = try await (
                tokensDb, userTokensDb, territoriesDb, housesDb, visitsDb,
                territoryAddressesDb, tokenTerritoriesDb, phoneTerritoriesDb,
                phoneCallsDb, phoneNumbersDb, recallsDb
            )
            let endFetchDb = Date()
            print("Database fetch completed in \(endFetchDb.timeIntervalSince(startFetchDb)) seconds")
            
            // Perform synchronization operations concurrently
            let startSyncOps = Date()
            //MARK: Start Synchronization Operations
            // Perform synchronization operations concurrently
            try await withThrowingTaskGroup(of: Void.self) { group in
                // Tokens synchronization
                group.addTask {
                    await self.comparingAndSynchronize(
                        apiList: tokens,
                        dbList: dbResults.0,
                        updateMethod: self.grdbManager.editBulkAsync,
                        addMethod: self.grdbManager.addBulkAsync,
                        deleteMethod: self.grdbManager.deleteBulkAsync
                    )
                }
                
                // User Tokens synchronization
                group.addTask {
                    await self.comparingAndSynchronize(
                        apiList: userTokens,
                        dbList: dbResults.1,
                        updateMethod: self.grdbManager.editBulkAsync,
                        addMethod: self.grdbManager.addBulkAsync,
                        deleteMethod: { deletions in
                            let compositeKeyForUserTokens: @Sendable (UserToken) -> [String: any DatabaseValueConvertible]? = { userToken in
                                return [
                                    "userId": userToken.userId,
                                    "token": userToken.token
                                ]
                            }
                            return await self.grdbManager.deleteBulkCompositeKeysAsync(deletions, compositeKey: compositeKeyForUserTokens)
                        }
                    )
                }
                
                // Territories synchronization
                group.addTask {
                    await self.comparingAndSynchronize(
                        apiList: territories,
                        dbList: dbResults.2,
                        updateMethod: self.grdbManager.editBulkAsync,
                        addMethod: self.grdbManager.addBulkAsync,
                        deleteMethod: self.grdbManager.deleteBulkAsync
                    )
                }
                
                // Houses synchronization
                group.addTask {
                    await self.comparingAndSynchronize(
                        apiList: houses,
                        dbList: dbResults.3,
                        updateMethod: self.grdbManager.editBulkAsync,
                        addMethod: self.grdbManager.addBulkAsync,
                        deleteMethod: self.grdbManager.deleteBulkAsync
                    )
                }
                
                // Visits synchronization
                group.addTask {
                    await self.comparingAndSynchronize(
                        apiList: visits,
                        dbList: dbResults.4,
                        updateMethod: self.grdbManager.editBulkAsync,
                        addMethod: self.grdbManager.addBulkAsync,
                        deleteMethod: self.grdbManager.deleteBulkAsync
                    )
                }
                
                // Territory Addresses synchronization
                group.addTask {
                    await self.comparingAndSynchronize(
                        apiList: territoryAddresses,
                        dbList: dbResults.5,
                        updateMethod: self.grdbManager.editBulkAsync,
                        addMethod: self.grdbManager.addBulkAsync,
                        deleteMethod: self.grdbManager.deleteBulkAsync
                    )
                }
                
                // Token Territories synchronization
                group.addTask {
                    await self.comparingAndSynchronizeTokenTerritories(
                        apiList: tokenTerritories,
                        dbList: dbResults.6
                    )
                }
                
                // Phone Territories synchronization
                group.addTask {
                    await self.comparingAndSynchronize(
                        apiList: phoneTerritories,
                        dbList: dbResults.7,
                        updateMethod: self.grdbManager.editBulkAsync,
                        addMethod: self.grdbManager.addBulkAsync,
                        deleteMethod: self.grdbManager.deleteBulkAsync
                    )
                }
                
                // Phone Calls synchronization
                group.addTask {
                    await self.comparingAndSynchronize(
                        apiList: phoneCalls,
                        dbList: dbResults.8,
                        updateMethod: self.grdbManager.editBulkAsync,
                        addMethod: self.grdbManager.addBulkAsync,
                        deleteMethod: self.grdbManager.deleteBulkAsync
                    )
                }
                
                // Phone Numbers synchronization
                group.addTask {
                    await self.comparingAndSynchronize(
                        apiList: phoneNumbers,
                        dbList: dbResults.9,
                        updateMethod: self.grdbManager.editBulkAsync,
                        addMethod: self.grdbManager.addBulkAsync,
                        deleteMethod: self.grdbManager.deleteBulkAsync
                    )
                }
                
                // Recalls synchronization
                group.addTask {
                    await self.comparingAndSynchronize(
                        apiList: recalls,
                        dbList: dbResults.10,
                        updateMethod: self.grdbManager.editBulkAsync,
                        addMethod: self.grdbManager.addBulkAsync,
                        deleteMethod: self.grdbManager.deleteBulkAsync
                    )
                }
                
                
                // Wait for all synchronization tasks to complete
                try await group.waitForAll()
            }
            let endSyncOps = Date()
            print("Synchronization operations completed in \(endSyncOps.timeIntervalSince(startSyncOps)) seconds")
            
            // Finalize synchronization
            await startupProcess(synchronizing: false)
            DispatchQueue.main.async {
                self.dataStore.lastTime = Date.now
                self.dataStore.synchronized = true
            }
            let endSync = Date()
            print("Synchronization finalized at \(endSync), total duration: \(endSync.timeIntervalSince(startSync)) seconds")
        } catch {
            print("Synchronization failed with error: \(error.localizedDescription)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.dataStore.synchronized = true
            }
        }
    }
    
    //MARK: - Fetch Tokens
    // Helper Functions for Fetching Data from Server]
    @SyncActor
    private func fetchTokensFromServer() async throws -> ([Token], [UserToken], [TokenTerritory]) {

        var tokensApi = [Token]()
        var userTokensApi = [UserToken]()
        var tokenTerritoriesApi = [TokenTerritory]()

        let tokenApi = TokenService()
        
        let result = try await tokenApi.loadAllTokens().get()
        
        tokensApi.append(contentsOf: result.map {
            Token(
                id: $0.id,
                name: $0.name,
                owner: $0.owner,
                congregation: $0.congregation,
                moderator: $0.moderator,
                expire: $0.expire,
                user: $0.user
            )
        })
        
        result.forEach { it in
            userTokensApi.append(contentsOf: it.token_users.map { user in
                UserToken(
                    token: it.id,
                    userId: user.id,
                    name: user.user,
                    blocked: user.blocked
                )
            })
        }
        
        result.forEach { it in
            tokenTerritoriesApi.append(contentsOf: it.token_territories)
        }

        return (tokensApi, userTokensApi, tokenTerritoriesApi)
    }
    
    //MARK: - Fetch Territories
    @SyncActor
    private func fetchTerritoriesFromServer() async throws -> ([Territory], [House], [Visit], [TerritoryAddress]) {
        
        if await authorizationLevelManager.existsAdminCredentials() {
            let result = try await AdminService().all().get()
            // Start all tasks concurrently using async let
            async let territories: [Territory] = result.territories.map {
                Territory(
                    id: $0.id,
                    congregation: result.id,
                    number: Int32($0.number),
                    description: $0.description,
                    image: $0.image
                )
            }

            async let addresses: [TerritoryAddress] = result.territories.flatMap { territory in
                territory.addresses.map {
                    TerritoryAddress(
                        id: $0.id,
                        territory: $0.territory,
                        address: $0.address,
                        floors: $0.floors
                    )
                }
            }

            async let houses: [House] = result.territories.flatMap { territory in
                territory.addresses.flatMap { address in
                    address.houses.map {
                        House(
                            id: $0.id,
                            territory_address: $0.territory_address,
                            number: $0.number,
                            floor: String($0.floor ?? 0)
                        )
                    }
                }
            }

            async let visits: [Visit] = result.territories.flatMap { territory in
                territory.addresses.flatMap { address in
                    address.houses.flatMap { house in
                        house.visits.map {
                            Visit(
                                id: $0.id,
                                house: $0.house,
                                date: $0.date,
                                symbol: $0.symbol,
                                notes: $0.notes,
                                user: $0.user
                            )
                        }
                    }
                }
            }

            // Await all tasks simultaneously
            let (territoriesResult, addressesResult, housesResult, visitsResult) = await (territories, addresses, houses, visits)
            return (territoriesResult, housesResult, visitsResult, addressesResult)
        } else {
            let response = try await UserService().loadTerritoriesNew().get()
            
            let territoriesMap = response.map {
                Territory(
                    id: $0.id,
                    congregation: $0.id,
                    number: Int32($0.number),
                    description: $0.description,
                    image: $0.image
                )
            }

            let addressesMap = response.flatMap {
                $0.addresses.map {
                    TerritoryAddress(
                        id: $0.id,
                        territory: $0.territory,
                        address: $0.address,
                        floors: $0.floors
                    )
                }
            }

            let housesMap = response.flatMap {
                $0.addresses.flatMap { address in
                    address.houses.map {
                        House(
                            id: $0.id,
                            territory_address: $0.territory_address,
                            number: $0.number,
                            floor: String($0.floor ?? 0)
                        )
                    }
                }
            }

            let visitsMap = response.flatMap {
                $0.addresses.flatMap { address in
                    address.houses.flatMap { house in
                        house.visits.map {
                            Visit(
                                id: $0.id,
                                house: $0.house,
                                date: $0.date,
                                symbol: $0.symbol,
                                notes: $0.notes,
                                user: $0.user
                            )
                        }
                    }
                }
            }

            return (territoriesMap, housesMap, visitsMap, addressesMap)
        }
    }
    
    //MARK: - Fetch Phone Territories
    @SyncActor
    private func fetchPhoneTerritoryDataFromServer() async throws -> ([PhoneTerritory], [PhoneNumber], [PhoneCall]) {
        
        let adminCredentials = await authorizationLevelManager.existsAdminCredentials()
        let phoneCredentials = await authorizationLevelManager.existsPhoneCredentials()
        
        // Early return if no valid credentials
        guard adminCredentials || phoneCredentials else {
            return ([], [], [])
        }
        
        // Determine service based on credentials
        let result: Result<CongregationWithAllPhone, any Error> = await {
            if adminCredentials {
                return await AdminService().allPhone()
            } else if phoneCredentials {
                return await UserService().loadPhonesNew()
            } else {
                fatalError("This should never happen due to earlier guard check")
            }
        }()
        
        // Process the result
        switch result {
        case .success(let response):
            // Map phone territories
            let phoneTerritories = response.phone_territories.map {
                PhoneTerritory(
                    id: $0.id,
                    congregation: response.id,
                    number: Int64($0.number),
                    description: $0.description,
                    image: $0.image
                )
            }
            
            // Map phone numbers
            let phoneNumbers = response.phone_territories.flatMap { territory in
                territory.numbers.map {
                    PhoneNumber(
                        id: $0.id,
                        congregation: $0.congregation,
                        number: $0.number,
                        territory: $0.territory,
                        house: $0.house
                    )
                }
            }
            
            // Map phone calls
            let phoneCalls = response.phone_territories.flatMap { territory in
                territory.numbers.flatMap { number in
                    number.calls.map {
                        PhoneCall(
                            id: $0.id,
                            phonenumber: $0.phonenumber,
                            date: $0.date,
                            notes: $0.notes,
                            user: $0.user
                        )
                    }
                }
            }
            
            return (phoneTerritories, phoneNumbers, phoneCalls)
            
        case .failure(let error):
            throw error
        }
    }
    
    //MARK: - Fetch Recalls
    @SyncActor
    private func fetchRecallsFromServer() async throws -> [Recalls] {
        return try await UserService().getRecalls().get()
    }
    
    //MARK: - Comparing and Synchronize
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
        operationQueue.maxConcurrentOperationCount = 10  // Adjust based on performance needs
        
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
                Task.detached {
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
    
    //MARK: - Comparing and Synchronize Token Territories
    @BackgroundActor
    private func comparingAndSynchronizeTokenTerritories(apiList: [TokenTerritory], dbList: [TokenTerritory]) async {
        
        struct TokenTerritoryKey: Hashable {
            let token: String
            let territory: String
        }

        let apiDict = Dictionary(apiList.map { (TokenTerritoryKey(token: $0.token, territory: $0.territory), $0) },
                                 uniquingKeysWith: { $1 })
        let dbDict = Dictionary(dbList.map { (TokenTerritoryKey(token: $0.token, territory: $0.territory), $0) },
                                uniquingKeysWith: { $1 })
        
        // Initialize sets for comparisons
        let apiKeys = Set(apiDict.keys)
        let dbKeys = Set(dbDict.keys)
        
        // Find additions, deletions, and updates
        let additionsKeys = apiKeys.subtracting(dbKeys)
        let deletionsKeys = dbKeys.subtracting(apiKeys)
        let updatesKeys = apiKeys.intersection(dbKeys).filter { apiDict[$0] != dbDict[$0] }
        
        // Retrieve the actual entities
        let additions = additionsKeys.compactMap { apiDict[$0] }
        let deletions = deletionsKeys.compactMap { dbDict[$0] }
        let updates = updatesKeys.compactMap { apiDict[$0] }
        
        // Process Additions
        if !additions.isEmpty {
            print("Adding \(additions.count) token territories")
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    _ = await self.grdbManager.addBulkAsync(additions)
                }
            }
        }
        
        // Process Updates
        if !updates.isEmpty {
            print("Updating \(updates.count) token territories")
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    _ = await self.grdbManager.editBulkAsync(updates)
                }
            }
        }
        
        // Process Deletions
        if !deletions.isEmpty {
            print("Deleting \(deletions.count) token territories")
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    _ = await self.grdbManager
                        .deleteBulkCompositeKeysAsync(deletions) { object in
                            let tokenTerritoryCompositeKey: (TokenTerritory) -> [String: any DatabaseValueConvertible]? = { tokenTerritory in
                                return [
                                    "token": object.token,
                                    "territory": object.territory
                                ]
                            }
                            return tokenTerritoryCompositeKey(object)
                        }
                }
            }
        }
    }
    
    @SyncActor
    func handleResult<T>(_ result: Result<[T], Error>) throws -> [T] {
        switch result {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        }
    }
}


