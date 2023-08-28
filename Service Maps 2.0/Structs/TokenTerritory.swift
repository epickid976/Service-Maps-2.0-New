//
//  TokenTerritory.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation

struct TokenTerritoryModel: Codable {
    var id: Int64
    var token: String
    var territory: String
    var created_at: String
    var updated_at: String
}
