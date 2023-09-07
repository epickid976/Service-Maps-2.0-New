//
//  TerritoryModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation

struct TerritoryModel: Codable {
    var id: String
    var congregation: String
    var number: Int64
    var description: String
    var image: String?
    var created_at: String
    var updated_at: String
}


func convertTerritoryToTerritoryModel(model: Territory) -> TerritoryModel {
    return TerritoryModel(id: model.id ?? "", congregation: model.congregation ?? "", number: Int64(model.number), description: model.description, created_at: "", updated_at: "")
}
