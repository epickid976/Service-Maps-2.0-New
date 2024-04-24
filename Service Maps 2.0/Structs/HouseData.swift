//
//  HouseData.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/21/24.
//

import Foundation

struct HouseData: Hashable, Identifiable {
    var id: UUID
    var house: HouseModel
    var visit: VisitModel?
    var accessLevel: AccessLevel
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(house)
        hasher.combine(visit)
        hasher.combine(accessLevel)
    }
    
    static func ==(lhs: HouseData, rhs: HouseData) -> Bool {
        return lhs.house == rhs.house &&
        lhs.visit == rhs.visit &&
        lhs.accessLevel == rhs.accessLevel
    }
}
