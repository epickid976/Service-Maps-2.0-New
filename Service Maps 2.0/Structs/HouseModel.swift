//
//  Visit.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation

struct HouseModel: Codable {
    var id: String
    var territory_address: String
    var number: String
    var floor: String?
    var created_at: String
    var updated_at: String
}

func convertHouseToHouseModel(model: House) -> HouseModel {
    return HouseModel(id: model.id ?? "", territory_address: model.territoryAddress ?? "", number: model.number ?? "", created_at: "", updated_at: "")
}
