////
////  TokenTerritory.swift
////  Service Maps 2.0
////
////  Created by Jose Blanco on 7/31/23.
////
//
//import Foundation
//
//struct TokenTerritory: Codable, Equatable, Hashable, Identifiable {
//    var id: String
//    var token: String
//    var territory: String
//    var created_at: String
//    var updated_at: String
//    
//    static func == (lhs: TokenTerritory, rhs: TokenTerritory) -> Bool {
//        return lhs.token == rhs.token &&
//        lhs.territory == rhs.territory
//    }
//    
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(token)
//        hasher.combine(territory)
//      }
//    
//    
//}
//
//func convertTokenToMyTokenModel(model: TokenTerritoryObject) -> TokenTerritory {
//    return TokenTerritory(id: model.id.debugDescription, token: model.token, territory: model.territory, created_at: "", updated_at: "")
//}
