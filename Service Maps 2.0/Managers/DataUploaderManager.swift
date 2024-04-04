//
//  DataUploaderManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/27/23.
//

import Foundation
import BackgroundTasks
import SwiftUI

class DataUploaderManager: ObservableObject {
    
    @Published private var authorizationLevelManager = AuthorizationLevelManager()
    @Published private var dataController = DataController.shared
    @Published private var dataStore = StorageManager.shared
    
    init() {
        allData()
    }
    
    private var territories = [Territory]()
    private var houses = [House]()
    private var visits = [Visit]()
    private var tokens = [MyToken]()
    private var territoryAddresses = [TerritoryAddress]()
    private var tokenTerritories = [TokenTerritory]()
    
    private var adminApi = AdminAPI()
    private var userApi = UserAPI()
    private var tokenApi = TokenAPI()
    
    func addTerritory(territory: Territory, image: UIImage? = nil) async -> Result<Bool, Error> {
        allData()
        
        var result: Result<Bool, Error>?
        
        if(image == nil) {
            do {
                try await adminApi.addTerritory(territory: TerritoryModel(id: territory.id!, congregation: territory.congregation!, number: String(territory.number), description: territory.description, created_at: "", updated_at: ""))
                result = Result.success(true)
            } catch {
                await addPendingChange(pendingChange: PendingChange(id: UUID(), changeType: .Territory, changeAction: .Add, modelId: territory.id!))
                result = Result.failure(error)
            }
        } else {
            //Add IMAGE Function here
            do {
                try await adminApi.addTerritory(territory: TerritoryModel(id: territory.id!, congregation: territory.congregation!, number: String(territory.number), description: territory.description, created_at: "", updated_at: ""), image: image!)
                result = Result.success(true)
            } catch {
                await addPendingChange(pendingChange: PendingChange(id: UUID(), changeType: .Territory, changeAction: .Add, modelId: territory.id!))
                result = Result.failure(error)
            }
        }
        
        switch result {
        case .success(true):
            dataController.container.viewContext.insert(territory)
            if dataController.container.viewContext.hasChanges {
                do {
                    try dataController.container.viewContext.save()
                    
                } catch {
                    return Result.failure(error)
                }
            }
        default:
            print("Si no se pudo no se pudo (DatauploaderManager ADD TERRITORY)")
        }
        
        return result ?? Result.failure(NotFoundError.NotFound)
    }
    
    func addTerritoryAddress(territoryAddress: TerritoryAddress) async -> Result<Bool, Error> {
        allData()
        
        var result: Result<Bool, Error>?
        
        do {
            try await adminApi.addTerritoryAddress(territoryAddress: TerritoryAddressModel(id: territoryAddress.id!, territory: territoryAddress.territory!, address: territoryAddress.address!, created_at: "", updated_at: ""))
            result = Result.success(true)
        } catch {
            await addPendingChange(pendingChange: PendingChange(id: UUID(), changeType: .TerritoryAddress, changeAction: .Add, modelId: territoryAddress.id!))
            result = Result.failure(error)
        }
        
        switch result {
        case .success(true):
            dataController.container.viewContext.insert(territoryAddress)
            if dataController.container.viewContext.hasChanges {
                do {
                    try dataController.container.viewContext.save()
                    
                } catch {
                    return Result.failure(error)
                }
            }
        default:
            print("Si no se pudo no se pudo (DatauploaderManager ADD TERRITORYADDRESS)")
        }
        
        return result ?? Result.failure(NotFoundError.NotFound)
    }
    
    func addHouse(house: House) async -> Result<Bool, Error> {
        allData()
        
        var result: Result<Bool, Error>?
        
        do {
            try await adminApi.addHouse(house: HouseModel(id: house.id!, territory_address: house.territoryAddress!, number: house.number!, created_at: "", updated_at: ""))
            result = Result.success(true)
        } catch {
            await addPendingChange(pendingChange: PendingChange(id: UUID(), changeType: .House, changeAction: .Add, modelId: house.id!))
            result = Result.failure(error)
        }
        
        switch result {
        case .success(true):
            dataController.container.viewContext.insert(house)
            if dataController.container.viewContext.hasChanges {
                do {
                    try dataController.container.viewContext.save()
                } catch {
                    return Result.failure(error)
                }
            }
        default:
            print("Si no se pudo no se pudo (DatauploaderManager ADD HOUSE)")
        }
        
        return result ?? Result.failure(NotFoundError.NotFound)
    }
    
