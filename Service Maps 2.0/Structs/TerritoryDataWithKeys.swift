//
//  TerritoryDataWithKeys.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/18/24.
//

import Foundation


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
