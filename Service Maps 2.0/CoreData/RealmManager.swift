//
//  RealmManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/15/24.
//

import Foundation
import RealmSwift
import Combine


class RealmManager: ObservableObject {
    static let shared = RealmManager()
    
    var realmDatabase: Realm
    //var dataUploaderManager = DataUploaderManager()
    
    init() {
        realmDatabase = try! Realm()
        
        let territoryEntities = realmDatabase.objects(TerritoryObject.self)
        territoriesFlow = territoryEntities
        let addressesEntities = realmDatabase.objects(TerritoryAddressObject.self)
        addressesFlow = addressesEntities
        let housesEntities = realmDatabase.objects(HouseObject.self)
        housesFlow = housesEntities
        let visitsEntities = realmDatabase.objects(VisitObject.self)
        visitsFlow = visitsEntities
        let tokensEntities = realmDatabase.objects(TokenObject.self)
        tokensFlow = tokensEntities
        let tokenTerritoryEntities = realmDatabase.objects(TokenTerritoryObject.self)
        tokenTerritoriesFlow = tokenTerritoryEntities
    }
    
    @Published var territoriesFlow: Results<TerritoryObject>
    @Published var addressesFlow: Results<TerritoryAddressObject>
    @Published var housesFlow: Results<HouseObject>
    @Published var visitsFlow: Results<VisitObject>
    @Published var tokensFlow: Results<TokenObject>
    @Published var tokenTerritoriesFlow: Results<TokenTerritoryObject>
    
    @Published var dataStore = StorageManager.shared
    
    func addModel<T: Object>(_ object: T) -> Result<Bool, Error> {
        do {
            let realmDatabase = try Realm()
            try realmDatabase.write {
                realmDatabase.add(object)
            }
            return Result.success(true)
        } catch {
            return Result.failure(error)
        }
    }
    