    func addVisit(visit: Visit) async -> Result<Bool, Error> {
        allData()
        var result: Result<Bool, Error>?
        
        do {
            try await adminApi.addVisit(visit: VisitModel(id: visit.id!, house: visit.house!, date: visit.date, symbol: visit.symbol!, notes: visit.notes!, user: visit.user!, created_at: "", updated_at: ""))
            result = Result.success(true)
        } catch {
            await addPendingChange(pendingChange: PendingChange(id: UUID(), changeType: .Visit, changeAction: .Add, modelId: visit.id!))
            result = Result.failure(error)
        }
        
        switch result {
        case .success(true):
            dataController.container.viewContext.insert(visit)
            if dataController.container.viewContext.hasChanges {
                do {
                    try dataController.container.viewContext.save()
                } catch {
                    return Result.failure(error)
                }
            }
        default:
            print("Si no se pudo no se pudo (DatauploaderManager ADD VISIT)")
        }
        
        return result ?? Result.failure(NotFoundError.NotFound)
    }
    
    func updateTerritory(territory: Territory, image: UIImage? = nil) async -> Result<Bool, Error> {
        allData()
        
        var result: Result<Bool, Error>?
        
        
        if authorizationLevelManager.existsAdminCredentials() {
            if image == nil {
                do {
                    try await adminApi.updateTerritory(territory: TerritoryModel(id: territory.id!, congregation: territory.congregation!, number: String(territory.number), description: territory.description, created_at: "", updated_at: ""))
                    result = Result.success(true)
                } catch {
                    await addPendingChange(pendingChange: PendingChange(id: UUID(), changeType: .Territory, changeAction: .Update, modelId: territory.id!))
                    result = Result.failure(error)
                }
            } else {
                do {
                    try await adminApi.updateTerritory(territory: TerritoryModel(id: territory.id!, congregation: territory.congregation!, number: String(territory.number), description: territory.description, created_at: "", updated_at: ""), image: image!)
                    result = Result.success(true)
                } catch {
                    await addPendingChange(pendingChange: PendingChange(id: UUID(), changeType: .Territory, changeAction: .Update, modelId: territory.id!))
                    result = Result.failure(error)
                }
            }
        } else {
            await authorizationLevelManager.setAuthorizationTokenFor(model: territory)
            if image == nil {
                do {
                    try await userApi.updateTerritory(territory: TerritoryModel(id: territory.id!, congregation: territory.congregation!, number: String(territory.number), description: territory.description, created_at: "", updated_at: ""))
                    result = Result.success(true)
                } catch {
                    await addPendingChange(pendingChange: PendingChange(id: UUID(), changeType: .Territory, changeAction: .Update, modelId: territory.id!))
                    result = Result.failure(error)
                }
            } else {
                do {
                    try await userApi.updateTerritory(territory: TerritoryModel(id: territory.id!, congregation: territory.congregation!, number: String(territory.number), description: territory.description, created_at: "", updated_at: ""), image: image!)
                    result = Result.success(true)
                } catch {
                    await addPendingChange(pendingChange: PendingChange(id: UUID(), changeType: .Territory, changeAction: .Update, modelId: territory.id!))
                    result = Result.failure(error)
                }
            }
        }
        
        switch result {
        case .success(true):
            let territoryToUpdate = territories.first(where: { $0.id == territory.id})
            territoryToUpdate?.number = territory.number
            territoryToUpdate?.territoryDescription = territory.territoryDescription
            territoryToUpdate?.congregation = territory.description
            territoryToUpdate?.image = territory.image
            do {
                try dataController.container.viewContext.save()
            } catch {
                return Result.failure(error)
            }
        default:
            print("Si no se pudo no se pudo (DatauploaderManager UPDATETERRITORY)")
        }
        
        return result ?? Result.failure(NotFoundError.NotFound)
    }
    
    func updateTerritoryAddress(territoryAddress: TerritoryAddress) async -> Result<Bool, Error> {
        allData()
        
        var result: Result<Bool, Error>?
        
        if authorizationLevelManager.existsAdminCredentials() {
            do {
                try await adminApi.updateTerritoryAddress(territoryAddress: TerritoryAddressModel(id: territoryAddress.id!, territory: territoryAddress.territory!, address: territoryAddress.address!, created_at: "", updated_at: ""))
                result = Result.success(true)
            } catch {
                await addPendingChange(pendingChange: PendingChange(id: UUID(), changeType: .TerritoryAddress, changeAction: .Update, modelId: territoryAddress.id!))
                result = Result.failure(error)
            }
        } else {
            await authorizationLevelManager.setAuthorizationTokenFor(model: territoryAddress)
            do {
                try await userApi.updateTerritoryAddress(territoryAddress: TerritoryAddressModel(id: territoryAddress.id!, territory: territoryAddress.territory!, address: territoryAddress.address!, created_at: "", updated_at: ""))
                result = Result.success(true)
            } catch {
                await addPendingChange(pendingChange: PendingChange(id: UUID(), changeType: .TerritoryAddress, changeAction: .Update, modelId: territoryAddress.id!))
                result = Result.failure(error)
            }
        }
        
        switch result {
        case .success(true):
            let territoryAddressToUpdate = territoryAddresses.first(where: { $0.id == territoryAddress.id})
            territoryAddressToUpdate?.territory = territoryAddress.territory
            territoryAddressToUpdate?.address = territoryAddress.address
            territoryAddressToUpdate?.floors = territoryAddress.floors
            do {
                try dataController.container.viewContext.save()
            } catch {
                return Result.failure(error)
            }
        default:
            print("Si no se pudo no se pudo (DatauploaderManager UPDATETERRITORYADDRESS)")
        }
        
        return result ?? Result.failure(NotFoundError.NotFound)
    }
    
