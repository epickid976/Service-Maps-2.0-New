//
//  HouseClass.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/15/24.
//

import Foundation
import RealmSwift

class HouseObject: Object, Identifiable {
    @Persisted var id: String
    @Persisted var territory_address: String
    @Persisted var number: String
    @Persisted var floor: String?
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    static func == (lhs: HouseObject, rhs: HouseModel) -> Bool {
        return lhs.id == rhs.id &&
               lhs.territory_address == rhs.territory_address &&
               lhs.number == rhs.number &&
               lhs.floor == rhs.floor
      }
    
    func createHouseObject(from model: HouseModel) -> HouseObject {
      let houseObject = HouseObject()
      houseObject.id = model.id
      houseObject.territory_address = model.territory_address
      houseObject.number = model.number
      houseObject.floor = model.floor
      return houseObject
    }

}
