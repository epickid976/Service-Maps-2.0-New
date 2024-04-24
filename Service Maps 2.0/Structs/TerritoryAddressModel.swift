//
//  TerritoryAddressModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/27/23.
//

import Foundation

struct TerritoryAddressModel: Codable, Equatable, Hashable, Identifiable{
    var id: String
    var territory: String
    var address: String
    var floors: Int?
    var created_at: String
    var updated_at: String
    
    static func == (lhs: TerritoryAddressModel, rhs: TerritoryAddressModel) -> Bool {
        return lhs.id == rhs.id &&
        lhs.territory == rhs.territory &&
        lhs.address == rhs.address &&
        lhs.floors == rhs.floors
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(territory)
        hasher.combine(address)
        hasher.combine(floors ?? 0) // Combine 0 for nil floors value
      }
    
    
}

func convertTerritoryToTerritoryAddressModel(model: TerritoryAddressObject) -> TerritoryAddressModel {
    return TerritoryAddressModel(id: model.id, territory: model.territory, address: model.address, created_at: "", updated_at: "")
}
