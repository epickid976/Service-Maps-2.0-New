//
//  MainStructs.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 10/17/24.
//

import GRDB
import Foundation

struct Territory: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable, Identifiable {
    var id: String
    var congregation: String
    var number: Int32
    var description: String
    var image: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(congregation)
        hasher.combine(number)
        hasher.combine(description)
        hasher.combine(image)
    }
    
    func getImageURL() -> String {
        let baseURL = "https://servicemaps.ejvapps.online/api/"
        if image != nil {
            return baseURL + "territories/" + congregation + "/" + image!
        } else {
            return ""
        }
    }
    
    // Define primary key
    static var databaseTableName: String {
        return "territories"
    }
    
    static var primaryKey: String {
        return "id"
    }
}

struct TerritoryAddress: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable, Identifiable {
    var id: String
    var territory: String
    var address: String
    var floors: Int?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(territory)
        hasher.combine(address)
        hasher.combine(floors ?? 0) // Combine 0 for nil floors value
    }
    
    // Define primary key
    static var databaseTableName: String {
        return "territory_addresses"
    }
    
    static var primaryKey: String {
        return "id"
    }
}

struct House: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable, Identifiable {
    var id: String
    var territory_address: String
    var number: String
    var floor: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(territory_address)
        hasher.combine(number)
        hasher.combine(floor ?? "") // Combine an empty string for optional floor
    }
    
    // Define primary key
    static var databaseTableName: String {
        return "houses"
    }
    
    static var primaryKey: String {
        return "id"
    }
}

struct Visit: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable, Identifiable {
    var id: String
    var house: String
    var date: Int64
    var symbol: String
    var notes: String
    var user: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(house)
        hasher.combine(date)
        hasher.combine(symbol)
        hasher.combine(notes)
        hasher.combine(user)
    }
    
    // Define primary key
    static var databaseTableName: String {
        return "visits"
    }
    
    static var primaryKey: String {
        return "id"
    }
}

struct Token: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable, Identifiable {
    var id: String
    var name: String
    var owner: String
    var congregation: String
    var moderator: Bool
    var expire: Int64?
    var user: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(owner)
        hasher.combine(congregation)
        hasher.combine(moderator)
        hasher.combine(expire ?? 0) // Combine 0 for nil expire value
    }
    
    // Define primary key
    static var databaseTableName: String {
        return "tokens"
    }
    
    static var primaryKey: String {
        return "id"
    }
}

struct TokenTerritory: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable, Identifiable {
    
    var token: String
    var territory: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(token)
        hasher.combine(territory)
    }
    
    // This `id` will not be decoded from JSON
    var id: String {
        return "\(token)_\(territory)"
    }
    
    // Define custom CodingKeys to omit the id
    enum CodingKeys: String, CodingKey {
        case token
        case territory
    }
    
    // Define primary key
    static var databaseTableName: String {
        return "token_territories"
    }
    
    static var primaryKey: [String] {
        return ["token", "territory"]
    }
}
