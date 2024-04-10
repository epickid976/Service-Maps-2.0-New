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
            entity.number = Int32(myStruct.number) 
            
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
    
    //MARK: Converting MYTOKENMODEL to MYTOKEN
      func convertTokenStructToEntity(structure: MyTokenModel) -> MyToken {
        let entity = MyToken(context: DataBaseManager.shared.container.viewContext)
        entity.id = structure.id
        entity.name = structure.name
        entity.owner = structure.owner
        entity.congregation = structure.congregation
        entity.moderator = structure.moderator
        entity.expires = structure.expire ?? 0
        entity.user = structure.user
        return entity
      }
      
      //MARK: Converting TOKENTERRITORIESMODEL to TOKENTERRITORIES
      func convertTokenTerritoryStructToEntity(structure: TokenTerritoryModel) -> TokenTerritory {
        let entity = TokenTerritory(context: DataBaseManager.shared.container.viewContext)
        entity.token = structure.token
        entity.territory = structure.territory
        return entity
      }
      
      func convertTerritoryAddressStructToEntity(structure: TerritoryAddressModel) -> TerritoryAddress {
        let entity = TerritoryAddress(context: DataBaseManager.shared.container.viewContext)
        entity.id = structure.id
        entity.territory = structure.territory
        entity.address = structure.address
        entity.floors = Int16(structure.floors ?? 0)
        return entity
      }
      
      //MARK: Converting TERRITORYMODEL to TERRITORY
      func convertTerritoryStructToEntity(structure: TerritoryModel) -> Territory {
        let entity = Territory(context: DataBaseManager.shared.container.viewContext)
        entity.id = structure.id
        entity.congregation = structure.congregation
        entity.number = structure.number
        entity.territoryDescription = structure.description
        entity.image = structure.image
        return entity
      }
      
      //MARK: Converting HOUSEMODEL to HOUSE
      func convertHouseStructToEntity(structure: HouseModel) -> House {
        let entity = House(context: DataBaseManager.shared.container.viewContext)
        entity.id = structure.id
        entity.territoryAddress = structure.territory_address
        entity.number = structure.number
        if let floorString = structure.floor, let floor = Int16(floorString) {
          entity.floor = floor
        }
        return entity
      }
      
      //MARK: Converting VISITMODEL to VISIT
      func convertVisitStructToEntity(structure: VisitModel) -> Visit {
          let entity = Visit(context: DataBaseManager.shared.container.viewContext)
        entity.id = structure.id
        entity.house = structure.house
        entity.date = structure.date // Assuming date is a unix timestamp
        entity.symbol = structure.symbol
        entity.notes = structure.notes
        entity.user = structure.user
        return entity
      }
}

//
// StructToModel.swift
// Service Maps 2.0
//
// Created by Jose Blanco on 8/1/23.
//

import Foundation

class ModelToStruct {
  
  private var dataController = DataController.shared
  
  //MARK: Converting MYTOKEN to MYTOKENMODEL
  func convertTokenEntitiesToStructs(entities: [MyToken]) -> [MyTokenModel] {
    var structs: [MyTokenModel] = []
    
    for entity in entities {
      let myStruct = MyTokenModel(id: entity.id ?? "",
                                 name: entity.name ?? "",
                                  owner: entity.owner ?? "", congregation: entity.congregation ?? "",
                                  moderator: entity.moderator ,
                                  expire: entity.expires ,
                                 user: entity.user,
                                created_at: "",
                                updated_at: "")
      structs.append(myStruct)
    }
    
    return structs
  }
  
  //MARK: Converting TOKENTERRITORIES to TOKENTERRITORIESMODEL
  func convertTokenTerritoryEntitiesToStructs(entities: [TokenTerritory]) -> [TokenTerritoryModel] {
    var structs: [TokenTerritoryModel] = []
    
    for entity in entities {
        let myStruct = TokenTerritoryModel(id: entity.id.debugDescription, token: entity.token ?? "", territory: entity.territory ?? "", created_at: "", updated_at: "")
      structs.append(myStruct)
    }
    
    return structs
  }
  
  func convertTerritoryAddressEntitiesToStructs(entities: [TerritoryAddress]) -> [TerritoryAddressModel] {
    var structs: [TerritoryAddressModel] = []
    
    for entity in entities {
        let myStruct = TerritoryAddressModel(id: entity.id ?? "",
                                           territory: entity.territory ?? "",
                                           address: entity.address ?? "",
                                           floors: Int(entity.floors),
                                            created_at: "", updated_at: "")
      structs.append(myStruct)
    }
    
    return structs
  }
  
  //MARK: Converting TERRITORY to TERRITORYMODEL
  func convertTerritoryEntitiesToStructs(entities: [Territory]) -> [TerritoryModel] {
    var structs: [TerritoryModel] = []
    
    for entity in entities {
      let myStruct = TerritoryModel(id: entity.id ?? "",
                                    congregation: entity.congregation ?? "",
                                    number: entity.number ,
                                    description: entity.image ?? "",
                                    image: entity.image,
                                    created_at: "", updated_at: "")
      structs.append(myStruct)
    }
    
    return structs
  }
  
  //MARK: Converting HOUSE to HOUSEMODEL
  func convertHouseEntitiesToStructs(entities: [House]) -> [HouseModel] {
    var structs: [HouseModel] = []
    
    for entity in entities {
      let myStruct = HouseModel(id: entity.id ?? "",
                                territory_address: entity.territoryAddress ?? "", number: entity.number ?? "",
                                floor: String(entity.floor),
                                created_at: "", updated_at: "")
      structs.append(myStruct)
    }
    
    return structs
  }
  
  //MARK: Converting VISIT to VISITMODEL
  func convertVisitEntitiesToStructs(entities: [Visit]) -> [VisitModel] {
    var structs: [VisitModel] = []
    
    for entity in entities {
        let myStruct = VisitModel(id: entity.id ?? "",
                                  house: entity.house ?? "", date: Int64(entity.date),
                                  symbol: entity.symbol ?? "", notes: entity.notes ?? "",
                                user: entity.user ?? "",
                                created_at: "", updated_at: "")
      structs.append(myStruct)
    }
    
    return structs
  }
}
