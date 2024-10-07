//
//  StructToModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/1/23.
//

import Foundation

class StructToModel {
    
    private var databaseManager = RealmManager.shared
    
    //MARK: Converting MYTOKENMODEL to MYTOKEN
    func convertTokenStructsToEntities(structs: [MyTokenModel]) -> [TokenObject] {
        var entities: [TokenObject] = []

        for myStruct in structs {
            let token = TokenObject()
            token.id = myStruct.id
            token.name = myStruct.name
            token.congregation = myStruct.congregation
            token.moderator = myStruct.moderator
            
            if let expiration = myStruct.expire {
                token.expire = expiration
            }
            
            
            
            token.owner = myStruct.owner
            token.user = myStruct.user
            // Set other properties as needed

            entities.append(token)
        }

        return entities
    }
    
    //MARK: Converting TOKENTERRITORIESMODEL to TOKENTERRITORIES
    func convertTokenTerritoriesStructsToEntities(structs: [TokenTerritoryModel]) -> [TokenTerritoryObject] {
        var tokenTerritories: [TokenTerritoryObject] = []

        for myStruct in structs {
            let tokenTerritory = TokenTerritoryObject()
            tokenTerritory.token = myStruct.token
            tokenTerritory.territory = myStruct.territory
            // Set other properties as needed

            tokenTerritories.append(tokenTerritory)
        }

        return tokenTerritories
    }
    
    func convertTerritoryAddressStructsToEntities(structs: [TerritoryAddressModel]) -> [TerritoryAddressObject] {
        var entities: [TerritoryAddressObject] = []

        for myStruct in structs {
            let entity = TerritoryAddressObject()
            entity.id = myStruct.id
            entity.territory = myStruct.territory
            entity.address = myStruct.address
            
            entity.floors = myStruct.floors ?? 0
            
            // Set other properties as needed

            entities.append(entity)
        }

        return entities
    }
    
