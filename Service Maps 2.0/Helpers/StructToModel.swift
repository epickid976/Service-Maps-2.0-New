//
//  StructToModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/1/23.
//

import Foundation

class StructToModel {
    
    private var dataController = DataController.shared
    
    //MARK: Converting MYTOKENMODEL to MYTOKEN
    func convertTokenStructsToEntities(structs: [MyTokenModel]) -> [MyToken] {
        var entities: [MyToken] = []

        for myStruct in structs {
            let entity = MyToken(context: dataController.container.viewContext)
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
            let entity = TokenTerritory(context: dataController.container.viewContext)
            entity.token = myStruct.token
            entity.territory = myStruct.territory
            // Set other properties as needed

            entities.append(entity)
        }

        return entities
    }
    
    //MARK: Converting TERRITORYMODEL to TERRITORY
    func convertTerritoryStructsToEntities(structs: [TerritoryModel]) -> [Territory] {
        var entities: [Territory] = []

        for myStruct in structs {
            let entity = Territory(context: dataController.container.viewContext)
            entity.id = myStruct.id
            entity.address = myStruct.address
            entity.congregation = myStruct.congregation
            if let floors = myStruct.floors {
                entity.floors = Int64(floors)
            }
            
            entity.image = myStruct.image
            entity.number = myStruct.number
            entity.section = myStruct.section
            
            // Set other properties as needed

            entities.append(entity)
        }

        return entities
    }
    
    //MARK: Converting HOUSEMODEL to HOUSE
    func convertHouseStructsToEntities(structs: [HouseModel]) -> [House] {
        var entities: [House] = []

        for myStruct in structs {
            let entity = House(context: dataController.container.viewContext)
            entity.id = myStruct.id
            entity.number = myStruct.number
            entity.territory = myStruct.territory
            
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
            let entity = Visit(context: dataController.container.viewContext)
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
