//
//  TerritoryData.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/6/23.
//

import Foundation

//MARK: - Territory Data With Keys
struct TerritoryDataWithKeys: Hashable, Identifiable, Sendable {
    var id: UUID
    var keys: [Token]
    var territoriesData: [TerritoryData]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(keys)
        hasher.combine(territoriesData)
    }
    
    static func ==(lhs: TerritoryDataWithKeys, rhs: TerritoryDataWithKeys) -> Bool {
        return lhs.keys == rhs.keys &&
        lhs.territoriesData == rhs.territoriesData
    }
}

//MARK: - Territory Data
struct TerritoryData: Hashable, Equatable, Identifiable, Sendable {
    var id: String { territory.id } // Use territory.id as the unique identifier
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
