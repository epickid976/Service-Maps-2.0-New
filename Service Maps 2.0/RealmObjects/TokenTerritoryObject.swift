////
////  TokenTerritoryObject.swift
////  Service Maps 2.0
////
////  Created by Jose Blanco on 4/15/24.
////
//
//import Foundation
//Swift
//
//class TokenTerritoryObject: Object, Identifiable {
//    @Persisted var token: String
//    @Persisted var territory: String
//    @Persisted var _id: ObjectId = ObjectId.generate()
//    
//    static func == (lhs: TokenTerritoryObject, rhs: TokenTerritory) -> Bool {
//       return lhs.token == rhs.token &&
//              lhs.territory == rhs.territory
//     }
//    
//    override static func primaryKey() -> String? {
//            return "_id"
//        }
//    
//    func createTokenTerritoryObject(from model: TokenTerritory) -> TokenTerritoryObject {
//      let tokenTerritoryObject = TokenTerritoryObject()
//        tokenTerritoryObject.territory = model.territory
//        tokenTerritoryObject.token = model.token
//      return tokenTerritoryObject
//    }
//}
