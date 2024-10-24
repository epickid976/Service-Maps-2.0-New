//
//  TerritoryData.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/6/23.
//

import Foundation

struct TerritoryData: Hashable, Equatable {
    var territory: Territory
    var addresses: [TerritoryAddress]
    var housesQuantity: Int
    var accessLevel: AccessLevel
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(territory)
        hasher.combine(addresses)
        hasher.combine(housesQuantity)
        hasher.combine(accessLevel)
    }
    
    static func ==(lhs: TerritoryData, rhs: TerritoryData) -> Bool {
        return lhs.territory == rhs.territory &&
        lhs.addresses == rhs.addresses &&
        lhs.housesQuantity == rhs.housesQuantity &&
        lhs.accessLevel == rhs.accessLevel
    }
}
