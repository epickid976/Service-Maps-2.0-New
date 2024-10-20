////
////  PhoneNumber.swift
////  Service Maps 2.0
////
////  Created by Jose Blanco on 4/30/24.
////
//
//import Foundation
//
//struct PhoneTerritory: Codable, Equatable, Hashable, Identifiable{
//    var id: String
//    var congregation: String
//    var number: String
//    var territory: String
//    var house: String?
//    var created_at: String
//    var updated_at: String
//    
//    static func == (lhs: PhoneTerritory, rhs: PhoneTerritory) -> Bool {
//        return lhs.id == rhs.id &&
//        lhs.congregation == rhs.congregation &&
//        lhs.number == rhs.number &&
//        lhs.territory == rhs.territory &&
//        lhs.house == rhs.house
//    }
//    
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//        hasher.combine(congregation)
//        hasher.combine(number)
//        hasher.combine(territory)
//        hasher.combine(house)// Combine an empty string for optional floor
//      }
//    
//    
//}
