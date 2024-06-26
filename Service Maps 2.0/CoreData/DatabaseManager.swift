////
////  DataBaseManager.swift
////  Service Maps 2.0
////
////  Created by Jose Blanco on 4/9/24.
////
//
//import Foundation
//import CoreData
//import Combine
//
//class DatabaseManager: ObservableObject {
//    static let shared = DatabaseManager()
//    
//    var privateViewContext: NSManagedObjectContext
//
//    let container: NSPersistentContainer
//    
//    @Published var territoriesFlow: [TerritoryModel] = [TerritoryModel]()
//    @Published var addressesFlow: [TerritoryAddressModel] = [TerritoryAddressModel]()
//    @Published var housesFlow: [HouseModel] = [HouseModel]()
//    @Published var visitsFlow: [VisitModel] = [VisitModel]()
//    @Published var tokensFlow: [MyTokenModel] = [MyTokenModel]()
//    @Published var tokenTerritoriesFlow: [TokenTerritoryModel] = [TokenTerritoryModel]()
//    
//    init() {
//        container = NSPersistentContainer(name: "Service_Maps")
//
//        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
//            if let error = error as NSError? {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                
//                /*
//                 Typical reasons for an error here include:
//                 * The parent directory does not exist, cannot be created, or disallows writing.
//                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
//                 * The device is out of space.
//                 * The store could not be migrated to the current model version.
//                 Check the error message to determine what the actual problem was.
//                 */
//                fatalError("Unresolved error \(error), \(error.userInfo)")
//            }
//        })
//        
//        privateViewContext = container.viewContext
//        privateViewContext.automaticallyMergesChangesFromParent = true
//    }
//    
//    func commit() -> Result<Bool, Error> {
//        let context = privateViewContext
//        
//        if context.hasChanges {
//            do {
//                 try context.save()
//                return Result.success(true)
//            } catch {
//                print("ERROR Saving CONTEXT")
//                // Show some error here
//                return Result.failure(error)
//            }
//        }
//        
//        return Result.failure(CustomErrors.NothingToSave)
//    }
//    
//    func addTerritory(territory: TerritoryModel) -> Result<Bool, Error> {
//        let newterritory = StructToModel().convertTerritoryStructToEntity(structure: territory)
//        
//        privateViewContext.insert(newterritory)
//        
//        switch commit() {
//        case .success(let success):
//            refreshTerritories()
//            return Result.success(success)
//        case .failure(let error):
//            return Result.failure(error)
//        }
//    }
//    
//    func addAddress(address: TerritoryAddressModel) -> Result<Bool, Error> {
//        let newAddress = StructToModel().convertTerritoryAddressStructToEntity(structure: address)
//        
//        privateViewContext.insert(newAddress)
//        
//        switch commit() {
//        case .success(let success):
//            refreshAddresses()
//            return Result.success(success)
//        case .failure(let error):
//            return Result.failure(error)
//        }
//    }
//    
//    func addHouse(house: HouseModel) -> Result<Bool, Error> {
//        let newHouse = StructToModel().convertHouseStructToEntity(structure: house)
//        
//        privateViewContext.insert(newHouse)
//        
//        switch commit() {
//        case .success(let success):
//            refreshHouses()
//            return Result.success(success)
//        case .failure(let error):
//            return Result.failure(error)
//        }
//    }
//    
//    func addVisit(visit: VisitModel) -> Result<Bool, Error> {
//        let newVisit = StructToModel().convertVisitStructToEntity(structure: visit)
//        
//        privateViewContext.insert(newVisit)
//        
//        switch commit() {
//        case .success(let success):
//            refreshVisits()
//            return Result.success(success)
//        case .failure(let error):
//            return Result.failure(error)
//        }
//    }
//    
//    func addToken(token: MyTokenModel) -> Result<Bool, Error> {
//        let newToken = StructToModel().convertTokenStructToEntity(structure: token)
//        
//        privateViewContext.insert(newToken)
//        
//        switch commit() {
//        case .success(let success):
//            refreshTokens()
//            return Result.success(success)
//        case .failure(let error):
//            return Result.failure(error)
//        }
//    }
//    
//    func addTokenTerritory(tokenTerritory: TokenTerritoryModel) -> Result<Bool, Error> {
//        let newTokenTerritory = StructToModel().convertTokenTerritoryStructToEntity(structure: tokenTerritory)
//        
//        privateViewContext.insert(newTokenTerritory)
//        
//        switch commit() {
//        case .success(let success):
//            refreshTokenTerritories()
//            return Result.success(success)
//        case .failure(let error):
//            return Result.failure(error)
//        }
//    }
//    
//    func updateTerritory(territory: TerritoryModel) -> Result<Bool, Error> {
//        var territories = getTerritories()
//        
//        let entity = territories.first(where: { $0.id == territory.id})
//        if let entity = entity {
//            entity.id = territory.id
//            entity.congregation = territory.congregation
//            entity.number = territory.number
//            entity.territoryDescription = territory.description
//            entity.image = territory.image
//            
//            switch commit() {
//            case .success(let success):
//                refreshTerritories()
//                return Result.success(success)
//            case .failure(let error):
//                return Result.failure(error)
//            }
//            
//        } else {
//            return Result.failure(CustomErrors.NotFound)
//        }
//    }
//    
//    func updateAddress(address: TerritoryAddressModel) -> Result<Bool, Error> {
//        var addresses = getTerritoryAddresses()
//        
//        let entity = addresses.first(where: { $0.id == address.id})
//        if let entity = entity {
//            entity.id = address.id
//            entity.territory = address.territory
//            entity.address = address.address
//            entity.floors = Int16(address.floors ?? 0)
//            
//            switch commit() {
//            case .success(let success):
//                refreshAddresses()
//                return Result.success(success)
//            case .failure(let error):
//                return Result.failure(error)
//            }
//        } else {
//            return Result.failure(CustomErrors.NotFound)
//        }
//    }
//    
//    func updateHouse(house: HouseModel) -> Result<Bool, Error> {
//        var houses = getHouses()
//        
//        let entity = houses.first(where: { $0.id == house.id})
//        if let entity = entity {
//            entity.id = house.id
//            entity.territoryAddress = house.territory_address
//            entity.number = house.number
//            if let floorString = house.floor, let floor = Int16(floorString) {
//              entity.floor = floor
//            }
//            
//            switch commit() {
//            case .success(let success):
//                refreshHouses()
//                return Result.success(success)
//            case .failure(let error):
//                return Result.failure(error)
//            }
//        } else {
//            return Result.failure(CustomErrors.NotFound)
//        }
//    }
//    
//    func updateVisit(visit: VisitModel) -> Result<Bool, Error> {
//        var visits = getVisits()
//        
//        let entity = visits.first(where: { $0.id == visit.id})
//        if let entity = entity {
//            entity.id = visit.id
//            entity.house = visit.house
//            entity.date = visit.date // Assuming date is a unix timestamp
//            entity.symbol = visit.symbol
//            entity.notes = visit.notes
//            entity.user = visit.user
//            
//            switch commit() {
//            case .success(let success):
//                refreshVisits()
//                return Result.success(success)
//            case .failure(let error):
//                return Result.failure(error)
//            }
//        } else {
//            return Result.failure(CustomErrors.NotFound)
//        }
//    }
//    
//    func updateToken(token: MyTokenModel) -> Result<Bool, Error> {
//        var tokens = getMyTokens()
//        
//        let entity = tokens.first(where: { $0.id == token.id})
//        if let entity = entity {
//            entity.id = token.id
//            entity.name = token.name
//            entity.owner = token.owner
//            entity.congregation = token.congregation
//            entity.moderator = token.moderator
//            entity.expires = token.expire ?? 0
//            entity.user = token.user
//            
//            switch commit() {
//            case .success(let success):
//                refreshTokens()
//                return Result.success(success)
//            case .failure(let error):
//                return Result.failure(error)
//            }
//        } else {
//            return Result.failure(CustomErrors.NotFound)
//        }
//    }
//    
//    func updateTokenTerritory(tokenTerritory: TokenTerritoryModel) -> Result<Bool, Error> {
//        var tokenTerritories = getTokenTerritories()
//        
//        let entity = tokenTerritories.first(where: { ($0.token == tokenTerritory.token) && ($0.territory == tokenTerritory.territory)})
//        if let entity = entity {
//            entity.token = tokenTerritory.token
//            entity.territory = tokenTerritory.territory
//            
//            switch commit() {
//            case .success(let success):
//                refreshTokenTerritories()
//                return Result.success(success)
//            case .failure(let error):
//                return Result.failure(error)
//            }
//        } else {
//            return Result.failure(CustomErrors.NotFound)
//        }
//    }
//    
//    func deleteTerritory(territory: TerritoryModel) -> Result<Bool, Error> {
//        var territories = getTerritories()
//        
//        guard let entity = territories.first(where: { $0.id == territory.id}) else { return Result.failure(CustomErrors.NotFound) }
//        
//        privateViewContext.delete(entity)
//        
//        switch commit() {
//        case .success(let success):
//            refreshTerritories()
//            return Result.success(success)
//        case .failure(let error):
//            return Result.failure(error)
//        }
//    }
//    
//    func deleteAddress(address: TerritoryAddressModel) -> Result<Bool, Error> {
//        var addresses = getTerritoryAddresses()
//        
//        guard let entity = addresses.first(where: { $0.id == address.id}) else { return Result.failure(CustomErrors.NotFound) }
//        
//        privateViewContext.delete(entity)
//        
//        switch commit() {
//        case .success(let success):
//            refreshAddresses()
//            return Result.success(success)
//        case .failure(let error):
//            return Result.failure(error)
//        }
//    }
//    
//    func deleteHouse(house: HouseModel) -> Result<Bool, Error> {
//        var houses = getHouses()
//        
//        guard let entity = houses.first(where: { $0.id == house.id}) else { return Result.failure(CustomErrors.NotFound) }
//        
//        privateViewContext.delete(entity)
//        
//        switch commit() {
//        case .success(let success):
//            refreshHouses()
//            return Result.success(success)
//        case .failure(let error):
//            return Result.failure(error)
//        }
//    }
//    
//    func deleteVisit(visit: VisitModel) -> Result<Bool, Error> {
//        var visits = getVisits()
//        
//        guard let entity = visits.first(where: { $0.id == visit.id}) else { return Result.failure(CustomErrors.NotFound) }
//        
//        privateViewContext.delete(entity)
//        
//        switch commit() {
//        case .success(let success):
//            refreshVisits()
//            return Result.success(success)
//        case .failure(let error):
//            return Result.failure(error)
//        }
//    }
//    
//    func deleteTokens(token: MyTokenModel) -> Result<Bool, Error> {
//        var tokens = getMyTokens()
//        
//        guard let entity = tokens.first(where: { $0.id == token.id}) else { return Result.failure(CustomErrors.NotFound) }
//        
//        privateViewContext.delete(entity)
//        
//        switch commit() {
//        case .success(let success):
//            refreshTokens()
//            return Result.success(success)
//        case .failure(let error):
//            return Result.failure(error)
//        }
//    }
//    
//    func deleteTokenTerritory(tokenTerritory: TokenTerritoryModel) -> Result<Bool, Error> {
//        var tokenTerritories = getTokenTerritories()
//        
//        guard let entity = tokenTerritories.first(where: { ($0.token == tokenTerritory.token) && ($0.territory == tokenTerritory.territory)}) else { return Result.failure(CustomErrors.NotFound) }
//        
//        privateViewContext.delete(entity)
//        
//        switch commit() {
//        case .success(let success):
//            refreshTokenTerritories()
//            return Result.success(success)
//        case .failure(let error):
//            return Result.failure(error)
//        }
//    }
//    
//    func getTerritories() -> [Territory] {
//        let viewContext = privateViewContext
//        let territoriesRequest = NSFetchRequest<NSManagedObject>(entityName: "Territory")
//        let territories = try! viewContext.fetch(territoriesRequest) as! [Territory]
//        
//        return territories
//    }
//    
//    func getHouses() -> [House] {
//        let viewContext = privateViewContext
//        let housesRequest = NSFetchRequest<NSManagedObject>(entityName: "House")
//        let houses = try! viewContext.fetch(housesRequest) as! [House]
//        
//        return houses
//    }
//    
//    func getVisits() -> [Visit] {
//        let viewContext = privateViewContext
//        let visitsRequest = NSFetchRequest<NSManagedObject>(entityName: "Visit")
//        let visits = try! viewContext.fetch(visitsRequest) as! [Visit]
//        
//        return visits
//    }
//    
//    func getMyTokens() -> [MyToken] {
//        let viewContext = privateViewContext
//        let tokensRequest = NSFetchRequest<NSManagedObject>(entityName: "MyToken")
//        let tokens = try! viewContext.fetch(tokensRequest) as! [MyToken]
//        
//        return tokens
//    }
//    
//    func getTerritoryAddresses() -> [TerritoryAddress] {
//        let viewContext = privateViewContext
//        let territoryAddressRequest = NSFetchRequest<NSManagedObject>(entityName: "TerritoryAddress")
//        let territoryAddresses = try! viewContext.fetch(territoryAddressRequest) as! [TerritoryAddress]
//        
//        return territoryAddresses
//    }
//    
//    func getTokenTerritories() -> [TokenTerritory] {
//      let viewContext = privateViewContext
//      let tokenTerritoryRequest = NSFetchRequest<NSManagedObject>(entityName: "TokenTerritory")
//      
//      do {
//        let tokenTerritory = try viewContext.fetch(tokenTerritoryRequest) as! [TokenTerritory]
//        return tokenTerritory
//      } catch {
//        // Handle the error appropriately, like printing error message or logging the issue
//        print("Error fetching TokenTerritory entities: \(error)")
//        return []  // Return an empty array in case of error
//      }
//    }
//
//    //
//    func refreshTerritories() {
//        let territoryEntities = getTerritories()
//        let structs = ModelToStruct().convertTerritoryEntitiesToStructs(entities: territoryEntities)
//        territoriesFlow = structs
//    }
//    
//    func refreshAddresses() {
//        let addressesEntities = getTerritoryAddresses()
//        let structs = ModelToStruct().convertTerritoryAddressEntitiesToStructs(entities: addressesEntities)
//        addressesFlow = structs
//    }
//    
//    func refreshHouses() {
//        let housesEntities = getHouses()
//        let structs = ModelToStruct().convertHouseEntitiesToStructs(entities: housesEntities)
//        housesFlow = structs
//    }
//    
//    func refreshVisits() {
//        let visitsEntities = getVisits()
//        let structs = ModelToStruct().convertVisitEntitiesToStructs(entities: visitsEntities)
//        visitsFlow = structs
//    }
//    
//    func refreshTokens() {
//        let tokensEntities = getMyTokens()
//        let structs = ModelToStruct().convertTokenEntitiesToStructs(entities: tokensEntities)
//        tokensFlow = structs
//    }
//    
//    func refreshTokenTerritories() {
//        let tokenTerritoryEntities = getTokenTerritories()
//        let structs = ModelToStruct().convertTokenTerritoryEntitiesToStructs(entities: tokenTerritoryEntities)
//        tokenTerritoriesFlow = structs
//    }
//    
//    func refreshAll() {
//        refreshTerritories()
//        refreshAddresses()
//        refreshHouses()
//        refreshVisits()
//        refreshTokens()
//        refreshTokenTerritories()
//    }
//    
//    func getTerritoryData() -> AnyPublisher<[TerritoryData], Never> {
//      let flow = Publishers.CombineLatest3(
//        $territoriesFlow,
//        $addressesFlow,
//        $housesFlow
//      )
//      .map { territoryData -> [TerritoryData] in
//        var data = [TerritoryData]()
//
//        for territory in territoryData.0 {
//          let currentAddresses = territoryData.1.filter { $0.territory == territory.id }
//            
//            let currentHouses = territoryData.1
//              .filter { $0.territory == territory.id }
//              .flatMap { address -> [HouseModel] in
//                return territoryData.2.filter { $0.territory_address == address.id }
//            }
//            
//          let territoryDataEntry = TerritoryData(
//            territory: territory,
//            addresses: currentAddresses,
//            housesQuantity: currentHouses.count,
//            accessLevel: AuthorizationLevelManager().getAccessLevel(model: territory) ?? .User // Implement your accessLevel logic
//          )
//          data.append(territoryDataEntry)
//        }
//
//        // Combine moderator and non-moderator data into a single array (corrected)
//        let combinedData = data.sorted(by: { $0.territory.number < $1.territory.number })
//        
//        return combinedData
//      }
//      .eraseToAnyPublisher()
//        
//     return flow
//    }
//}
