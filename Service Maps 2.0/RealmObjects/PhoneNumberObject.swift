//
//  PhoneNumberObject.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/30/24.
//

import Foundation
import RealmSwift

class PhoneNumberObject: Object, Identifiable {
    @Persisted var id: String
    @Persisted var congregation: String
    @Persisted var number: String
    @Persisted var territory: String
    @Persisted var house: String?
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    static func == (lhs: PhoneNumberObject, rhs: PhoneNumberModel) -> Bool {
        return lhs.id == rhs.id &&
               lhs.congregation == rhs.congregation &&
               lhs.number == rhs.number &&
               lhs.territory == rhs.territory && // Match description property name
               lhs.house == rhs.house
      }
    
    func createTerritoryObject(from model: PhoneNumberModel) -> PhoneNumberObject {
      let territoryObject = PhoneNumberObject()
      territoryObject.id = model.id
      territoryObject.congregation = model.congregation
      territoryObject.number = model.number
      territoryObject.territory = model.territory  // Match description property name
      territoryObject.house = model.house
      return territoryObject
    }

}
