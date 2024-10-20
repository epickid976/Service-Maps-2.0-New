////
////  TerritoryAddress.swift
////  Service Maps 2.0
////
////  Created by Jose Blanco on 4/15/24.
////
//
//import Foundation
//Swift
//
//class TerritoryAddress: Object, Identifiable {
//    @Persisted var id: String
//    @Persisted var territory: String
//    @Persisted var address: String
//    @Persisted var floors: Int?
//    
//    override static func primaryKey() -> String? {
//        return "id"
//    }
//    
//    static func == (lhs: TerritoryAddress, rhs: TerritoryAddress) -> Bool {
//       return lhs.id == rhs.id &&
//              lhs.territory == rhs.territory &&
//              lhs.address == rhs.address &&
//              lhs.floors == rhs.floors
//     }
//    
//    func createTerritoryAddressObject(from model: TerritoryAddress) -> TerritoryAddress {
//      let territoryAddressObject = TerritoryAddress()
//      territoryAddressObject.id = model.id
//      territoryAddressObject.territory = model.territory
//      territoryAddressObject.address = model.address
//      territoryAddressObject.floors = model.floors
//      return territoryAddressObject
//    }
//
//}
