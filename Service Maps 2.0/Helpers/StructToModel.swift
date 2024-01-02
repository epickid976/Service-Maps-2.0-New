//
//  StructToModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/1/23.
//

import Foundation

class StructToModel {
    
    private var dataController = DataController.shared
    private var privateContext = DataController.shared.container.viewContext
    
    //MARK: Converting MYTOKENMODEL to MYTOKEN
    func convertTokenStructsToEntities(structs: [MyTokenModel]) -> [MyToken] {
        var entities: [MyToken] = []

        for myStruct in structs {
            let entity = MyToken(context: privateContext)
            entity.id = myStruct.id
            entity.name = myStruct.name
            entity.congregation = myStruct.congregation
            entity.moderator = myStruct.moderator
            
            if let expiration = myStruct.expire {
                entity.expires = expiration
            }
            
            
            
            entity.owner = myStruct.owner
            entity.user = myStruct.user
            // Set other properties as needed

            entities.append(entity)
        }

        return entities
    }
    
    //MARK: Converting TOKENTERRITORIESMODEL to TOKENTERRITORIES
    func convertTokenTerritoriesStructsToEntities(structs: [TokenTerritoryModel]) -> [TokenTerritory] {
        var entities: [TokenTerritory] = []

        for myStruct in structs {
            let entity = TokenTerritory(context: privateContext)
            entity.token = myStruct.token
            entity.territory = myStruct.territory
            // Set other properties as needed

            entities.append(entity)
        }

        return entities
    }
    
    func convertTerritoryAddressStructsToEntities(structs: [TerritoryAddressModel]) -> [TerritoryAddress] {
        var entities: [TerritoryAddress] = []

        for myStruct in structs {
            let entity = TerritoryAddress(context: privateContext)
            entity.id = myStruct.id
            entity.territory = myStruct.territory
            entity.address = myStruct.address
            
            entity.floors = Int16(myStruct.floors ?? 0)
            
            // Set other properties as needed

            entities.append(entity)
        }

        return entities
    }
    
    //MARK: Converting TERRITORYMODEL to TERRITORY
    func convertTerritoryStructsToEntities(structs: [TerritoryModel]) -> [Territory] {
        var entities: [Territory] = []

        for myStruct in structs {
            let entity = Territory(context: privateContext)
            entity.id = myStruct.id
            entity.territoryDescription = myStruct.description
            entity.congregation = myStruct.congregation
            
            entity.image = myStruct.image
            entity.number = Int32(myStruct.number) ?? 0
            
            // Set other properties as needed

            entities.append(entity)
        }

        return entities
    }
    
    //MARK: Converting HOUSEMODEL to HOUSE
    func convertHouseStructsToEntities(structs: [HouseModel]) -> [House] {
        var entities: [House] = []

        for myStruct in structs {
            let entity = House(context: privateContext)
            entity.id = myStruct.id
            entity.number = myStruct.number
            entity.territoryAddress = myStruct.territory_address
            if let floor = myStruct.floor {
                entity.floor = Int16(floor)!
            }
            // Set other properties as needed

            entities.append(entity)
        }

        return entities
    }
    
    //MARK: Converting VISITMODEL to VISIT
    func convertVisitStructsToEntities(structs: [VisitModel]) -> [Visit] {
        var entities: [Visit] = []

        for myStruct in structs {
            let entity = Visit(context: privateContext)
            entity.id = myStruct.id
            entity.date = myStruct.date
            entity.house = myStruct.house
            entity.notes = myStruct.notes
            entity.symbol = myStruct.symbol
            entity.user = myStruct.user
            // Set other properties as needed

            entities.append(entity)
        }

        return entities
    }
}
