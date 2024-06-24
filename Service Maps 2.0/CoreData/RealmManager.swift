//
//  RealmManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/15/24.
//

import Foundation
import RealmSwift
import Combine
import SwiftUI

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
        
        let phoneTerritoriesEntities = realmDatabase.objects(PhoneTerritoryObject.self)
        phoneTerritoriesFlow = phoneTerritoriesEntities
        
        let phoneNumbersEntities = realmDatabase.objects(PhoneNumberObject.self)
        phoneNumbersFlow = phoneNumbersEntities
        
        let phoneCallsEntities = realmDatabase.objects(PhoneCallObject.self)
        phoneCallsFlow = phoneCallsEntities
        
        let userTokensEntities = realmDatabase.objects(UserTokenObject.self)
        userTokensFlow = userTokensEntities
        
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        
        
        let visitsPastTwoWeeksEntities = realmDatabase.objects(VisitObject.self).filter("date >= %@", Int64(twoWeeksAgo.timeIntervalSince1970 * 1000))
        visitsPastTwoWeeks = visitsPastTwoWeeksEntities
    }
    
    @Published var territoriesFlow: Results<TerritoryObject>
    @Published var addressesFlow: Results<TerritoryAddressObject>
    @Published var housesFlow: Results<HouseObject>
    @Published var visitsFlow: Results<VisitObject>
    @Published var tokensFlow: Results<TokenObject>
    @Published var tokenTerritoriesFlow: Results<TokenTerritoryObject>
    
    @Published var phoneTerritoriesFlow: Results<PhoneTerritoryObject>
    @Published var phoneNumbersFlow: Results<PhoneNumberObject>
    @Published var phoneCallsFlow: Results<PhoneCallObject>
    
    @Published var userTokensFlow: Results<UserTokenObject>
    
    @Published var dataStore = StorageManager.shared
    
    @Published var visitsPastTwoWeeks: Results<VisitObject>
    
    
    func getAllTerritoriesDirect() -> [TerritoryObject] {
        return Array(realmDatabase.objects(TerritoryObject.self))
    }
    
    func getAllAddressesDirect() -> [TerritoryAddressObject] {
        return Array(realmDatabase.objects(TerritoryAddressObject.self))
    }
    
    func getAllHousesDirect() -> [HouseObject] {
        return Array(realmDatabase.objects(HouseObject.self))
    }
    
    func getAllVisitsDirect() -> [VisitObject] {
        return Array(realmDatabase.objects(VisitObject.self))
    }
    
    func getAllTokensDirect() -> [TokenObject] {
        return Array(realmDatabase.objects(TokenObject.self))
    }
    
    func getAllTokenTerritoriesDirect() -> [TokenTerritoryObject] {
        return Array(realmDatabase.objects(TokenTerritoryObject.self))
    }
    
    func getAllPhoneTerritoriesDirect() -> [PhoneTerritoryObject] {
        return Array(realmDatabase.objects(PhoneTerritoryObject.self))
    }
    
    func getAllPhoneNumbersDirect() -> [PhoneNumberObject] {
        return Array(realmDatabase.objects(PhoneNumberObject.self))
    }
    
    func getAllPhoneCallsDirect() -> [PhoneCallObject] {
        return Array(realmDatabase.objects(PhoneCallObject.self))
    }
    
    func getAllUserTokensDirect() -> [UserTokenObject] {
        return Array(realmDatabase.objects(UserTokenObject.self))
    }
    
    
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
            try realmDatabase.write {
                if let entity = realmDatabase.objects(VisitObject.self).filter("id == %d", visit.id).first {
                    
                        entity.house = visit.house
                        entity.date = visit.date // Assuming date is a unix timestamp
                        entity.symbol = visit.symbol
                        entity.notes = visit.notes
                        entity.user = visit.user
                    
                } else {
                    throw CustomErrors.NotFound
                }
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
    
    func updatePhoneTerritory(phoneTerritory: PhoneTerritoryModel) -> Result<Bool, Error> {
        do {
            let realmDatabase = try Realm()
            if let entity = realmDatabase.objects(PhoneTerritoryObject.self)
                .filter("id == %d", phoneTerritory.id)
                .first {
                try realmDatabase.write {
                    entity.congregation = phoneTerritory.congregation
                    entity.image = phoneTerritory.image
                    entity.territoryDescription = phoneTerritory.description
                    entity.number = phoneTerritory.number
                }
            } else {
                return .failure(CustomErrors.NotFound)
            }
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    func updatePhoneNumber(phoneNumber: PhoneNumberModel) -> Result<Bool, Error> {
        do {
            let realmDatabase = try Realm()
            if let entity = realmDatabase.objects(PhoneNumberObject.self)
                .filter("id == %d", phoneNumber.id)
                .first {
                try realmDatabase.write {
                    entity.congregation = phoneNumber.congregation
                    entity.house = phoneNumber.house
                    entity.territory = phoneNumber.territory
                    entity.number = phoneNumber.number
                }
            } else {
                return .failure(CustomErrors.NotFound)
            }
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    func updatePhoneCall(phoneCall: PhoneCallModel) -> Result<Bool, Error> {
        do {
            let realmDatabase = try Realm()
            if let entity = realmDatabase.objects(PhoneCallObject.self)
                .filter("id == %d", phoneCall.id)
                .first {
                try realmDatabase.write {
                    entity.date = phoneCall.date
                    entity.notes = phoneCall.notes
                    entity.phoneNumber = phoneCall.phonenumber
                    entity.user = phoneCall.user
                }
            } else {
                return .failure(CustomErrors.NotFound)
            }
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    func updateUserToken(userToken: UserTokenModel) -> Result<Bool, Error> {
        do {
            let realmDatabase = try Realm()
            if let entity = realmDatabase.objects(UserTokenObject.self)
                .filter("id == %d", userToken.id)
                .first {
                try realmDatabase.write {
                    entity.token = userToken.token
                    entity.userId = userToken.userId
                    entity.name = userToken.name
                    entity.blocked = userToken.blocked
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
    
    func deletePhoneTerritory(phoneTerritory: PhoneTerritoryObject) -> Result<Bool, Error> {
        do {
            let realmDatabase = try Realm()
            if let entity = realmDatabase.objects(PhoneTerritoryObject.self).filter("id == %d", phoneTerritory.id).first {
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
    
    func deletePhoneNumber(phoneNumber: PhoneNumberObject) -> Result<Bool, Error> {
        do {
            let realmDatabase = try Realm()
            if let entity = realmDatabase.objects(PhoneNumberObject.self).filter("id == %d", phoneNumber.id).first {
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
    
    func deletePhoneCall(phoneCall: PhoneCallObject) -> Result<Bool, Error> {
        do {
            let realmDatabase = try Realm()
            if let entity = realmDatabase.objects(PhoneCallObject.self).filter("id == %d", phoneCall.id).first {
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
    
    func deleteUserToken(userToken: UserTokenObject) -> Result<Bool, Error> {
        do {
            let realmDatabase = try Realm()
            if let entity = realmDatabase.objects(UserTokenObject.self).filter("id == %d", userToken.id).first {
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
    
    @MainActor
        func getTerritoryData() -> AnyPublisher<[TerritoryDataWithKeys], Never> {
            
            let flow = Publishers.CombineLatest3(
                $territoriesFlow,
                $addressesFlow,
                $housesFlow
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
                    
                    print("END OF REALM MANAGER FUNC \(dataWithKeys.sorted { $0.territoriesData.first?.territory.number ?? Int32(Int.max) < $1.territoriesData.first?.territory.number ?? Int32(Int.max) })")
                    
                    return CurrentValueSubject(dataWithKeys.sorted { $0.territoriesData.first?.territory.number ?? Int32(Int.max) < $1.territoriesData.first?.territory.number ?? Int32(Int.max) }).eraseToAnyPublisher()
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
                
                return CurrentValueSubject(data).eraseToAnyPublisher()
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
                return CurrentValueSubject(data).eraseToAnyPublisher()
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
                
                return Just(data).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    @MainActor
    func getKeyData() -> AnyPublisher<[KeyData], Never> {
        
        let flow = Publishers.CombineLatest3(
            $tokensFlow.share(),
            $territoriesFlow.share(),
            $tokenTerritoriesFlow.share()
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
                
                return CurrentValueSubject(data.sorted { $0.key.name < $1.key.name }).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        return flow
    }
    
    @MainActor
    func getPhoneData() -> AnyPublisher<[PhoneData], Never> {
        
        let flow = Publishers.CombineLatest(
            $phoneTerritoriesFlow.share(),
            $phoneNumbersFlow.share()
        )
            .flatMap { keyData -> AnyPublisher<[PhoneData], Never> in
                let phoneTerritories = keyData.0
                let phoneNumbers = keyData.1
                var data = [PhoneData]()
                
                for territory in phoneTerritories {
                    let currentPhoneNumbers = phoneNumbers.filter { $0.territory == String(territory.id) }
                    
                    data.append(
                        PhoneData(
                            id: UUID(),
                            territory: convertPhoneTerritoryModelToPhoneTerritoryModel(model: territory),
                            numbersQuantity: currentPhoneNumbers.count)
                    )
                }
                
                return CurrentValueSubject(data.sorted { $0.territory.number < $1.territory.number }).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        return flow
    }
    
    @MainActor
    func getPhoneNumbersData(phoneTerritoryId: String) -> AnyPublisher<[PhoneNumbersData], Never> {
        
        let flow = Publishers.CombineLatest(
            $phoneNumbersFlow.share(),
            $phoneCallsFlow.share()
        )
            .flatMap { keyData -> AnyPublisher<[PhoneNumbersData], Never> in
                let phoneNumbers = keyData.0
                let phoneCalls = keyData.1
                var data = [PhoneNumbersData]()
                
                phoneNumbers.filter { $0.territory == phoneTerritoryId }.forEach { number in
                    let phoneCall = phoneCalls.filter { $0.phoneNumber == number.id  }.sorted { $0.date > $1.date }.first
                    data.append(
                        PhoneNumbersData(
                            id: UUID(),
                            phoneNumber: convertPhoneNumberModelToPhoneNumberModel(model: number),
                            phoneCall: phoneCall != nil ? convertPhoneCallModelToPhoneCallModel(model: phoneCall!) : nil
                        )
                    )
                }
                
                return CurrentValueSubject(data.sorted { $0.phoneNumber.house ?? "0" < $1.phoneNumber.house ?? "0"}).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        return flow
    }
    
    @MainActor
    func getPhoneCallData(phoneNumberId: String) -> AnyPublisher<[PhoneCallData], Never> {
        return Just(phoneCallsFlow)
            .flatMap { phoneCalls -> AnyPublisher<[PhoneCallData], Never> in
                let email = self.dataStore.userEmail
                let name = self.dataStore.userName
                
                var data = [PhoneCallData]()
                
                phoneCalls.filter { $0.phoneNumber == phoneNumberId }.forEach { call in
                    let callToAdd = PhoneCallModel(id: call.id, phonenumber: call.phoneNumber, date: call.date, notes: call.notes, user: (call.user == email ? name : call.user) ?? "", created_at: "", updated_at: "")
                    data.append(
                        PhoneCallData(
                            id: UUID(),
                            phoneCall: callToAdd,
                            accessLevel: self.phoneCallAccessLevel(call: call, email: email ?? "")
                        )
                    )
                }
                
                data.sort { $0.phoneCall.date > $1.phoneCall.date }
                return CurrentValueSubject(data).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
   
    @MainActor
    func getRecentTerritoryData() -> AnyPublisher<[RecentTerritoryData], Never> {
        let territoriesPublisher = $territoriesFlow.share()

        // 1. Create Dictionaries for Efficient Lookups
        let addressDictPublisher = $addressesFlow.share().map { addresses in
            Dictionary(uniqueKeysWithValues: addresses.map { ($0.id, $0) })
        }.eraseToAnyPublisher()

        let houseDictPublisher = $housesFlow.share().map { houses in
            Dictionary(uniqueKeysWithValues: houses.map { ($0.id, $0) })
        }.eraseToAnyPublisher()

        // 2. Combine Only Relevant Publishers
        return Publishers.CombineLatest3(
            territoriesPublisher,
            addressDictPublisher,
            houseDictPublisher
        )
        .flatMap { (territories, addressDict, houseDict) -> AnyPublisher<[RecentTerritoryData], Never> in
            return self.$visitsPastTwoWeeks // Subscribe to visits publisher only when other data is ready
                .map { recentVisits in
                    recentVisits.compactMap { visit -> RecentTerritoryData? in
                        guard let house = houseDict[visit.house],
                              let address = addressDict[house.territory_address],
                              let territory = territories.first(where: { $0.id == address.territory }) else {
                            return nil
                        }
                        return RecentTerritoryData(
                            id: UUID(),
                            territory: convertTerritoryToTerritoryModel(model: territory),
                            lastVisit: convertVisitToVisitModel(model: visit)
                        )
                    }
                    .unique { $0.territory.id }
                }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }


    
    @MainActor
    func getRecentPhoneTerritoryData() -> AnyPublisher<[RecentPhoneData], Never> {
        let territoriesPublisher = $phoneTerritoriesFlow.share()

        // 1. Create Dictionary for Phone Numbers
        let numberDictPublisher = $phoneNumbersFlow.share().map { numbers in
            Dictionary(uniqueKeysWithValues: numbers.map { ($0.id, $0) })
        }.eraseToAnyPublisher()
        
        // 2. Combine Relevant Publishers
        return Publishers.CombineLatest(
            territoriesPublisher,
            numberDictPublisher
        )
        .flatMap { (territories, numberDict) -> AnyPublisher<[RecentPhoneData], Never> in
            return self.$phoneCallsFlow // Subscribe to calls only when other data is ready
                .map { phoneCalls in
                    phoneCalls
                        .filter { isInLastTwoWeeks(Date(timeIntervalSince1970: TimeInterval($0.date) / 1000)) }
                        .compactMap { call -> RecentPhoneData? in
                            guard let number = numberDict[call.phoneNumber],
                                  let territory = territories.first(where: { $0.id == number.territory }) else {
                                return nil
                            }
                            return RecentPhoneData(
                                id: UUID(),
                                territory: convertPhoneTerritoryModelToPhoneTerritoryModel(model: territory),
                                lastCall: convertPhoneCallModelToPhoneCallModel(model: call)
                            )
                        }
                        .unique { $0.territory.id }
                }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }



    @MainActor
    func getKeyUsers(token: MyTokenModel) -> AnyPublisher<[UserTokenModel], Never> {
        return Just(userTokensFlow)
            .flatMap { keyUsers -> AnyPublisher<[UserTokenModel], Never> in
                var data = [UserTokenModel]()
                print(keyUsers.count)
                for user in keyUsers {
                    if user.token == token.id {
                        data.append(convertUserTokenToModel(model: user))
                    }
                }
                
                data.sort { $0.name < $1.name }
                return Just(data).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    @MainActor
    func searchEverywhere(query: String, searchMode: SearchMode) -> AnyPublisher<[MySearchResult], Never> {
        let territoriesPublisher = $territoriesFlow.eraseToAnyPublisher()
        let addressesPublisher = $addressesFlow.eraseToAnyPublisher()
        let housesPublisher = $housesFlow.eraseToAnyPublisher()
        let visitsPublisher = $visitsFlow.eraseToAnyPublisher()
        let phoneTerritoriesPublisher = $phoneTerritoriesFlow.eraseToAnyPublisher()
        let numbersPublisher = $phoneNumbersFlow.eraseToAnyPublisher()
        let callsPublisher = $phoneCallsFlow.eraseToAnyPublisher()

        let combinedPublisher: AnyPublisher<[MySearchResult], Never>
        
        switch searchMode {
        case .Territories:
            combinedPublisher = Publishers.CombineLatest4(
                territoriesPublisher,
                addressesPublisher,
                housesPublisher,
                visitsPublisher
            )
            .map { (territories, addresses, houses, visits) -> [MySearchResult] in
                var results: [MySearchResult] = []

                territories.forEach { territory in
                    if String(territory.number).localizedCaseInsensitiveContains(query) || territory.territoryDescription.localizedCaseInsensitiveContains(query) {
                        results.append(MySearchResult(type: .Territory, territory: convertTerritoryToTerritoryModel(model: territory)))
                    }
                }
                
                addresses.forEach { address in
                    if address.address.localizedCaseInsensitiveContains(query),
                       let territory = territories.first(where: { $0.id == address.territory }) {
                        results.append(MySearchResult(type: .Address, territory: convertTerritoryToTerritoryModel(model: territory), address: convertTerritoryToTerritoryAddressModel(model: address)))
                    }
                }
                
                houses.forEach { house in
                    if house.number.localizedCaseInsensitiveContains(query),
                       let address = addresses.first(where: { $0.id == house.territory_address }),
                       let territory = territories.first(where: { $0.id == address.territory }) {
                        results.append(MySearchResult(type: .House, territory: convertTerritoryToTerritoryModel(model: territory), address: convertTerritoryToTerritoryAddressModel(model: address), house: convertHouseToHouseModel(model: house)))
                    }
                }
                
                visits.forEach { visit in
                    if visit.notes.localizedCaseInsensitiveContains(query) || visit.user.localizedCaseInsensitiveContains(query),
                       let house = houses.first(where: { $0.id == visit.house }),
                       let address = addresses.first(where: { $0.id == house.territory_address }),
                       let territory = territories.first(where: { $0.id == address.territory }) {
                        results.append(MySearchResult(type: .Visit, territory: convertTerritoryToTerritoryModel(model: territory), address: convertTerritoryToTerritoryAddressModel(model: address), house: convertHouseToHouseModel(model: house), visit: convertVisitToVisitModel(model: visit)))
                    }
                }

                return results
            }
            .eraseToAnyPublisher()

        case .PhoneTerritories:
            combinedPublisher = Publishers.CombineLatest3(
                phoneTerritoriesPublisher,
                numbersPublisher,
                callsPublisher
            )
            .map { (phoneTerritories, numbers, calls) -> [MySearchResult] in
                var results: [MySearchResult] = []

                phoneTerritories.forEach { phoneTerritory in
                    if String(phoneTerritory.number).localizedCaseInsensitiveContains(query) || phoneTerritory.description.localizedCaseInsensitiveContains(query) {
                        results.append(MySearchResult(type: .PhoneTerritory, phoneTerritory: convertPhoneTerritoryModelToPhoneTerritoryModel(model: phoneTerritory)))
                    }
                }

                numbers.forEach { number in
                    if number.number.localizedCaseInsensitiveContains(query),
                       let phoneTerritory = phoneTerritories.first(where: { $0.id == number.territory }) {
                        results.append(MySearchResult(type: .Number, phoneTerritory: convertPhoneTerritoryModelToPhoneTerritoryModel(model: phoneTerritory), number: convertPhoneNumberModelToPhoneNumberModel(model: number)))
                    }
                }

                calls.forEach { call in
                    if call.notes.localizedCaseInsensitiveContains(query) || call.user.localizedCaseInsensitiveContains(query),
                       let number = numbers.first(where: { $0.id == call.phoneNumber }),
                       let phoneTerritory = phoneTerritories.first(where: { $0.id == number.territory }) {
                        results.append(MySearchResult(type: .Call, phoneTerritory: convertPhoneTerritoryModelToPhoneTerritoryModel(model: phoneTerritory), number: convertPhoneNumberModelToPhoneNumberModel(model: number), call: convertPhoneCallModelToPhoneCallModel(model: call)))
                    }
                }

                return results
            }
            .eraseToAnyPublisher()
        }

        return combinedPublisher
    }

    
    func phoneCallAccessLevel(call: PhoneCallObject, email: String) -> AccessLevel {
        if AuthorizationLevelManager().existsAdminCredentials() {
            return .Admin
        } else if call.user == email {
            return .Moderator
        } else {
            return .User
        }
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

extension Array {
    func unique<T:Hashable>(map: ((Element) -> (T)))  -> [Element] {
        var set = Set<T>() //the unique list kept in a Set for fast retrieval
        var arrayOrdered = [Element]() //keeping the unique list of elements but ordered
        for value in self {
            if !set.contains(map(value)) {
                set.insert(map(value))
                arrayOrdered.append(value)
            }
        }

        return arrayOrdered
    }
}
