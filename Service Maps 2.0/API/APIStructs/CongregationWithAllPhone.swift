//
//  Untitled.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 12/3/24.
//

import Foundation

public struct CongregationWithAllPhone: Codable, Sendable {
    var id: String
    var name: String
    var password: String
    var created_at: String
    var updated_at: String
    var phone: String
    var congregation_number: Int64
    var country: String
    var phone_territories: [TerritoryWithAllPhone]
}

public struct TerritoryWithAllPhone: Codable, Sendable {
    var id: String
    var congregation: String
    var number: Int
    var image: String?
    var description: String
    var created_at: String
    var updated_at: String
    var numbers: [NumberWithCalls]
}

public struct NumberWithCalls: Codable, Sendable {
    var id: String
    var territory: String
    var congregation: String
    var number: String
    var house: String?
    var created_at: String
    var updated_at: String
    var calls: [CallResponse]
}

public struct CallResponse: Codable, Sendable {
    var id: String
    var phonenumber: String
    var date: Int64
    var notes: String
    var user: String
    var created_at: String
    var updated_at: String
}