    func updateHouse(house: House) async -> Result<Bool, Error> {
        allData()
        
        var result: Result<Bool, Error>?
        
        if authorizationLevelManager.existsAdminCredentials() {
            do {
                try await adminApi.updateHouse(house: HouseModel(id: house.id!, territory_address: house.territoryAddress!, number: house.number!, created_at: "", updated_at: ""))
                result = Result.success(true)
            } catch {
                await addPendingChange(pendingChange: PendingChange(id: UUID(), changeType: .House, changeAction: .Update, modelId: house.id!))
                result = Result.failure(error)
            }
        } else {
            await authorizationLevelManager.setAuthorizationTokenFor(model: house)
            do {
                try await userApi.updateHouse(house: HouseModel(id: house.id!, territory_address: house.territoryAddress!, number: house.number!, created_at: "", updated_at: ""))
                result = Result.success(true)
            } catch {
                await addPendingChange(pendingChange: PendingChange(id: UUID(), changeType: .House, changeAction: .Update, modelId: house.id!))
                result = Result.failure(error)
            }
        }
        
        switch result {
        case .success(true):
            let houseToUpdate = houses.first(where: { $0.id == house.id})
            houseToUpdate?.territoryAddress = house.territoryAddress
            houseToUpdate?.floor = house.floor
            houseToUpdate?.number = house.number
            do {
                try dataController.container.viewContext.save()
            } catch {
                return Result.failure(error)
            }
        default:
            print("Si no se pudo no se pudo (DatauploaderManager UPDATEHOUSE)")
        }
        
        return result ?? Result.failure(NotFoundError.NotFound)
    }
    
    func updateVisit(visit: Visit) async -> Result<Bool, Error> {
        allData()
        
        
        var result: Result<Bool, Error>?
        
        if authorizationLevelManager.existsAdminCredentials() {
            do {
                try await adminApi.updateVisit(visit: VisitModel(id: visit.id!, house: visit.house!, date: visit.date, symbol: visit.symbol!, notes: visit.notes!, user: visit.user!, created_at: "", updated_at: ""))
                result = Result.success(true)
            } catch {
                await addPendingChange(pendingChange: PendingChange(id: UUID(), changeType: .Visit, changeAction: .Update, modelId: visit.id!))
                result = Result.failure(error)
            }
        } else {
            await authorizationLevelManager.setAuthorizationTokenFor(model: visit)
            do {
                try await adminApi.updateVisit(visit: VisitModel(id: visit.id!, house: visit.house!, date: visit.date, symbol: visit.symbol!, notes: visit.notes!, user: visit.user!, created_at: "", updated_at: ""))
                result = Result.success(true)
            } catch {
                await addPendingChange(pendingChange: PendingChange(id: UUID(), changeType: .Visit, changeAction: .Update, modelId: visit.id!))
                result = Result.failure(error)
            }
        }
        
        switch result {
        case .success(true):
            let visitsToUpdate = visits.first(where: { $0.id == visit.id})
            visitsToUpdate?.house = visit.house
            visitsToUpdate?.date = visit.date
            visitsToUpdate?.notes = visit.notes
            visitsToUpdate?.symbol = visit.symbol
            visitsToUpdate?.user = visit.user
            
            do {
                try dataController.container.viewContext.save()
            } catch {
                return Result.failure(error)
            }
        default:
            print("Si no se pudo no se pudo (DatauploaderManager UPDATEVISIT)")
        }
        
        return result ?? Result.failure(NotFoundError.NotFound)
    }
    
