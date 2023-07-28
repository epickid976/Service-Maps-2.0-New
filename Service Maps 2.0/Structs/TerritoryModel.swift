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
    var address: String
    var image: String?
    var floors: Int?
    var section: String
}