    func updateTerritory(territory: TerritoryModel) -> Result<Bool, Error> {
        do {
            let realmDatabase = try Realm()
            try realmDatabase.write {
                if let territoryToUpdate = realmDatabase.objects(TerritoryObject.self).filter("id == %d", territory.id).first {
                    territoryToUpdate.congregation = territory.congregation
                    territoryToUpdate.number = territory.number
                    territoryToUpdate.territoryDescription = territory.description
                    territoryToUpdate.image = territory.image
                } else {
                    // Handle case where no territory was found (e.g., throw specific error)
                    print("no territory found")
                    throw CustomErrors.NotFound
                }
            }
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    
    func updateAddress(address: TerritoryAddressModel) -> Result<Bool, Error> {
        do {
            let realmDatabase = try Realm()
            try realmDatabase.write {
                if let entity = realmDatabase.objects(TerritoryAddressObject.self).filter("id == %d", address.id).first {
                    entity.territory = address.territory
                    entity.address = address.address
                    entity.floors = address.floors
                } else {
                    // Handle case where no address was found (e.g., throw specific error)
                    print("no address found")
                    throw CustomErrors.NotFound
                }
            }
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    func updateHouse(house: HouseModel) -> Result<Bool, Error> {
        do {
            let realmDatabase = try Realm()
            try realmDatabase.write {
                if let entity = realmDatabase.objects(HouseObject.self).filter("id == %d", house.id).first {
                    entity.territory_address = house.territory_address
                    entity.number = house.number
                    if let floorString = house.floor{
                        entity.floor = floorString
                    }
                } else {
                    // Handle case where no house was found (e.g., throw specific error)
                    print("no house found")
                    throw CustomErrors.NotFound
                }
            }
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    func updateVisit(visit: VisitModel) -> Result<Bool, Error> {
        do {
            let realmDatabase = try Realm()
            if let entity = realmDatabase.objects(VisitObject.self).filter("id == %d", visit.id).first {
                try realmDatabase.write {
                    entity.house = visit.house
                    entity.date = visit.date // Assuming date is a unix timestamp
                    entity.symbol = visit.symbol
                    entity.notes = visit.notes
                    entity.user = visit.user
                }
            } else {
                return .failure(CustomErrors.NotFound)
            }
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    func updateToken(token: MyTokenModel) -> Result<Bool, Error> {
        do {
            let realmDatabase = try Realm()
            if let entity = realmDatabase.objects(TokenObject.self).filter("id == %d", token.id).first {
                try realmDatabase.write {
                    entity.name = token.name
                    entity.owner = token.owner
                    entity.congregation = token.congregation
                    entity.moderator = token.moderator
                    entity.expire = token.expire ?? 0
                    entity.user = token.user
                }
            } else {
                return .failure(CustomErrors.NotFound)
            }
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    func updateTokenTerritory(tokenTerritory: TokenTerritoryModel) -> Result<Bool, Error> {
        do {
            let realmDatabase = try Realm()
            if let entity = realmDatabase.objects(TokenTerritoryObject.self)
                .filter("token == %@ && territory == %@", tokenTerritory.token, tokenTerritory.territory)
                .first {
                try realmDatabase.write {
                    entity.token = tokenTerritory.token
                    entity.territory = tokenTerritory.territory
                }
            } else {
                return .failure(CustomErrors.NotFound)
            }
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    
    func deleteTerritory(territory: TerritoryObject) -> Result<Bool, Error> {
        do {
            let realmDatabase = try Realm()
            try realmDatabase.write {
                if let territoryToDelete = realmDatabase.objects(TerritoryObject.self).filter("id == %d", territory.id).first {
                    print(territoryToDelete)
                    realmDatabase.delete(territoryToDelete)
                } else {
                    // Handle case where no territory was found (e.g., throw specific error)
                    print("no territory found")
                    throw CustomErrors.NotFound
                }
            }
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    
    func deleteAddress(address: TerritoryAddressObject) -> Result<Bool, Error> {
        do {
            let realmDatabase = try Realm()
            try realmDatabase.write {
                if let entity = realmDatabase.objects(TerritoryAddressObject.self).filter("id == %d", address.id).first {
                    realmDatabase.delete(entity)
                } else {
                    // Handle case where no address was found (e.g., throw specific error)
                    print("no address found")
                    throw CustomErrors.NotFound
                }
            }
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    func deleteHouse(house: HouseObject) -> Result<Bool, Error> {
        do {
            let realmDatabase = try Realm()
            try realmDatabase.write {
                if let entity = realmDatabase.objects(HouseObject.self).filter("id == %d", house.id).first {
                    realmDatabase.delete(entity)
                } else {
                    // Handle case where no house was found (e.g., throw specific error)
                    print("no house found")
                    throw CustomErrors.NotFound
                }
            }
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    func deleteVisit(visit: VisitObject) -> Result<Bool, Error> {
        do {
            let realmDatabase = try Realm()
            if let entity = realmDatabase.objects(VisitObject.self).filter("id == %d", visit.id).first {
                try realmDatabase.write {
                    realmDatabase.delete(entity)
                }
            } else {
                return .failure(CustomErrors.NotFound)
            }
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    func deleteToken(token: TokenObject) -> Result<Bool, Error> {
        do {
            let realmDatabase = try Realm()
            if let entity = realmDatabase.objects(TokenObject.self).filter("id == %d", token  .id).first {
                try realmDatabase.write {
                    realmDatabase.delete(entity)
                }
            } else {
                return .failure(CustomErrors.NotFound)
            }
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    func deleteTokenTerritory(tokenTerritory: TokenTerritoryObject) -> Result<Bool, Error> {
        do {
            let realmDatabase = try Realm()
            if let entity = realmDatabase.objects(TokenTerritoryObject.self)
                .filter("token == %@ && territory == %@", tokenTerritory.token, tokenTerritory.territory)
                .first {
                try realmDatabase.write {
                    realmDatabase.delete(entity)
                }
            } else {
                return .failure(CustomErrors.NotFound)
            }
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    
    func refreshTerritories() {
        do {
            let realmDatabase = try Realm()
            let territoryEntities = realmDatabase.objects(TerritoryObject.self)
            territoriesFlow = territoryEntities
        } catch {
            print(error)
        }
    }
    
    func refreshAddresses() {
        do {
            let realmDatabase = try Realm()
            let addressesEntities = realmDatabase.objects(TerritoryAddressObject.self)
            addressesFlow = addressesEntities
        } catch {
            print(error)
        }
    }
    
    func refreshHouses() {
        do {
            let realmDatabase = try Realm()
            let housesEntities = realmDatabase.objects(HouseObject.self)
            housesFlow = housesEntities
        } catch {
            print(error)
        }
    }
    
    func refreshVisits() {
        do {
            let realmDatabase = try Realm()
            let visitsEntities = realmDatabase.objects(VisitObject.self)
            visitsFlow = visitsEntities
        } catch {
            print(error)
        }
    }
    
    func refreshTokens() {
        do {
            let realmDatabase = try Realm()
            let tokensEntities = realmDatabase.objects(TokenObject.self)
            tokensFlow = tokensEntities
        } catch {
            print(error)
        }
    }
    
    func refreshTokenTerritories() {
        do {
            let realmDatabase = try Realm()
            let tokenTerritoryEntities = realmDatabase.objects(TokenTerritoryObject.self)
            tokenTerritoriesFlow = tokenTerritoryEntities
        } catch {
            print(error)
        }
    }
    
    func getTerritories() async throws -> Results<TerritoryObject> {
        let realmDatabase = try await Realm()
        let territoryEntities = realmDatabase.objects(TerritoryObject.self)
        return territoryEntities
    }
    
    func getAddresses() async throws -> Results<TerritoryAddressObject> {
        let realmDatabase = try await Realm()
        let addressesEntities = realmDatabase.objects(TerritoryAddressObject.self)
        return addressesEntities
    }
    
    func getHouses() async throws -> Results<HouseObject> {
        let realmDatabase = try await Realm()
        let housesEntities = realmDatabase.objects(HouseObject.self)
        return housesEntities
    }
    
    func getVisits() async throws -> Results<VisitObject> {
        let realmDatabase = try await Realm()
        let visitsEntities = realmDatabase.objects(VisitObject.self)
        return visitsEntities
    }
    
    func getTokens() async throws -> Results<TokenObject> {
        let realmDatabase = try await Realm()
        let tokensEntities = realmDatabase.objects(TokenObject.self)
        return tokensEntities
    }
    
    func getTokenTerritories() async throws -> Results<TokenTerritoryObject> {
        let realmDatabase = try await Realm()
        let tokenTerritoryEntities = realmDatabase.objects(TokenTerritoryObject.self)
        return tokenTerritoryEntities
    }
    
    
    func refreshAll() {
        refreshTerritories()
        refreshAddresses()
        refreshHouses()
        refreshVisits()
        refreshTokens()
        refreshTokenTerritories()
    }
    
    @MainActor
    func getTerritoryData() -> AnyPublisher<[TerritoryDataWithKeys], Never> {
        
        let flow = Publishers.CombineLatest3(
            $territoriesFlow.share(),
            $addressesFlow.share(),
            $housesFlow.share()
        )
            .flatMap { territoryData -> AnyPublisher<[TerritoryDataWithKeys], Never> in
                var data = [TerritoryData]()
                
                for territory in territoryData.0 {
                    let currentAddresses = territoryData.1.filter { $0.territory == territory.id }
                    
                    let currentHouses = territoryData.1
                        .filter { $0.territory == territory.id }
                        .flatMap { address -> LazyFilterSequence<Results<HouseObject>> in
                            return territoryData.2.filter { $0.territory_address == address.id }
                        }
                    
                    let territoryDataEntry = TerritoryData(
                        territory: convertTerritoryToTerritoryModel(model: territory) ,
                        addresses: ModelToStruct().convertTerritoryAddressEntitiesToStructs(entities: Array(currentAddresses)) ,
                        housesQuantity: currentHouses.count,
                        accessLevel: AuthorizationLevelManager().getAccessLevel(model: territory) ?? .User // Implement your accessLevel logic
                    )
                    data.append(territoryDataEntry)
                }
                
                // Combine moderator and non-moderator data into a single array (corrected)
                let combinedData = data.sorted(by: { $0.territory.number < $1.territory.number })
                
                var dataWithKeys = [TerritoryDataWithKeys]()
                
                
                for territoryData in combinedData {
                    var keys = [TokenObject]()
                    let keysDao = self.realmDatabase.objects(TokenObject.self)
                    
                    let tokenTerritoriesOfKey = self.realmDatabase.objects(TokenTerritoryObject.self).filter({ $0.territory == territoryData.territory.id})
                    
                    for tokenTerritory in tokenTerritoriesOfKey {
                        if let token = keysDao.first(where: { $0.id == tokenTerritory.token}) {
                            keys.append(token)
                        }
                    }
                    
                    let founded = dataWithKeys.first { item in
                        if keys.isEmpty {
                            return item.keys.isEmpty
                        } else {
                            return self.containsSame(first: item.keys, second: ModelToStruct().convertTokenEntitiesToStructs(entities: keys) , getId: { $0.id })
                        }
                    }
                    
                    if founded != nil {
                        var territoriesToReplace = founded!.territoriesData
                        
                        territoriesToReplace.append(territoryData)
                        
                        if let index = dataWithKeys.firstIndex(where: { $0.id == founded!.id}) {
                            dataWithKeys.remove(at: index)
                        }
                        
                        dataWithKeys.append(
                            TerritoryDataWithKeys(
                                id: UUID(),
                                keys: ModelToStruct().convertTokenEntitiesToStructs(entities: keys),
                                territoriesData: territoriesToReplace.sorted { $0.territory.number < $1.territory.number }
                            )
                        )
                    } else {
                        dataWithKeys.append(
                            TerritoryDataWithKeys(
                                id: UUID(),
                                keys: ModelToStruct().convertTokenEntitiesToStructs(entities: keys),
                                territoriesData: [territoryData]
                            )
                        )
                    }
                }
                
                
                return Just(dataWithKeys.sorted { $0.territoriesData.first?.territory.number ?? Int32(Int.max) < $1.territoriesData.first?.territory.number ?? Int32(Int.max) }).eraseToAnyPublisher()
                //.sorted { $0.territoriesData.first?.territory?.number ?? Int.max < $1.territoriesData.first?.territory?.number ?? Int.max }
                
            }
            .eraseToAnyPublisher()
        
        return flow
    }
    
    @MainActor
    func getAddressData(territoryId: String) -> AnyPublisher<[AddressData], Never> {
        
        let flow = Publishers.CombineLatest(
            $addressesFlow.share(),
            $housesFlow.share()
        )
            .flatMap { addressData -> AnyPublisher<[AddressData], Never> in
                var data = [AddressData]()
                
                let addressesFiltered = addressData.0.filter { $0.territory == territoryId }
                
                for address in addressesFiltered {
                    let housesQuantity = addressData.1.filter { $0.territory_address == address.id }.count
                    
                    data.append(AddressData(
                        id: address.id,
                        address: convertTerritoryToTerritoryAddressModel(model: address),
                        houseQuantity: housesQuantity,
                        accessLevel: AuthorizationLevelManager().getAccessLevel(model: address) ?? .User)
                    )
                }
                
                return Just(data).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        
        return flow
    }
    
    @MainActor
    func getHouseData(addressId: String) -> AnyPublisher<[HouseData], Never>  {
        let flow = Publishers.CombineLatest(
            $housesFlow,
            $visitsFlow
        )
            .flatMap { houseData -> AnyPublisher<[HouseData], Never> in
                var data = [HouseData]()
                
                let housesFiltered = houseData.0.filter { $0.territory_address == addressId }
                
                for house in housesFiltered {
                    if let mostRecentVisit = houseData.1
                        .filter({ $0.house == house.id })
                        .max(by: { $0.date < $1.date }) {
                        data.append(
                            HouseData(
                                id: UUID(),
                                house: convertHouseToHouseModel(model: house),
                                visit: convertVisitToVisitModel(model: mostRecentVisit),
                                accessLevel: AuthorizationLevelManager().getAccessLevel(model: house) ?? .User
                            )
                        )
                    } else {
                        // Handle the case where mostRecentVisit is nil
                        data.append(
                            HouseData(
                                id: UUID(),
                                house: convertHouseToHouseModel(model: house),
                                visit: nil,
                                accessLevel: AuthorizationLevelManager().getAccessLevel(model: house) ?? .User
                            )
                        )
                    }
                }
                return Just(data).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        return flow
    }
    
    @MainActor
    func getVisitData(houseId: String) -> AnyPublisher<[VisitData], Never> {
        return Just(visitsFlow)
            .flatMap { visits -> AnyPublisher<[VisitData], Never> in
                let email = self.dataStore.userEmail
                let name = self.dataStore.userName
                
                var data = [VisitData]()
                
                visits.filter { $0.house == houseId}.forEach { visit in
                    let visitModel = VisitModel(id: visit.id, house: visit.house, date: visit.date, symbol: visit.symbol, notes: visit.notes, user: name ?? "", created_at: "", updated_at: "")
                    data.append(
                        VisitData(
                            id: UUID(),
                            visit: visit.user == email ? visitModel : convertVisitToVisitModel(model: visit) ,
                            accessLevel: visit.user == email ? .Moderator : AuthorizationLevelManager().getAccessLevel(model: visit)
                        )
                    )
                }
                data.sort { $0.visit.date > $1.visit.date }
                return Just(data).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    @MainActor
    func getKeyData() -> AnyPublisher<[KeyData], Never> {
        
        let flow = Publishers.CombineLatest3(
            $tokensFlow,
            $territoriesFlow,
            $tokenTerritoriesFlow
        )
            .flatMap { keyData -> AnyPublisher<[KeyData], Never> in
                let myTokens = keyData.0
                let allTerritoriesDb = keyData.1
                let tokenTerritories = keyData.2
                var data = [KeyData]()
                
                for token in myTokens {
                    var territories = [TerritoryObject]()
                    
                    tokenTerritories.filter { $0.token == token.id }.forEach { tokenTerritory in
                        if let territory = allTerritoriesDb.first(where: { $0.id == tokenTerritory.territory }) {
                            territories.append(territory)
                        }
                    }
                    
                    data.append(
                        KeyData(
                            id: UUID(),
                            key: convertTokenToMyTokenModel(model: token),
                            territories: ModelToStruct().convertTerritoryEntitiesToStructs(entities: territories))
                    )
                }
                
                return Just(data).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        return flow
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
}