    //MARK: Converting TERRITORYMODEL to TERRITORY
    func convertTerritoryStructsToEntities(structs: [TerritoryModel]) -> [TerritoryObject] {
        var entities: [TerritoryObject] = []

        for myStruct in structs {
            let entity = TerritoryObject()
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
    func convertHouseStructsToEntities(structs: [HouseModel]) -> [HouseObject] {
        var entities: [HouseObject] = []

        for myStruct in structs {
            let entity = HouseObject()
            entity.id = myStruct.id
            entity.number = myStruct.number
            entity.territory_address = myStruct.territory_address
            if let floor = myStruct.floor {
                entity.floor = floor
            }
            // Set other properties as needed

            entities.append(entity)
        }

        return entities
    }
    
    //MARK: Converting VISITMODEL to VISIT
    func convertVisitStructsToEntities(structs: [VisitModel]) -> [VisitObject] {
        var entities: [VisitObject] = []

        for myStruct in structs {
            let entity = VisitObject()
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
      func convertTokenStructToEntity(structure: MyTokenModel) -> TokenObject {
        let entity = TokenObject()
        entity.id = structure.id
        entity.name = structure.name
        entity.owner = structure.owner
        entity.congregation = structure.congregation
        entity.moderator = structure.moderator
        entity.expire = structure.expire ?? 0
        entity.user = structure.user
        return entity
      }
      
      //MARK: Converting TOKENTERRITORIESMODEL to TOKENTERRITORIES
      func convertTokenTerritoryStructToEntity(structure: TokenTerritoryModel) -> TokenTerritoryObject {
        let entity = TokenTerritoryObject()
        entity.token = structure.token
        entity.territory = structure.territory
        return entity
      }
      
      func convertTerritoryAddressStructToEntity(structure: TerritoryAddressModel) -> TerritoryAddressObject {
        let entity = TerritoryAddressObject()
        entity.id = structure.id
        entity.territory = structure.territory
        entity.address = structure.address
        entity.floors = structure.floors ?? 0
        return entity
      }
      
      //MARK: Converting TERRITORYMODEL to TERRITORY
      func convertTerritoryStructToEntity(structure: TerritoryModel) -> TerritoryObject {
        let entity = TerritoryObject()
        entity.id = structure.id
        entity.congregation = structure.congregation
        entity.number = structure.number
        entity.territoryDescription = structure.description
        entity.image = structure.image
        return entity
      }
      
      //MARK: Converting HOUSEMODEL to HOUSE
      func convertHouseStructToEntity(structure: HouseModel) -> HouseObject {
        let entity = HouseObject()
        entity.id = structure.id
        entity.territory_address = structure.territory_address
        entity.number = structure.number
        if let floorString = structure.floor {
          entity.floor = floorString
        }
        return entity
      }
      
      //MARK: Converting VISITMODEL to VISIT
      func convertVisitStructToEntity(structure: VisitModel) -> VisitObject {
          let entity = VisitObject()
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
  
  //MARK: Converting MYTOKEN to MYTOKENMODEL
  func convertTokenEntitiesToStructs(entities: [TokenObject]) -> [MyTokenModel] {
    var structs: [MyTokenModel] = []
    
    for entity in entities {
        let myStruct = MyTokenModel(id: entity.id,
                                    name: entity.name,
                                    owner: entity.owner, congregation: entity.congregation,
                                  moderator: entity.moderator ,
                                  expire: entity.expire ,
                                 user: entity.user,
                                created_at: "",
                                updated_at: "")
      structs.append(myStruct)
    }
    
    return structs
  }
  
  //MARK: Converting TOKENTERRITORIES to TOKENTERRITORIESMODEL
  func convertTokenTerritoryEntitiesToStructs(entities: [TokenTerritoryObject]) -> [TokenTerritoryModel] {
    var structs: [TokenTerritoryModel] = []
    
    for entity in entities {
        let myStruct = TokenTerritoryModel(id: entity.description, token: entity.token, territory: entity.territory, created_at: "", updated_at: "")
      structs.append(myStruct)
    }
    
    return structs
  }
  
  func convertTerritoryAddressEntitiesToStructs(entities: [TerritoryAddressObject]) -> [TerritoryAddressModel] {
    var structs: [TerritoryAddressModel] = []
    
    for entity in entities {
        let myStruct = TerritoryAddressModel(id: entity.id,
                                             territory: entity.territory,
                                             address: entity.address,
                                           floors: entity.floors,
                                            created_at: "", updated_at: "")
      structs.append(myStruct)
    }
    
    return structs
  }
  
  //MARK: Converting TERRITORY to TERRITORYMODEL
  func convertTerritoryEntitiesToStructs(entities: [TerritoryObject]) -> [TerritoryModel] {
    var structs: [TerritoryModel] = []
    
    for entity in entities {
        let myStruct = TerritoryModel(id: entity.id,
                                      congregation: entity.congregation,
                                    number: entity.number ,
                                      description: entity.territoryDescription ,
                                    image: entity.image,
                                    created_at: "", updated_at: "")
      structs.append(myStruct)
    }
    
    return structs
  }
  
  //MARK: Converting HOUSE to HOUSEMODEL
  func convertHouseEntitiesToStructs(entities: [HouseObject]) -> [HouseModel] {
    var structs: [HouseModel] = []
    
    for entity in entities {
        let myStruct = HouseModel(id: entity.id,
                                  territory_address: entity.territory_address, number: entity.number,
                                floor: entity.floor,
                                created_at: "", updated_at: "")
      structs.append(myStruct)
    }
    
    return structs
  }
  
  //MARK: Converting VISIT to VISITMODEL
  func convertVisitEntitiesToStructs(entities: [VisitObject]) -> [VisitModel] {
    var structs: [VisitModel] = []
    
    for entity in entities {
        let myStruct = VisitModel(id: entity.id,
                                  house: entity.house, date: Int64(entity.date),
                                  symbol: entity.symbol, notes: entity.notes,
                                  user: entity.user,
                                created_at: "", updated_at: "")
      structs.append(myStruct)
    }
    
    return structs
  }
    
    func convertVisitEntitiesToStructsBackup(entities: [VisitObject]) -> [VisitModel] {
      var structs: [VisitModel] = []
      
      for entity in entities {
          let myStruct = VisitModel(id: entity.id,
                                    house: entity.house, date: Int64(entity.date),
                                    symbol: entity.symbol == "uk" ? "-" : entity.symbol.uppercased() , notes: entity.notes,
                                    user: entity.user,
                                  created_at: "", updated_at: "")
        structs.append(myStruct)
      }
      
      return structs
    }
}


