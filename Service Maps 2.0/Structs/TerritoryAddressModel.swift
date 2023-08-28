//
//  TerritoryAddressModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/27/23.
//

import Foundation

struct TerritoryAddressModel: Codable {
    var id: String
    var territory: String
    var address: String
    var floors: Int?
    var created_at: String
    var updated_at: String
}
