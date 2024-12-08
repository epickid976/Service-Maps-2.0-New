//
//  CongregationWithAll.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 12/3/24.
//

import Foundation

// MARK: - New Data Forms
public struct CongregationWithAll: Codable, Sendable {
    var id: String
    var name: String
    var password: String
    var created_at: String
    var updated_at: String
    var phone: String
    var congregation_number: Int
    var country: String
    var territories: [TerritoryWithAll]
}

public struct TerritoryWithAll: Codable, Sendable {
    var id: String
    var congregation: String
    var number: Int
    var description: String
    var image: String?
    var created_at: String
    var updated_at: String
    var addresses: [AddressWithAll]
}

public struct AddressWithAll: Codable, Sendable {
    var id: String
    var territory: String
    var address: String
    var floors: Int?
    var created_at: String
    var updated_at: String
    var houses: [HouseWithVisits]
}

public struct HouseWithVisits: Codable, Sendable {
    var id: String
    var territory_address: String
    var number: String
    var floor: Int?
    var created_at: String
    var updated_at: String
    var visits: [VisitResponse]
}

public struct VisitResponse: Codable, Sendable {
    var id: String
    var house: String
    var date: Int64
    var symbol: String
    var notes: String
    var user: String
    var created_at: String
    var updated_at: String
}
