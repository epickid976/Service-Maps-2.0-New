//
//  GRDBManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 10/17/24.
//

import GRDB
import Foundation
import Combine
import SwiftUI

// MARK: - Global Actor
@globalActor actor BackgroundActor: GlobalActor {
    nonisolated(unsafe) static var shared = BackgroundActor()
}

extension BackgroundActor {
    // Custom run function
    static func run<T>(_ operation: @escaping () async -> T) async -> T {
        await operation()
    }
}

// MARK: - GRDBManager
final class GRDBManager: ObservableObject, Sendable {
    // MARK: - Properties
    static let shared = GRDBManager()
    let dbPool: DatabasePool  // Use DatabasePool for concurrent reads and writes
    
    @MainActor var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    private init() {
        // Setup code with DatabasePool for concurrent access
        let databasePath = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("ServiceMaps.sqlite").path
        
        // Initialize DatabasePool
        
        dbPool = try! DatabasePool(path: databasePath)
        try! setupMigrations()
    }
    
    // MARK: - Get User Info
    @MainActor
    func getUserName() -> String? {
        return StorageManager.shared.userName
    }
    
    @MainActor
    func getUserEmail() -> String? {
        return StorageManager.shared.userEmail
    }
    
    // MARK: - Database Setup (Migrations)
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
                t.column("token", .text).notNull()
                t.column("territory", .text).notNull()
                t.primaryKey(["token", "territory"]) // Composite primary key
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
        
        // Migration to drop and recreate "user_tokens" with composite primary key
        migrator.registerMigration("recreateUserTokensWithCompositeKey") { db in
            if try db.tableExists("user_tokens") {
                try db.drop(table: "user_tokens")
            }
            try db.create(table: "user_tokens") { t in
                t.column("token", .text).notNull()
                t.column("userId", .text).notNull()
                t.column("name", .text).notNull()
                t.column("blocked", .boolean).notNull()
                
                // Define composite primary key
                t.primaryKey(["token", "userId"])
            }
        }
        
        migrator.registerMigration("createRecalls") { db in
            try db.create(table: "recalls") { t in
                t.column("id", .integer).primaryKey(autoincrement: true)
                t.column("user", .text).notNull()
                t.column("house", .text).notNull() // Removed .references("houses", onDelete: .cascade)
            }
        }
        
