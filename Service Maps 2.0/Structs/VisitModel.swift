//
//  VisitModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation

struct VisitModel: Codable {
    var id: String
    var house: String
    var date: Int64
    var symbol: String
    var notes: String
    var user: String
    var created_at: String
    var updated_at: String
}