    func deleteTerritory(territory: Territory) async -> Result<Bool, Error> {
        allData()
        do {
            try await adminApi.deleteTerritory(territory: TerritoryModel(id: territory.id!, congregation: territory.congregation!, number: String(territory.number), description: territory.description, created_at: "", updated_at: ""))
            dataController.container.viewContext.delete(territory)
            return Result.success(true)
        } catch {
            await addPendingChange(pendingChange: PendingChange(id: UUID(), changeType: .Territory, changeAction: .Delete, modelId: territory.id!))
            return Result.failure(error)
        }
    }
    
    func deleteTerritoryAddress(territoryAddress: TerritoryAddress) async -> Result<Bool, Error> {
        allData()
        do {
            try await adminApi.deleteTerritoryAddress(territoryAddress: TerritoryAddressModel(id: territoryAddress.id!, territory: territoryAddress.territory!, address: territoryAddress.address!, created_at: "", updated_at: ""))
            dataController.container.viewContext.delete(territoryAddress)
            return Result.success(true)
        } catch {
            await addPendingChange(pendingChange: PendingChange(id: UUID(), changeType: .TerritoryAddress, changeAction: .Delete, modelId: territoryAddress.id!))
            return Result.failure(error)
        }
    }
    
    func deleteHouse(house: House) async -> Result<Bool, Error> {
        allData()
        do {
            try await adminApi.deleteHouse(house: HouseModel(id: house.id!, territory_address: house.territoryAddress!, number: house.number!, created_at: "", updated_at: ""))
            dataController.container.viewContext.delete(house)
            return Result.success(true)
        } catch {
            await addPendingChange(pendingChange: PendingChange(id: UUID(), changeType: .House, changeAction: .Delete, modelId: house.id!))
            return Result.failure(error)
        }
    }
    
    func deleteVisit(visit: Visit) async -> Result<Bool, Error> {
        allData()
        do {
            try await adminApi.deleteVisit(visit: VisitModel(id: visit.id!, house: visit.house!, date: visit.date, symbol: visit.symbol!, notes: visit.notes!, user: visit.user!, created_at: "", updated_at: ""))
            dataController.container.viewContext.delete(visit)
            return Result.success(true)
        } catch {
            await addPendingChange(pendingChange: PendingChange(id: UUID(), changeType: .Visit, changeAction: .Delete, modelId: visit.id!))
            return Result.failure(error)
        }
    }
    
    
    
    func createToken(newTokenForm: NewTokenForm, territories: [Territory]) async -> Result<MyToken, Error> {
        do {
            let token = try await tokenApi.createToken(name: newTokenForm.name, moderator: newTokenForm.moderator, territories: newTokenForm.territories, congregation: newTokenForm.congregation, expire: newTokenForm.expire)
            
            var tokenTerritories = [TokenTerritory]()
            
            let newToken = MyToken(context: dataController.container.viewContext)
            newToken.id = token.id
            newToken.moderator = token.moderator
            newToken.congregation = token.congregation
            if let expire = token.expire {
                newToken.expires = expire
            }
            newToken.name = token.name
            newToken.owner = token.owner
            newToken.user = token.user
            
            try dataController.container.viewContext.save()
            
            for territory in territories {
                let newTokenTerritory = TokenTerritory()
                newTokenTerritory.token = newToken.id
                newTokenTerritory.territory = territory.id
                tokenTerritories.append(newTokenTerritory)
            }
            
            tokenTerritories.forEach { tokenTerritory in
                dataController.container.viewContext.insert(tokenTerritory)
            }
            
            return Result.success(newToken)
            
        } catch {
            return Result.failure(error)
        }
    }
    
    func deleteToken(myToken: MyToken) async -> Result<Bool, Error> {
        do {
            try await tokenApi.deleteToken(token: myToken.id!)
            
            tokens.forEach { token in
                tokenTerritories.forEach { tokenTerritory in
                    if token.id == tokenTerritory.token {
                        dataController.container.viewContext.delete(tokenTerritory)
                    }
                    dataController.container.viewContext.delete(token)
                }
            }
            
            return Result.success(true)
            
        } catch {
            return Result.failure(error)
        }
    }
    
    func addPendingChange(pendingChange: PendingChange) async {
        dataStore.pendingChanges.append(pendingChange)
        //Schedule background task
        ReuploaderWorker.shared.scheduleReupload(minutes: 15.0)
    }
    
    func getAllPendingChanges() async -> [PendingChange] {
        return dataStore.pendingChanges
    }
    
    
    func allData() {
        territories = dataController.getTerritories()
        houses = dataController.getHouses()
        visits = dataController.getVisits()
        tokens = dataController.getMyTokens()
        territoryAddresses = dataController.getTerritoryAddresses()
        tokenTerritories = dataController.getTokenTerritories()
    }
    
    
}
