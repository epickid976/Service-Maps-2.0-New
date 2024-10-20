////
////  Visit.swift
////  Service Maps 2.0
////
////  Created by Jose Blanco on 7/31/23.
////
//
//import Foundation
//
//struct House: Codable, Equatable, Hashable, Identifiable {
//    var id: String
//    var territory_address: String
//    var number: String
//    var floor: String?
//    var created_at: String
//    var updated_at: String
//    
//    static func == (lhs: House, rhs: House) -> Bool {
//        return lhs.id == rhs.id &&
//        lhs.territory_address == rhs.territory_address &&
//        lhs.number == rhs.number &&
//        lhs.floor == rhs.floor
//    }
//    
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//        hasher.combine(territory_address)
//        hasher.combine(number)
//        hasher.combine(floor ?? "") // Combine an empty string for optional floor
//      }
//}
//
//func convertHouseToHouseModel(model: House) -> House {
//    return House(id: model.id, territory_address: model.territory_address, number: model.number, floor: model.floor, created_at: "", updated_at: "")
//}
