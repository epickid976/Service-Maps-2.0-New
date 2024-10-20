//
//  GRDBManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 10/17/24.
//

import GRDB
import Foundation
import Combine
import SwiftUICore

@globalActor actor BackgroundActor: GlobalActor {
    static var shared = BackgroundActor()
}

extension BackgroundActor {
    // Custom run function
    static func run<T>(_ operation: @escaping () async -> T) async -> T {
        await operation()
    }
}

class GRDBManager: ObservableObject {
    static let shared = GRDBManager()
    var dbPool: DatabasePool  // Use DatabasePool for concurrent reads and writes
    
    @ObservedObject var dataStore = StorageManager.shared
    
    var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Setup code with DatabasePool for concurrent access
        let databasePath = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("ServiceMaps.sqlite").path
        
        // Initialize DatabasePool
        dbPool = try! DatabasePool(path: databasePath)
        try! setupMigrations()
    }
    
    // Setup migrations
    private func setupMigrations() throws {
        var migrator = DatabaseMigrator()
        
        // Migration to create the "territories" table
        migrator.registerMigration("createTerritories") { db in
            try db.create(table: "territories") { t in
                t.column("id", .text).primaryKey()
                t.column("congregation", .text).notNull()
                t.column("number", .integer).notNull()
                t.column("description", .text).notNull()
                t.column("image", .text)
            }
        }
        
        // Migration to create the "territory_addresses" table (without foreign key constraint)
        migrator.registerMigration("createTerritoryAddresses") { db in
            try db.create(table: "territory_addresses") { t in
                t.column("id", .text).primaryKey()
                t.column("territory", .text).notNull().indexed() // Removed .references()
                t.column("address", .text).notNull()
                t.column("floors", .integer)
            }
        }
        
        // Migration to create the "houses" table (without foreign key constraint)
        migrator.registerMigration("createHouses") { db in
            try db.create(table: "houses") { t in
                t.column("id", .text).primaryKey()
                t.column("territory_address", .text).notNull().indexed() // Removed .references()
                t.column("number", .text).notNull()
                t.column("floor", .text)
            }
        }
        
        // Migration to create the "visits" table (without foreign key constraint)
        migrator.registerMigration("createVisits") { db in
            try db.create(table: "visits") { t in
                t.column("id", .text).primaryKey()
                t.column("house", .text).notNull().indexed() // Removed .references()
                t.column("date", .integer).notNull()
                t.column("symbol", .text).notNull()
                t.column("notes", .text).notNull()
                t.column("user", .text).notNull()
            }
        }
        
        // Migration to create the "tokens" table
        migrator.registerMigration("createTokens") { db in
            try db.create(table: "tokens") { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("owner", .text).notNull()
                t.column("congregation", .text).notNull()
                t.column("moderator", .boolean).notNull()
                t.column("expire", .integer)
                t.column("user", .text)
            }
        }
        
        // Migration to create the "token_territories" table
        migrator.registerMigration("createTokenTerritories") { db in
            try db.create(table: "token_territories") { t in
                t.column("id", .text).primaryKey()
                t.column("token", .text).notNull() // Removed .references("tokens", onDelete: .cascade)
                t.column("territory", .text).notNull() // Removed .references("territories", onDelete: .cascade)
            }
        }
        
        // Migration to create the "phone_territories" table
        migrator.registerMigration("createPhoneTerritories") { db in
            try db.create(table: "phone_territories") { t in
                t.column("id", .text).primaryKey()
                t.column("congregation", .text).notNull()
                t.column("number", .integer).notNull()
                t.column("description", .text).notNull()
                t.column("image", .text)
            }
        }
        
        // Migration to create the "phone_numbers" table
        migrator.registerMigration("createPhoneNumbers") { db in
            try db.create(table: "phone_numbers") { t in
                t.column("id", .text).primaryKey()
                t.column("congregation", .text).notNull()
                t.column("number", .text).notNull()
                t.column("territory", .text).notNull() // Removed .references("phone_territories", onDelete: .cascade)
                t.column("house", .text)
            }
        }
        
        // Migration to create the "phone_calls" table
        migrator.registerMigration("createPhoneCalls") { db in
            try db.create(table: "phone_calls") { t in
                t.column("id", .text).primaryKey()
                t.column("phonenumber", .text).notNull() // Removed .references("phone_numbers", onDelete: .cascade)
                t.column("date", .integer).notNull()
                t.column("notes", .text).notNull()
                t.column("user", .text).notNull()
            }
        }
        
        // Migration to create the "user_tokens" table
        migrator.registerMigration("createUserTokens") { db in
            try db.create(table: "user_tokens") { t in
                t.column("id", .text).primaryKey()
                t.column("token", .text).notNull() // Removed .references("tokens", onDelete: .cascade)
                t.column("userId", .text).notNull()
                t.column("name", .text).notNull()
                t.column("blocked", .boolean).notNull()
            }
        }
        
        migrator.registerMigration("createRecalls") { db in
            try db.create(table: "recalls") { t in
                t.column("id", .integer).primaryKey()
                t.column("user", .text).notNull()
                t.column("house", .text).notNull() // Removed .references("houses", onDelete: .cascade)
            }
        }
        
        // Apply all migrations
        try migrator.migrate(dbPool)
    }
    
    // MARK: - Synchronous CRUD Methods
    
    // General Add using Result type
    func add<T: MutablePersistableRecord>(_ object: T) -> Result<Void, Error> {
        do {
            try dbPool.write { db in  // Use dbPool.write for writes
                var object = object
                try object.insert(db)
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    // General Edit using Result type
    func edit<T: MutablePersistableRecord>(_ object: T) -> Result<Void, Error> {
        do {
            try dbPool.write { db in
                try object.update(db)
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    // General Delete using Result type
    @discardableResult
    func delete<T: MutablePersistableRecord>(_ object: T) -> Result<Void, Error> {
        do {
            try dbPool.write { db in
                try object.delete(db)
                return // Explicitly return from the write block
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    // General Fetch method to retrieve all objects of a type using Result type
    func fetchAll<T: FetchableRecord & TableRecord>(_ type: T.Type) -> Result<[T], Error> {
        do {
            let objects = try dbPool.read { db in  // Use dbPool.read for concurrent reads
                try T.fetchAll(db)
            }
            return .success(objects)
        } catch {
            return .failure(error)
        }
    }
    
    func fetchById<T: FetchableRecord & MutablePersistableRecord, Key: DatabaseValueConvertible>(_ type: T.Type, id: Key) -> Result<T?, Error> {
        do {
            let object = try dbPool.read { db in
                try T.fetchOne(db, key: id)
            }
            return .success(object)
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Asynchronous CRUD Methods
    
    @BackgroundActor
    func addAsync<T: MutablePersistableRecord>(_ object: T) async -> Result<String, Error> {
        do {
            try await dbPool.write { db in
                var mutableObject = object  // Make a mutable copy inside the write block
                try mutableObject.insert(db)  // Now insert the mutable object
            }
            return .success("Added successfully")
        } catch {
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func editAsync<T: MutablePersistableRecord>(_ object: T) async -> Result<String, Error> {
        do {
            try await dbPool.write { db in
                try object.update(db)
            }
            return .success("Edited successfully")
        } catch {
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func deleteAsync<T: MutablePersistableRecord>(_ object: T) async -> Result<String, Error> {
        do {
            _ = try await dbPool.write { db in
                try object.delete(db)
            }
            return .success("Deleted successfully")
        } catch {
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func addBulkAsync<T: MutablePersistableRecord>(_ objects: [T]) async -> Result<String, Error> {
        do {
            try await dbPool.write { db in
                for object in objects {
                    var mutableObject = object // Make a mutable copy inside the write block
                    try mutableObject.insert(db)
                }
            }
            return .success("Bulk added successfully")
        } catch {
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func deleteBulkAsync<T: MutablePersistableRecord>(_ objects: [T]) async -> Result<String, Error> {
        do {
            try await dbPool.write { db in
                for object in objects {
                    try object.delete(db)
                }
            }
            return .success("Bulk deleted successfully")
        } catch {
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func editBulkAsync<T: MutablePersistableRecord>(_ objects: [T]) async -> Result<String, Error> {
        do {
            try await dbPool.write { db in
                for object in objects {
                    try object.update(db)
                }
            }
            return .success("Bulk edited successfully")
        } catch {
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func fetchAllAsync<T: FetchableRecord & TableRecord>(_ type: T.Type) async -> Result<[T], Error> {
        do {
            let result = try await dbPool.read { db in
                try T.fetchAll(db)
            }
            return .success(result)
        } catch {
            return .failure(error)
        }
    }

    @BackgroundActor
    func fetchByIdAsync<T: FetchableRecord & MutablePersistableRecord, Key: DatabaseValueConvertible>(_ type: T.Type, id: Key) async -> Result<T?, Error> {
        do {
            let result = try await dbPool.read { db in
                try T.fetchOne(db, key: id)
            }
            return .success(result)
        } catch {
            return .failure(error)
        }
    }
    
    // Fetch the first territory from the Territory table
    func fetchFirstTerritory() -> Territory? {
        do {
            return try dbPool.read { db in
                try Territory.fetchOne(db) // Fetch the first Territory object
            }
        } catch {
            return nil
        }
    }
    
    // MARK: - Main Territory Data Fetching
    
    func getTerritoryData() -> AnyPublisher<[TerritoryDataWithKeys], Error> {
        return Publishers.CombineLatest3(
            fetchTerritories(),
            fetchAddresses(),
            fetchHouses()
        )
        .flatMap { [weak self] territories, addresses, houses -> AnyPublisher<[TerritoryDataWithKeys], Error> in
            guard let self = self else {
                return Fail(error: DatabaseError.instanceDeallocated).eraseToAnyPublisher()
            }
            
            let territoryData = self.processTerritoryData(
                territories: territories,
                addresses: addresses,
                houses: houses
            )
            
            return self.fetchAndCombineKeys(for: territoryData)
                .eraseToAnyPublisher()
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    // MARK: - Individual Data Fetching
    private func fetchTerritories() -> AnyPublisher<[Territory], Error> {
        ValueObservation.tracking { db in
            try Territory.fetchAll(db)
        }
        .publisher(in: dbPool)
        .eraseToAnyPublisher()
    }

    private func fetchAddresses() -> AnyPublisher<[TerritoryAddress], Error> {
        ValueObservation.tracking { db in
            try TerritoryAddress.fetchAll(db)
        }
        .publisher(in: dbPool)
        .eraseToAnyPublisher()
    }

    private func fetchHouses() -> AnyPublisher<[House], Error> {
        ValueObservation.tracking { db in
            try House.fetchAll(db)
        }
        .publisher(in: dbPool)
        .eraseToAnyPublisher()
    }

    // MARK: - Data Processing
    private func processTerritoryData(
        territories: [Territory],
        addresses: [TerritoryAddress],
        houses: [House]
    ) -> [TerritoryData] {
        let territoryAddresses = Dictionary(grouping: addresses, by: { $0.territory })
        let territoryHouses = Dictionary(grouping: houses, by: { $0.territory_address })
        let authManager = AuthorizationLevelManager()
        
        return territories
            .map { territory in
                let currentAddresses = territoryAddresses[territory.id] ?? []
                let currentHouses = currentAddresses.flatMap { territoryHouses[$0.id] ?? [] }
                
                return TerritoryData(
                    territory: territory,
                    addresses: currentAddresses,
                    housesQuantity: currentHouses.count,
                    accessLevel: authManager.getAccessLevel(model: territory) ?? .User
                )
            }
            .sorted(by: { $0.territory.number < $1.territory.number })
    }

    // MARK: - Key Processing
    private func fetchAndCombineKeys(for territoryData: [TerritoryData]) -> AnyPublisher<[TerritoryDataWithKeys], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(DatabaseError.instanceDeallocated))
                return
            }
            
            do {
                let result = try self.dbPool.read { db in
                    let tokens = try Token.fetchAll(db)
                    let territoryTokens = try TokenTerritory.fetchAll(db)
                    
                    let tokensByTerritory = Dictionary(
                        grouping: territoryTokens,
                        by: { $0.territory }
                    )
                    
                    return self.combineTerritoriesWithKeys(
                        territoryData: territoryData,
                        tokens: tokens,
                        tokensByTerritory: tokensByTerritory
                    )
                }
                promise(.success(result))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }

    private func combineTerritoriesWithKeys(
        territoryData: [TerritoryData],
        tokens: [Token],
        tokensByTerritory: [String: [TokenTerritory]]
    ) -> [TerritoryDataWithKeys] {
        var result = [TerritoryDataWithKeys]()

        // Existing logic to group and combine keys
        var groupedData = [Set<String>: [TerritoryData]]()
        for data in territoryData {
            let territoryTokens = tokensByTerritory[data.territory.id] ?? []
            let tokenIds = Set(territoryTokens.compactMap { $0.token })
            groupedData[tokenIds, default: []].append(data)
        }
        
        for (tokenIds, territories) in groupedData {
            let associatedTokens = tokens.filter { tokenIds.contains($0.id) }
            result.append(
                TerritoryDataWithKeys(
                    id: UUID(),
                    keys: associatedTokens,
                    territoriesData: territories.sorted { $0.territory.number < $1.territory.number }
                )
            )
        }
        return result
    }

    // MARK: - Error Types
    enum DatabaseError: Error {
        case instanceDeallocated
        // Add other specific error cases as needed
    }
    
    
    func getAddressData(territoryId: String) -> AnyPublisher<[AddressData], Never> {
        
        // Observations for addresses and houses
        let addressesObservation = ValueObservation.tracking { db in
            try TerritoryAddress.fetchAll(db) // Replace Address with your actual model
        }
        
        let housesObservation = ValueObservation.tracking { db in
            try House.fetchAll(db) // Replace House with your actual model
        }
        
        // Combine both observations
        let flow = Publishers.CombineLatest(
            addressesObservation
                .publisher(in: dbPool)
                .catch { _ in Just([]) } // Handle errors by emitting an empty array
                .setFailureType(to: Never.self), // Set failure type to Never
            
            housesObservation
                .publisher(in: dbPool)
                .catch { _ in Just([]) } // Handle errors by emitting an empty array
                .setFailureType(to: Never.self) // Set failure type to Never
        )
            .flatMap { addressData -> AnyPublisher<[AddressData], Never> in
                var data = [AddressData]()
                
                // Filter addresses by territoryId
                let addressesFiltered = addressData.0.filter { $0.territory == territoryId }
                
                // Loop through filtered addresses and count associated houses
                for address in addressesFiltered {
                    let housesQuantity = addressData.1.filter { $0.territory_address == address.id }.count
                    
                    data.append(AddressData(
                        id: UUID(),
                        address: address,
                        houseQuantity: housesQuantity,
                        accessLevel: AuthorizationLevelManager().getAccessLevel(model: address) ?? .User)
                    )
                }
                
                // Return the transformed data
                return Just(data)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        
        return flow
    }
    
    
    func getHouseData(addressId: String) -> AnyPublisher<[HouseData], Never> {
        
        // Observations for houses and visits
        let housesObservation = ValueObservation.tracking { db in
            try House.fetchAll(db) // Replace House with your actual model
        }
        
        let visitsObservation = ValueObservation.tracking { db in
            try Visit.fetchAll(db) // Replace Visit with your actual model
        }
        
        // Combine both observations
        let flow = Publishers.CombineLatest(
            housesObservation
                .publisher(in: dbPool)
                .catch { _ in Just([]) } // Handle errors by emitting an empty array
                .setFailureType(to: Never.self), // Set failure type to Never
            
            visitsObservation
                .publisher(in: dbPool)
                .catch { _ in Just([]) } // Handle errors by emitting an empty array
                .setFailureType(to: Never.self) // Set failure type to Never
        )
            .flatMap { houseData -> AnyPublisher<[HouseData], Never> in
                var data = [HouseData]()
                
                // Filter houses by addressId
                let housesFiltered = houseData.0.filter { $0.territory_address == addressId }
                
                // Loop through filtered houses and find the most recent visit
                for house in housesFiltered {
                    if let mostRecentVisit = houseData.1
                        .filter({ $0.house == house.id })
                        .max(by: { $0.date < $1.date }) {
                        
                        data.append(
                            HouseData(
                                id: UUID(),
                                house: house,
                                visit:  mostRecentVisit,
                                accessLevel: AuthorizationLevelManager().getAccessLevel(model: house) ?? .User
                            )
                        )
                    } else {
                        // Handle the case where there is no most recent visit
                        data.append(
                            HouseData(
                                id: UUID(),
                                house:  house,
                                visit: nil,
                                accessLevel: AuthorizationLevelManager().getAccessLevel(model: house) ?? .User
                            )
                        )
                    }
                }
                
                // Return the transformed data
                return Just(data)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        
        return flow
    }
    
    
    func getVisitData(houseId: String) -> AnyPublisher<[VisitData], Never> {
        
        // Observation for visits related to the houseId
        let visitsObservation = ValueObservation.tracking { db in
            try Visit.fetchAll(db) // Replace Visit with your actual model
        }
        
        // Set up a publisher to observe visits
        let flow = visitsObservation
            .publisher(in: dbPool)
            .catch { _ in Just([]) } // Handle errors by emitting an empty array
            .setFailureType(to: Never.self) // Set failure type to Never
        
            .flatMap { visits -> AnyPublisher<[VisitData], Never> in
                let email = self.dataStore.userEmail
                let name = self.dataStore.userName
                
                var data = [VisitData]()
                
                // Filter visits by houseId
                visits.filter { $0.house == houseId }.forEach { visit in
                    let visitModel = Visit(
                        id: visit.id,
                        house: visit.house,
                        date: visit.date,
                        symbol: visit.symbol,
                        notes: visit.notes,
                        user: name ?? ""
                    )
                    
                    // Append VisitData with access level
                    data.append(
                        VisitData(
                            id: UUID(),
                            visit: visit.user == email ? visitModel :  visit,
                            accessLevel: visit.user == email ? .Moderator : AuthorizationLevelManager().getAccessLevel(model: visit)
                        )
                    )
                }
                
                // Return the transformed visit data as a publisher
                return Just(data).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        
        return flow
    }
    
    
    func getKeyData() -> AnyPublisher<[KeyData], Never> {
        
        // Observations for tokens, territories, and token-territories
        let tokensObservation = ValueObservation.tracking { db in
            try Token.fetchAll(db) // Replace Token with your actual model
        }
        
        let territoriesObservation = ValueObservation.tracking { db in
            try Territory.fetchAll(db) // Replace Territory with your actual model
        }
        
        let tokenTerritoriesObservation = ValueObservation.tracking { db in
            try TokenTerritory.fetchAll(db) // Replace TokenTerritory with your actual model
        }
        
        // Combine the three observations
        let flow = Publishers.CombineLatest3(
            tokensObservation
                .publisher(in: dbPool)
                .catch { _ in Just([]) } // Handle errors by emitting an empty array
                .setFailureType(to: Never.self),
            
            territoriesObservation
                .publisher(in: dbPool)
                .catch { _ in Just([]) } // Handle errors by emitting an empty array
                .setFailureType(to: Never.self),
            
            tokenTerritoriesObservation
                .publisher(in: dbPool)
                .catch { _ in Just([]) } // Handle errors by emitting an empty array
                .setFailureType(to: Never.self)
        )
            .flatMap { keyData -> AnyPublisher<[KeyData], Never> in
                let myTokens = keyData.0
                let allTerritoriesDb = keyData.1
                let tokenTerritories = keyData.2
                var data = [KeyData]()
                
                // For each token, find the associated territories
                for token in myTokens {
                    var territories = [Territory]()
                    
                    tokenTerritories.filter { $0.token == token.id }.forEach { tokenTerritory in
                        if let territory = allTerritoriesDb.first(where: { $0.id == tokenTerritory.territory }) {
                            territories.append(territory)
                        }
                    }
                    
                    // Append KeyData with sorted territories
                    data.append(
                        KeyData(
                            id: UUID(),
                            key:  token,
                            territories: territories)
                    )
                }
                
                // Sort the data by token name and return as a publisher
                return Just(data.sorted { $0.key.name < $1.key.name })
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        
        return flow
    }
    
    
    func getPhoneData() -> AnyPublisher<[PhoneData], Never> {
        
        // Observations for phone territories and phone numbers
        let phoneTerritoriesObservation = ValueObservation.tracking { db in
            try PhoneTerritory.fetchAll(db) // Replace PhoneTerritory with your actual model
        }
        
        let phoneNumbersObservation = ValueObservation.tracking { db in
            try PhoneNumber.fetchAll(db) // Replace PhoneNumber with your actual model
        }
        
        // Combine both observations
        let combinedFlow = Publishers.CombineLatest(
            phoneTerritoriesObservation
                .publisher(in: dbPool)
                .catch { _ in Just([]) } // Handle errors by emitting an empty array
                .setFailureType(to: Never.self),
            
            phoneNumbersObservation
                .publisher(in: dbPool)
                .catch { _ in Just([]) } // Handle errors by emitting an empty array
                .setFailureType(to: Never.self)
        )
        
        // Transform the combined flow
        let transformedFlow = combinedFlow.flatMap { keyData -> AnyPublisher<[PhoneData], Never> in
            let phoneTerritories = keyData.0
            let phoneNumbers = keyData.1
            
            // Group phone numbers by territory
            let phoneNumbersByTerritory = Dictionary(grouping: phoneNumbers, by: { $0.territory })
            
            // Map phone territories to PhoneData
            let phoneDataList = phoneTerritories.map { territory -> PhoneData in
                let currentPhoneNumbers = phoneNumbersByTerritory[String(territory.id)] ?? []
                
                return PhoneData(
                    id: UUID(),
                    territory:  territory,
                    numbersQuantity: currentPhoneNumbers.count
                )
            }
            
            // Sort the phone data by territory number
            let sortedPhoneData = phoneDataList.sorted { $0.territory.number < $1.territory.number }
            
            return Just(sortedPhoneData)
                .eraseToAnyPublisher()
        }
        
        return transformedFlow.eraseToAnyPublisher()
    }
    
    
    func getPhoneNumbersData(phoneTerritoryId: String) -> AnyPublisher<[PhoneNumbersData], Never> {
        
        // Observations for phone numbers and phone calls
        let phoneNumbersObservation = ValueObservation.tracking { db in
            try PhoneNumber.fetchAll(db) // Replace PhoneNumber with your actual model
        }
        
        let phoneCallsObservation = ValueObservation.tracking { db in
            try PhoneCall.fetchAll(db) // Replace PhoneCall with your actual model
        }
        
        // Combine both observations
        let flow = Publishers.CombineLatest(
            phoneNumbersObservation
                .publisher(in: dbPool)
                .catch { _ in Just([]) } // Handle errors by emitting an empty array
                .setFailureType(to: Never.self),
            
            phoneCallsObservation
                .publisher(in: dbPool)
                .catch { _ in Just([]) } // Handle errors by emitting an empty array
                .setFailureType(to: Never.self)
        )
            .flatMap { keyData -> AnyPublisher<[PhoneNumbersData], Never> in
                let phoneNumbers = keyData.0
                let phoneCalls = keyData.1
                var data = [PhoneNumbersData]()
                
                // Filter phone numbers by phoneTerritoryId
                phoneNumbers.filter { $0.territory == phoneTerritoryId }.forEach { number in
                    // Find the most recent phone call for the phone number
                    let phoneCall = phoneCalls.filter { $0.phonenumber == number.id }
                        .sorted { $0.date > $1.date }
                        .first
                    
                    // Append the phone number data with the most recent phone call (if any)
                    data.append(
                        PhoneNumbersData(
                            id: UUID(),
                            phoneNumber:  number,
                            phoneCall: phoneCall != nil ?  phoneCall! : nil
                        )
                    )
                }
                
                // Return sorted phone numbers by house number
                let sortedData = data.sorted { $0.phoneNumber.house ?? "0" < $1.phoneNumber.house ?? "0" }
                
                return Just(sortedData)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        
        return flow
    }
    
    
    func getPhoneCallData(phoneNumberId: String) -> AnyPublisher<[PhoneCallData], Never> {
        
        // Observation for phone calls
        let phoneCallsObservation = ValueObservation.tracking { db in
            try PhoneCall.fetchAll(db) // Replace PhoneCall with your actual model
        }
        
        // Observe and transform phone calls
        let flow = phoneCallsObservation
            .publisher(in: dbPool)
            .catch { _ in Just([]) } // Handle errors by emitting an empty array
            .setFailureType(to: Never.self)
            .flatMap { phoneCalls -> AnyPublisher<[PhoneCallData], Never> in
                let email = self.dataStore.userEmail
                let name = self.dataStore.userName
                var data = [PhoneCallData]()
                
                // Filter phone calls by phoneNumberId
                phoneCalls.filter { $0.phonenumber == phoneNumberId }.forEach { call in
                    // Create a PhoneCall for each call
                    let callToAdd = PhoneCall(
                        id: call.id,
                        phonenumber: call.phonenumber,
                        date: call.date,
                        notes: call.notes,
                        user: (call.user == email ? name : call.user) ?? "" // Use current user's name if it's their call
                    )
                    
                    // Append PhoneCallData with access level
                    data.append(
                        PhoneCallData(
                            id: UUID(),
                            phoneCall: callToAdd,
                            accessLevel: self.phoneCallAccessLevel(call: call, email: email ?? "")
                        )
                    )
                }
                
                // Return the transformed phone call data as a publisher
                return Just(data)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        
        return flow
    }
    
    
    func getRecentTerritoryData() -> AnyPublisher<[RecentTerritoryData], Never> {
        
        // 1. ValueObservation for territories, addresses, houses, and visits
        let territoriesObservation = ValueObservation.tracking { db in
            let territories = try Territory.fetchAll(db)
            return territories
        }
        
        let addressesObservation = ValueObservation.tracking { db in
            let addresses = try TerritoryAddress.fetchAll(db)
            return addresses
        }
        
        let housesObservation = ValueObservation.tracking { db in
            let houses = try House.fetchAll(db)
            return houses
        }
        
        let twoWeeksAgoTimestamp: Int64 = Int64(Date().addingTimeInterval(-14 * 24 * 60 * 60).timeIntervalSince1970)

        let visitsPastTwoWeeksObservation = ValueObservation.tracking { db in
            let visits = try Visit.filter(sql: "date >= ?", arguments: [twoWeeksAgoTimestamp]).fetchAll(db)
            return visits
        }
        
        // 2. Create dictionaries for efficient lookups (addresses and houses)
        let addressDictPublisher = addressesObservation
            .publisher(in: dbPool)
            .map { addresses in
                return Dictionary(uniqueKeysWithValues: addresses.map { ($0.id, $0) })
            }
            .replaceError(with: [:]) // Handle errors by emitting an empty dictionary
            .eraseToAnyPublisher()
        
        let houseDictPublisher = housesObservation
            .publisher(in: dbPool)
            .map { houses in
                return Dictionary(uniqueKeysWithValues: houses.map { ($0.id, $0) })
            }
            .replaceError(with: [:]) // Handle errors by emitting an empty dictionary
            .eraseToAnyPublisher()
        
        // 3. Combine the relevant publishers
        return Publishers.CombineLatest3(
            territoriesObservation
                .publisher(in: dbPool)
                .replaceError(with: []) // Handle errors by emitting an empty array
                .setFailureType(to: Never.self),
            
            addressDictPublisher,
            houseDictPublisher
        )
        .flatMap { (territories, addressDict, houseDict) -> AnyPublisher<[RecentTerritoryData], Never> in
            
            // Subscribe to visitsPastTwoWeeks publisher once other data is ready
            return visitsPastTwoWeeksObservation
                .publisher(in: self.dbPool)
                .replaceError(with: []) // Handle errors by emitting an empty array
                .setFailureType(to: Never.self)
                .map { recentVisits in
                    
                    // Map recent visits to RecentTerritoryData
                    let mappedData = recentVisits.compactMap { visit -> RecentTerritoryData? in
                        guard let house = houseDict[visit.house] else {
                            return nil
                        }
                        guard let address = addressDict[house.territory_address] else {
                            return nil
                        }
                        guard let territory = territories.first(where: { $0.id == address.territory }) else {
                            return nil
                        }
                        return RecentTerritoryData(
                            id: UUID(),
                            territory: territory,
                            lastVisit: visit
                        )
                    }
                    
                    // Ensure unique territories
                    return mappedData.unique { $0.territory.id }
                }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    func getRecentPhoneTerritoryData() -> AnyPublisher<[RecentPhoneData], Never> {
        
        // 1. Observations for phone territories, phone numbers, and phone calls
        let phoneTerritoriesObservation = ValueObservation.tracking { db in
            try PhoneTerritory.fetchAll(db) // Replace PhoneTerritory with your actual model
        }
        
        let phoneNumbersObservation = ValueObservation.tracking { db in
            try PhoneNumber.fetchAll(db) // Replace PhoneNumber with your actual model
        }
        
        let twoWeeksAgoTimestamp: Int64 = Int64(Date().addingTimeInterval(-14 * 24 * 60 * 60).timeIntervalSince1970)

        let phoneCallsObservation = ValueObservation.tracking { db in
            try PhoneCall.filter(sql: "date >= ?", arguments: [twoWeeksAgoTimestamp]).fetchAll(db)
        }
        
        // 2. Create a dictionary for phone numbers
        let numberDictPublisher = phoneNumbersObservation
            .publisher(in: dbPool)
            .map { numbers in
                Dictionary(uniqueKeysWithValues: numbers.map { ($0.id, $0) })
            }
            .catch { _ in Just([String: PhoneNumber]()) } // Handle errors by emitting an empty dictionary
            .eraseToAnyPublisher()
        
        // 3. Combine the relevant publishers
        return Publishers.CombineLatest(
            phoneTerritoriesObservation
                .publisher(in: dbPool)
                .catch { _ in Just([]) } // Handle errors by emitting an empty array
                .setFailureType(to: Never.self),
            
            numberDictPublisher
        )
        .flatMap { (territories, numberDict) -> AnyPublisher<[RecentPhoneData], Never> in
            // Subscribe to phoneCalls only when other data is ready
            return phoneCallsObservation
                .publisher(in: self.dbPool)
                .catch { _ in Just([]) } // Handle errors by emitting an empty array
                .setFailureType(to: Never.self)
                .map { phoneCalls in
                    // Filter phone calls from the last two weeks and map to RecentPhoneData
                    phoneCalls.compactMap { call -> RecentPhoneData? in
                        guard let number = numberDict[call.phonenumber],
                              let territory = territories.first(where: { $0.id == number.territory }) else {
                            return nil
                        }
                        return RecentPhoneData(
                            id: UUID(),
                            territory:  territory,
                            lastCall: call
                        )
                    }
                    .unique { $0.territory.id } // Ensure unique territories
                }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    
    func getKeyUsers(token: Token) -> AnyPublisher<[UserToken], Never> {
        
        // 1. ValueObservation for user tokens
        let userTokensObservation = ValueObservation.tracking { db in
            try UserToken.fetchAll(db) // Replace UserToken with your actual model
        }
        
        // 2. Observe and filter user tokens based on the provided token ID
        return userTokensObservation
            .publisher(in: dbPool)
            .catch { _ in Just([]) } // Handle errors by emitting an empty array
            .setFailureType(to: Never.self)
            .flatMap { keyUsers -> AnyPublisher<[UserToken], Never> in
                var data = [UserToken]()
                
                // Filter user tokens based on token ID
                for user in keyUsers {
                    if user.token == token.id {
                        data.append( user)
                    }
                }
                
                // Sort the data by name
                data.sort { $0.name < $1.name }
                
                // Return the filtered and sorted data as a publisher
                return Just(data)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    
    func getRecalls() -> AnyPublisher<[RecallData], Never> {
        
        // Observations for the relevant tables
        let recallsObservation = ValueObservation.tracking { db in
            try Recalls.fetchAll(db)
        }
        
        let housesObservation = ValueObservation.tracking { db in
            try House.fetchAll(db)
        }
        
        let addressesObservation = ValueObservation.tracking { db in
            try TerritoryAddress.fetchAll(db)
        }
        
        let territoriesObservation = ValueObservation.tracking { db in
            try Territory.fetchAll(db)
        }
        
        let visitsObservation = ValueObservation.tracking { db in
            try Visit.fetchAll(db)
        }
        
        // Combine recalls, houses, and addresses
        let combinedFirstThree = Publishers.CombineLatest3(
            recallsObservation.publisher(in: dbPool).catch { _ in Just([]) },
            housesObservation.publisher(in: dbPool).catch { _ in Just([]) },
            addressesObservation.publisher(in: dbPool).catch { _ in Just([]) }
        )
        
        // Combine territories and visits
        let combinedNextTwo = Publishers.CombineLatest(
            territoriesObservation.publisher(in: dbPool).catch { _ in Just([]) },
            visitsObservation.publisher(in: dbPool).catch { _ in Just([]) }
        )
        
        // Combine both groups
        return Publishers.CombineLatest(combinedFirstThree, combinedNextTwo)
            .map { (firstThree, nextTwo) -> [RecallData] in
                let (recalls, houses, addresses) = firstThree
                let (territories, visits) = nextTwo
                
                var data = [RecallData]()
                
                // Process recalls and related data
                for recall in recalls {
                    guard let house = houses.first(where: { $0.id == recall.house }),
                          let address = addresses.first(where: { $0.id == house.territory_address }),
                          let territory = territories.first(where: { $0.id == address.territory }) else {
                        continue
                    }
                    
                    let visit = visits.first(where: { $0.house == house.id })
                    
                    // Append RecallData
                    data.append(
                        RecallData(
                            recall: recall,
                            territory: territory,
                            territoryAddress: address,
                            house: house,
                            visit: visit
                        )
                    )
                }
                
                return data
            }
            .eraseToAnyPublisher()
    }
    
    func phoneCallAccessLevel(call: PhoneCall, email: String) -> AccessLevel {
        if AuthorizationLevelManager().existsAdminCredentials() {
            return .Admin
        } else if call.user == email {
            return .Moderator
        } else {
            return .User
        }
    }
    
    
    func searchEverywhere(query: String, searchMode: SearchMode) -> AnyPublisher<[MySearchResult], Never> {
        
        // Observations for relevant tables
        let territoriesObservation = ValueObservation.tracking { db in
            try Territory.fetchAll(db)
        }
        
        let addressesObservation = ValueObservation.tracking { db in
            try TerritoryAddress.fetchAll(db)
        }
        
        let housesObservation = ValueObservation.tracking { db in
            try House.fetchAll(db)
        }
        
        let visitsObservation = ValueObservation.tracking { db in
            try Visit.fetchAll(db)
        }
        
        let phoneTerritoriesObservation = ValueObservation.tracking { db in
            try PhoneTerritory.fetchAll(db)
        }
        
        let numbersObservation = ValueObservation.tracking { db in
            try PhoneNumber.fetchAll(db)
        }
        
        let callsObservation = ValueObservation.tracking { db in
            try PhoneCall.fetchAll(db)
        }
        
        let combinedPublisher: AnyPublisher<[MySearchResult], Never>
        
        switch searchMode {
        case .Territories:
            // Combine the observations for territories, addresses, houses, and visits
            combinedPublisher = Publishers.CombineLatest4(
                territoriesObservation.publisher(in: dbPool).catch { _ in Just([]) },
                addressesObservation.publisher(in: dbPool).catch { _ in Just([]) },
                housesObservation.publisher(in: dbPool).catch { _ in Just([]) },
                visitsObservation.publisher(in: dbPool).catch { _ in Just([]) }
            )
            .map { (territories, addresses, houses, visits) -> [MySearchResult] in
                var results: [MySearchResult] = []
                
                // Search in territories
                territories.forEach { territory in
                    if String(territory.number).localizedCaseInsensitiveContains(query) || territory.description.localizedCaseInsensitiveContains(query) {
                        results.append(MySearchResult(type: .Territory, territory:  territory))
                    }
                }
                
                // Search in addresses
                addresses.forEach { address in
                    if address.address.localizedCaseInsensitiveContains(query),
                       let territory = territories.first(where: { $0.id == address.territory }) {
                        results.append(MySearchResult(type: .Address, territory:  territory, address:  address))
                    }
                }
                
                // Search in houses
                houses.forEach { house in
                    if house.number.localizedCaseInsensitiveContains(query),
                       let address = addresses.first(where: { $0.id == house.territory_address }),
                       let territory = territories.first(where: { $0.id == address.territory }) {
                        results.append(MySearchResult(type: .House, territory:  territory, address:  address, house:  house))
                    }
                }
                
                // Search in visits
                visits.forEach { visit in
                    if visit.notes.localizedCaseInsensitiveContains(query) || visit.user.localizedCaseInsensitiveContains(query),
                       let house = houses.first(where: { $0.id == visit.house }),
                       let address = addresses.first(where: { $0.id == house.territory_address }),
                       let territory = territories.first(where: { $0.id == address.territory }) {
                        results.append(MySearchResult(type: .Visit, territory:  territory, address:  address, house:  house, visit:  visit))
                    }
                }
                
                return results
            }
            .eraseToAnyPublisher()
            
        case .PhoneTerritories:
            // Combine the observations for phone territories, numbers, and calls
            combinedPublisher = Publishers.CombineLatest3(
                phoneTerritoriesObservation.publisher(in: dbPool).catch { _ in Just([]) },
                numbersObservation.publisher(in: dbPool).catch { _ in Just([]) },
                callsObservation.publisher(in: dbPool).catch { _ in Just([]) }
            )
            .map { (phoneTerritories, numbers, calls) -> [MySearchResult] in
                var results: [MySearchResult] = []
                
                // Search in phone territories
                phoneTerritories.forEach { phoneTerritory in
                    if String(phoneTerritory.number).localizedCaseInsensitiveContains(query) || phoneTerritory.description.localizedCaseInsensitiveContains(query) {
                        results.append(MySearchResult(type: .PhoneTerritory, phoneTerritory:  phoneTerritory))
                    }
                }
                
                // Search in phone numbers
                numbers.forEach { number in
                    if number.number.localizedCaseInsensitiveContains(query),
                       let phoneTerritory = phoneTerritories.first(where: { $0.id == number.territory }) {
                        results.append(MySearchResult(type: .Number, phoneTerritory:  phoneTerritory, number:  number))
                    }
                }
                
                // Search in phone calls
                calls.forEach { call in
                    if call.notes.localizedCaseInsensitiveContains(query) || call.user.localizedCaseInsensitiveContains(query),
                       let number = numbers.first(where: { $0.id == call.phonenumber }),
                       let phoneTerritory = phoneTerritories.first(where: { $0.id == number.territory }) {
                        results.append(MySearchResult(type: .Call, phoneTerritory:  phoneTerritory, number:  number, call:  call))
                    }
                }
                
                return results
            }
            .eraseToAnyPublisher()
        }
        
        return combinedPublisher
    }
    
    func containsSame<T: Hashable>(first: [T], second: [T], getId: (T) -> String) -> Bool {
        if first.count != second.count {
            return false
        }
        
        for item in first {
            if !second.contains(where: { getId($0) == getId(item) }) {
                return false
            }
        }
        
        return true
    }
    
    // Check if the house has a recall using GRDB
    func isHouseRecall(house: String) -> Bool {
        do {
            return try dbPool.read { db in
                let count = try Recalls.filter(Column("house") == house).fetchCount(db)
                return count > 0
            }
        } catch {
            return false
        }
    }
}