        migrator.registerMigration("addIndexes") { db in
            // Index for fast lookup on "territory" column in "territory_addresses"
            try db.create(index: "idx_territory_addresses_on_territory",
                          on: "territory_addresses",
                          columns: ["territory"],
                          ifNotExists: true)
            
            // Index for fast lookup on "territory_address" column in "houses"
            try db.create(index: "idx_houses_on_territory_address",
                          on: "houses",
                          columns: ["territory_address"],
                          ifNotExists: true)
            
            // Index for fast lookup on "house" column in "visits"
            try db.create(index: "idx_visits_on_house",
                          on: "visits",
                          columns: ["house"],
                          ifNotExists: true)
            
            // Compound index for "moderator" and "expire" columns in "tokens" to optimize token filtering
            try db.create(index: "idx_tokens_on_moderator_and_expire",
                          on: "tokens",
                          columns: ["moderator", "expire"],
                          ifNotExists: true)
            
            // Conditional index on "tokens" for non-expired tokens
            try db.create(index: "idx_tokens_on_user_and_expire",
                          on: "tokens",
                          columns: ["user", "expire"],
                          unique: false,
                          ifNotExists: true,
                          condition: Column("expire") > Int64(Date().timeIntervalSince1970 * 1000))
            
            // Index for the composite key in "token_territories"
            try db.create(index: "idx_token_territories_on_token_and_territory",
                          on: "token_territories",
                          columns: ["token", "territory"],
                          ifNotExists: true)
            
            // Index for fast lookup on "territory" column in "token_territories"
            try db.create(index: "idx_token_territories_on_territory",
                          on: "token_territories",
                          columns: ["territory"],
                          ifNotExists: true)
            
            // Index for fast lookup on "house" column in "recalls"
            try db.create(index: "idx_recalls_on_house",
                          on: "recalls",
                          columns: ["house"],
                          ifNotExists: true)
            
            // Index for fast lookup on "territory" column in "phone_numbers"
            try db.create(index: "idx_phone_numbers_on_territory",
                          on: "phone_numbers",
                          columns: ["territory"],
                          ifNotExists: true)
            
            // Index for fast lookup on "phonenumber" column in "phone_calls"
            try db.create(index: "idx_phone_calls_on_phonenumber",
                          on: "phone_calls",
                          columns: ["phonenumber"],
                          ifNotExists: true)
        }
        
        
        // Apply all migrations
        try migrator.migrate(dbPool)
    }
    
    // MARK: - Synchronous CRUD Methods
    
    // General Add using Result type
    @Sendable func add<T: MutablePersistableRecord>(_ object: T) -> Result<Void, Error> {
        do {
            try dbPool.write { db in  // Use dbPool.write for writes
                var object = object
                try object.insert(db, onConflict: .replace)
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    // General Edit using Result type
    @Sendable func edit<T: MutablePersistableRecord>(_ object: T) -> Result<Void, Error> {
        do {
            try dbPool.write { db in
                try object.update(db, onConflict: .replace)
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    // General Delete using Result type
    @discardableResult
    @Sendable func delete<T: MutablePersistableRecord>(_ object: T) -> Result<Void, Error> {
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
    @Sendable func fetchAll<T: FetchableRecord & TableRecord>(_ type: T.Type) -> Result<[T], Error> {
        do {
            let objects = try dbPool.read { db in  // Use dbPool.read for concurrent reads
                try T.fetchAll(db)
            }
            return .success(objects)
        } catch {
            return .failure(error)
        }
    }
    
    @Sendable func fetchById<T: FetchableRecord & MutablePersistableRecord, Key: DatabaseValueConvertible>(_ type: T.Type, id: Key) -> Result<T?, Error> {
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
    @Sendable func addAsync<T: MutablePersistableRecord & Sendable>(_ object: T) async -> Result<String, Error> {
        do {
            try await dbPool.write { db in
                var mutableObject = object  // Make a mutable copy inside the write block
                
                try mutableObject.insert(db, onConflict: .replace)  // Now insert the mutable object
            }
            return .success("Added successfully")
        } catch {
            return .failure(error)
        }
    }
    
    @BackgroundActor
    @Sendable func editAsync<T: MutablePersistableRecord & Sendable>(_ object: T ) async -> Result<String, Error> {
        do {
            try await dbPool.write { db in
                try object.update(db, onConflict: .replace)
            }
            return .success("Edited successfully")
        } catch {
            print("Database Error \(error)")
            return .failure(error)
        }
    }
    
    @BackgroundActor
    @Sendable func deleteAsync<T: MutablePersistableRecord & Sendable>(_ object: T) async -> Result<String, Error> {
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
    @Sendable func addBulkAsync<T: MutablePersistableRecord & Sendable>(_ objects: [T]) async -> Result<String, Error> {
        do {
            try await dbPool.write { db in
                try objects.forEach { object in
                    var mutableObject = object
                    try mutableObject.insert(db, onConflict: .replace)
                }
            }
            return .success("Bulk added successfully")
        } catch {
            return .failure(error)
        }
    }
    
    @BackgroundActor
    @Sendable func deleteBulkAsync<T: MutablePersistableRecord & TableRecord & Sendable & Identifiable>(_ objects: [T]) async -> Result<String, Error> where T.ID: DatabaseValueConvertible {
        do {
            guard !objects.isEmpty else {
                return .success("No objects to delete")
            }
            
            try await dbPool.write { db in
                // Extract primary keys from objects
                let ids = objects.compactMap { $0.id }
                
                // Ensure the primary keys are valid before proceeding
                guard !ids.isEmpty else {
                    throw DatabaseError(message: "Objects must have valid primary keys for batch deletion.")
                }
                
                // Perform batch deletion
                try T.deleteAll(db, ids: ids)
            }
            return .success("Bulk deleted successfully")
        } catch {
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func deleteBulkCompositeKeysAsync<T: MutablePersistableRecord & TableRecord & Sendable>(
        _ objects: [T],
        compositeKey: @escaping @Sendable (T) -> [String: any DatabaseValueConvertible]?
    ) async -> Result<String, Error> {
        do {
            guard !objects.isEmpty else {
                return .success("No objects to delete")
            }
            
            try await dbPool.write { db in
                // Extract composite keys from objects
                let keys = objects.compactMap(compositeKey)
                
                // Ensure composite keys are valid before proceeding
                guard !keys.isEmpty else {
                    throw DatabaseError(message: "Objects must have valid composite keys for batch deletion.")
                }
                
                // Perform batch deletion
                try T.deleteAll(db, keys: keys)
            }
            return .success("Bulk deleted successfully")
        } catch {
            return .failure(error)
        }
    }
    
    @BackgroundActor
    @Sendable func editBulkAsync<T: MutablePersistableRecord & Sendable>(_ objects: [T]) async -> Result<String, Error> {
        do {
            try await dbPool.write { db in
                try objects.forEach { object in
                    try object.update(db, onConflict: .replace)
                }
            }
            return .success("Bulk edited successfully")
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Clear All Data
    func clearAllData() throws {
        try dbPool.write { db in
            // Delete all data from all tables
            try db.execute(sql: "DELETE FROM visits")
            try db.execute(sql: "DELETE FROM houses")
            try db.execute(sql: "DELETE FROM territory_addresses")
            try db.execute(sql: "DELETE FROM territories")
            try db.execute(sql: "DELETE FROM tokens")
            try db.execute(sql: "DELETE FROM token_territories")
            try db.execute(sql: "DELETE FROM user_tokens")
            try db.execute(sql: "DELETE FROM recalls")
            try db.execute(sql: "DELETE FROM phone_territories")
            try db.execute(sql: "DELETE FROM phone_numbers")
            try db.execute(sql: "DELETE FROM phone_calls")
        }
    }
    
    
    @BackgroundActor
    @Sendable func fetchAllAsync<T: FetchableRecord & TableRecord & Sendable>(_ type: T.Type) async -> Result<[T], Error> {
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
    @Sendable func fetchByIdAsync<T: FetchableRecord & MutablePersistableRecord & Sendable, Key: DatabaseValueConvertible & Sendable>(_ type: T.Type, id: Key) async -> Result<T?, Error> {
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
    @BackgroundActor
    @Sendable func fetchFirstTerritory() async -> Territory? {
        do {
            return try await dbPool.read { db in
                try Territory.fetchOne(db) // Fetch the first Territory object
            }
        } catch {
            return nil
        }
    }
    // MARK: - Individual Data Fetching
    @MainActor
    func getTerritoryData() -> AnyPublisher<[TerritoryDataWithKeys], Never> {
        let combinedObservation = ValueObservation.tracking { db -> (
            territories: [Territory],
            addresses: [TerritoryAddress],
            houses: [House],
            tokens: [Token],
            tokenTerritories: [TokenTerritory]
        ) in
            let territories = try Territory.fetchAll(db)
            
            // Only fetch addresses linked to existing territories
            let territoryIDs = Set(territories.map(\.id))
            let addresses = try TerritoryAddress
                .filter(territoryIDs.contains(Column("territory")))
                .fetchAll(db)
            
            // Only fetch houses linked to those addresses
            let addressIDs = Set(addresses.map(\.id))
            let houses = try House
                .filter(addressIDs.contains(Column("territory_address")))
                .fetchAll(db)
            
            let tokens = try Token.fetchAll(db)
            let tokenTerritories = try TokenTerritory
                .filter(territoryIDs.contains(Column("territory")))
                .fetchAll(db)
            
            return (territories, addresses, houses, tokens, tokenTerritories)
        }
        
        return combinedObservation
            .publisher(in: dbPool)
            .catch { _ in Just(([], [], [], [], [])) }
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .map { [weak self] (territories, addresses, houses, tokens, tokenTerritories) -> [TerritoryDataWithKeys] in
                guard let self else { return [] }
                
                let territoryAddressesMap = Dictionary(grouping: addresses, by: \.territory)
                let territoryHousesMap = Dictionary(grouping: houses, by: \.territory_address)
                let tokenTerritoriesMap = Dictionary(grouping: tokenTerritories, by: \.territory)
                let tokenMap = Dictionary(uniqueKeysWithValues: tokens.map { ($0.id, $0) })
                
                let groupedData = territories.reduce(into: [TerritoryDataWithKeys]()) { result, territory in
                    let currentAddresses = territoryAddressesMap[territory.id] ?? []
                    let currentHouses = currentAddresses.flatMap { territoryHousesMap[$0.id] ?? [] }
                    let associatedTokenTerritories = tokenTerritoriesMap[territory.id] ?? []
                    let keys = associatedTokenTerritories.compactMap { tokenMap[$0.token] }
                    
                    let territoryData = TerritoryData(
                        territory: territory,
                        addresses: currentAddresses,
                        housesQuantity: currentHouses.count,
                        accessLevel: AuthorizationLevelManager().getAccessLevel(model: territory) ?? .User
                    )
                    
                    if let index = result.firstIndex(where: { self.containsSame(first: $0.keys, second: keys, getId: { $0.id }) }) {
                        result[index].territoriesData.append(territoryData)
                    } else {
                        result.append(TerritoryDataWithKeys(keys: keys, territoriesData: [territoryData]))
                    }
                }
                
                return groupedData.map { group in
                    var group = group
                    group.territoriesData.sort { $0.territory.number < $1.territory.number }
                    return group
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    @MainActor
    func getAddressData(territoryId: String) -> AnyPublisher<[AddressData], Never> {
        let observation = ValueObservation.tracking { db -> (addresses: [TerritoryAddress], houses: [House]) in
            let addresses = try TerritoryAddress
                .filter(Column("territory") == territoryId)
                .fetchAll(db)
            
            let addressIDs = addresses.map(\.id)
            
            let houses = try House
                .filter(addressIDs.contains(Column("territory_address")))
                .fetchAll(db)
            
            return (addresses, houses)
        }
        
        return observation
            .publisher(in: dbPool)
            .catch { _ in Just(([], [])) }
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .map { addresses, houses in
                let houseMap = Dictionary(grouping: houses, by: \.territory_address)
                
                return addresses.map { address in
                    AddressData(
                        id: UUID(),
                        address: address,
                        houseQuantity: houseMap[address.id]?.count ?? 0,
                        accessLevel: AuthorizationLevelManager().getAccessLevel(model: address) ?? .User
                    )
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    @MainActor
    func getHouseData(addressId: String) -> AnyPublisher<[HouseData], Never> {
        let observation = ValueObservation.tracking { db -> (houses: [House], visits: [Visit]) in
            // Fetch all houses for the specific address
            let houses = try House
                .filter(Column("territory_address") == addressId)
                .fetchAll(db)
            
            let houseIds = houses.map(\.id)
            
            // Fetch only visits for those houses
            let visits = try Visit
                .filter(houseIds.contains(Column("house")))
                .fetchAll(db)
            
            return (houses, visits)
        }
        
        return observation
            .publisher(in: dbPool)
            .catch { _ in Just(([], [])) }
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .map { houses, visits in
                let visitsByHouse = Dictionary(grouping: visits, by: \.house)
                
                return houses.map { house in
                    let mostRecentVisit = visitsByHouse[house.id]?.max(by: { $0.date < $1.date })
                    
                    return HouseData(
                        id: UUID(),
                        house: house,
                        visit: mostRecentVisit,
                        accessLevel: AuthorizationLevelManager().getAccessLevel(model: house) ?? .User
                    )
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    @MainActor
    func getVisitData(houseId: String) -> AnyPublisher<[VisitData], Never> {
        let userEmail = getUserEmail()
        let userName = getUserName()
        let isAdmin = AuthorizationLevelManager().existsAdminCredentials()
        
        let observation = ValueObservation.tracking { db in
            try Visit
                .filter(Column("house") == houseId)
                .order(Column("date").desc)
                .fetchAll(db)
        }
        
        return observation
            .publisher(in: dbPool)
            .catch { _ in Just([]) }
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .map { visits in
                visits.map { visit in
                    let isCurrentUser = visit.user == userEmail
                    let resolvedUser = isCurrentUser ? (userName ?? "") : visit.user
                    let accessLevel: AccessLevel = (
                        isAdmin
                        ? .Admin
                        : (
                            isCurrentUser ? .Moderator : AuthorizationLevelManager()
                                .getAccessLevel(model: visit)
                        )
                    ) ?? .User
                    
                    return VisitData(
                        id: UUID(),
                        visit: Visit(
                            id: visit.id,
                            house: visit.house,
                            date: visit.date,
                            symbol: visit.symbol,
                            notes: visit.notes,
                            user: resolvedUser
                        ),
                        accessLevel: accessLevel
                    )
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    @MainActor
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
            .flatMap { (tokens: [Token], allTerritories: [Territory], tokenTerritories: [TokenTerritory]) -> AnyPublisher<[KeyData], Never> in
                
                var data: [KeyData] = []
                
                // Iterate through tokens and create KeyData
                for token in tokens {
                    // Create an array to collect unique territories (use a dictionary to avoid duplicates)
                    var uniqueTerritories: [Territory] = []
                    var seenTerritoryIDs: Set<String> = [] // Store IDs to check for duplicates
                    
                    // Find associated territories for the token
                    let associatedTokenTerritories = tokenTerritories.filter { $0.token == token.id }
                    
                    for tokenTerritory in associatedTokenTerritories {
                        // Find the territory and ensure it's not a duplicate
                        if let territory = allTerritories.first(where: { $0.id == tokenTerritory.territory }), !seenTerritoryIDs.contains(territory.id) {
                            uniqueTerritories.append(territory)
                            seenTerritoryIDs.insert(territory.id)
                        }
                    }
                    
                    // Append sorted KeyData
                    let sortedTerritories = uniqueTerritories.sorted(by: { $0.number < $1.number })
                    let keyData = KeyData(id: UUID(), key: token, territories: sortedTerritories)
                    data.append(keyData)
                }
                
                // Return the data sorted by token name
                let sortedData = data.sorted { $0.key.name < $1.key.name }
                return Just(sortedData).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        
        return flow
    }
    
    @MainActor
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
    
    @MainActor
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
                
                let sortedData = data.sorted { $0.phoneNumber.house ?? "0" < $1.phoneNumber.house ?? "0" }.map { item -> PhoneNumbersData in
                    var modifiedItem = item
                    if let house = modifiedItem.phoneNumber.house {
                        modifiedItem.phoneNumber.house = house.replacingOccurrences(of: ".0", with: "")
                    }
                    return modifiedItem
                }
                
                return Just(sortedData)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        
        return flow
    }
    
    @MainActor
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
                let email = self.getUserEmail()
                let name = self.getUserName()
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
        let twoWeeksAgoDate = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        let timestamp = Int64(twoWeeksAgoDate.timeIntervalSince1970)

        let recentVisitsObs = ValueObservation.tracking { db in
            try Visit
                .filter(Column("date") >= timestamp)
                .order(Column("date").desc)
                .fetchAll(db)
        }

        return recentVisitsObs
            .publisher(in: dbPool)
            .catch { _ in Just([]) }
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .flatMap { [weak self] visits -> AnyPublisher<[RecentTerritoryData], Never> in
                guard let self else { return Just([]).eraseToAnyPublisher() }

                let houseIds = Set(visits.map { $0.house })
                let houseObs = ValueObservation.tracking { db in
                    try House.filter(houseIds.contains(Column("id"))).fetchAll(db)
                }

                let housePublisher: AnyPublisher<[House], Never> = houseObs
                    .publisher(in: self.dbPool)
                    .catch { _ in Just([]) }
                    .eraseToAnyPublisher()

                return housePublisher.flatMap { houses -> AnyPublisher<[RecentTerritoryData], Never> in
                    let addressIds = Set(houses.map { $0.territory_address })
                    let addressObs = ValueObservation.tracking { db in
                        try TerritoryAddress.filter(addressIds.contains(Column("id"))).fetchAll(db)
                    }

                    let addressPublisher: AnyPublisher<[TerritoryAddress], Never> = addressObs
                        .publisher(in: self.dbPool)
                        .catch { _ in Just([]) }
                        .eraseToAnyPublisher()

                    return addressPublisher.flatMap { addresses -> AnyPublisher<[RecentTerritoryData], Never> in
                        let territoryIds = Set(addresses.map { $0.territory })
                        let territoryObs = ValueObservation.tracking { db in
                            try Territory.filter(territoryIds.contains(Column("id"))).fetchAll(db)
                        }

                        let territoryPublisher: AnyPublisher<[Territory], Never> = territoryObs
                            .publisher(in: self.dbPool)
                            .catch { _ in Just([]) }
                            .eraseToAnyPublisher()

                        return territoryPublisher.map { territories -> [RecentTerritoryData] in
                            let houseMap = Dictionary(uniqueKeysWithValues: houses.map { ($0.id, $0) })
                            let addressMap = Dictionary(uniqueKeysWithValues: addresses.map { ($0.id, $0) })
                            let territoryMap = Dictionary(uniqueKeysWithValues: territories.map { ($0.id, $0) })

                            let results: [RecentTerritoryData] = visits.compactMap { visit in
                                guard
                                    let house = houseMap[visit.house],
                                    let address = addressMap[house.territory_address],
                                    let territory = territoryMap[address.territory]
                                else {
                                    return nil
                                }

                                return RecentTerritoryData(
                                    id: UUID(),
                                    territory: territory,
                                    lastVisit: visit
                                )
                            }

                            return results
                                .sorted(by: { $0.lastVisit.date > $1.lastVisit.date })
                                .unique { $0.territory.id }
                        }
                        .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func getRecentPhoneTerritoryData() -> AnyPublisher<[RecentPhoneData], Never> {
        
        // Correct timestamp calculation
        let twoWeeksAgoDate = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        let twoWeeksAgoTimestamp = Int64(twoWeeksAgoDate.timeIntervalSince1970)
        
        // Single combined publisher
        return Publishers.CombineLatest3(
            ValueObservation.tracking { db in try PhoneTerritory.fetchAll(db) }
                .publisher(in: dbPool).replaceError(with: []),
            
            ValueObservation.tracking { db in try PhoneNumber.fetchAll(db) }
                .publisher(in: dbPool).replaceError(with: []),
            
            ValueObservation.tracking { db in
                try PhoneCall
                    .filter(sql: "date >= ?", arguments: [twoWeeksAgoTimestamp])
                    .fetchAll(db)
            }
                .publisher(in: dbPool).replaceError(with: [])
        )
        .map { territories, numbers, recentCalls in
            
            let numberDict = Dictionary(uniqueKeysWithValues: numbers.map { ($0.id, $0) })
            
            // Map recent calls to RecentPhoneData
            let mappedData = recentCalls.compactMap { call -> RecentPhoneData? in
                guard let number = numberDict[call.phonenumber] else {
                    print("Missing phone number for call \(call.id)")
                    return nil
                }
                guard let territory = territories.first(where: { $0.id == number.territory }) else {
                    print("Missing territory for phone number \(number.id)")
                    return nil
                }
                return RecentPhoneData(
                    id: UUID(),
                    territory: territory,
                    lastCall: call
                )
            }
            
            // Sort mapped data by most recent call date
            let sortedMappedData = mappedData.sorted {
                $0.lastCall.date > $1.lastCall.date
            }
            
            // Deduplicate by territory, preserving only the most recent call per territory
            return sortedMappedData.unique { $0.territory.id }
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
    @MainActor
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
    
    // MARK: - Helper Functions
    
    @MainActor
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
    
    func findRecallId(house: String) -> Int64? {
        do {
            return try dbPool.read { db in
                let recall = try Recalls.filter(Column("house") == house).fetchOne(db)
                return recall?.id
            }
        } catch {
            return nil
        }
    }
    
    func getLastVisitForHouse(_ house: House) -> Visit? {
        do {
            return try dbPool.read { db in
                try Visit.filter(Column("house") == house.id).order(Column("date").desc).fetchOne(db)
            }
        } catch {
            return nil
        }
    }
    
    func getLastCallForNumber(_ number: PhoneNumber) -> PhoneCall? {
        do {
            return try dbPool.read { db in
                try PhoneCall.filter(Column("phonenumber") == number.id).order(Column("date").desc).fetchOne(db)
            }
        } catch {
            return nil
        }
    }
    
    /// Returns FloorData for a given territory.
    /// For each TerritoryAddress (floor) in the territory, it gathers the houses,
    /// fetches the most recent visit dates (assuming Visit.date is stored as an integer timestamp),
    /// and if there are at least 5 visits, the 5th most recent date is used as the knocked date.
    @BackgroundActor
    func getFloorData(for territoryId: String) async -> FloorData? {
        do {
            return try await dbPool.read { db in
                // Fetch the territory.
                guard let territory = try Territory.fetchOne(db, key: territoryId) else { return nil }
                
                // Get all addresses (floors) for this territory.
                let addresses = try TerritoryAddress.filter(Column("territory") == territoryId).fetchAll(db)
                var floorDetails: [FloorDetail] = []
                
                for address in addresses {
                    // Fetch houses that belong to this address.
                    let houses = try House.filter(Column("territory_address") == address.id).fetchAll(db)
                    var visitDates: [Date] = []
                    
                    // For each house, get its most recent visit.
                    for house in houses {
                        if let visit = try Visit
                            .filter(Column("house") == house.id)
                            .order(Column("date").desc)
                            .fetchOne(db) {
                            // Assuming Visit.date is an integer timestamp.
                            let visitDate = Date(timeIntervalSince1970: TimeInterval(visit.date / 1000))
                            visitDates.append(visitDate)
                        }
                    }
                    
                    // Sort visit dates from most recent to oldest.
                    visitDates.sort(by: >)
                    
                    // If there are at least 5 visits, the knocked date is the 5th most recent.
                    let knockedDate: Date? = visitDates.count >= 5 ? visitDates[4] : nil
                    
                    let detail = FloorDetail(address: address, knockedDate: knockedDate)
                    floorDetails.append(detail)
                }
                
                return FloorData(territory: territory, floors: floorDetails)
            }
        } catch {
            print("Error fetching floor data: \(error)")
            return nil
        }
    }
}

// MARK: - Extensions

extension GRDBManager {
    func exists<T: FetchableRecord & MutablePersistableRecord & Sendable>(
        _ type: T.Type,
        matching keys: [String: DatabaseValueConvertible & Sendable]
    ) async -> Bool {
        do {
            return try await dbPool.read { db in
                var query = type.all()
                for (column, value) in keys {
                    query = query.filter(Column(column) == value)
                }
                return try query.fetchCount(db) > 0
            }
        } catch {
            print("Error checking existence with composite keys: \(error)")
            return false
        }
    }
}

extension GRDBManager {
    func deleteBulkCompositeKeysWrapper<T: MutablePersistableRecord & TableRecord & Sendable>(
        _ objects: [T],
        compositeKey: @Sendable @escaping (T) -> [String: any DatabaseValueConvertible]?
    ) async -> Result<String, Error> {
        return await self.deleteBulkCompositeKeysAsync(objects, compositeKey: compositeKey)
    }
}
