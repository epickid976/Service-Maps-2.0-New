//
//  MainStructs.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 10/17/24.
//

import GRDB
import Foundation

//MARK: - Main Structs



//MARK: - Territory
public struct Territory: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    var congregation: String
    var number: Int32
    var description: String
    var image: String?
    
    public func hash(into hasher: inout Hasher) {
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
    public static var databaseTableName: String {
        return "territories"
    }
    
    static var primaryKey: String {
        return "id"
    }
}

//MARK: - Address
public struct TerritoryAddress: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    var territory: String
    var address: String
    var floors: Int?
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(territory)
        hasher.combine(address)
        hasher.combine(floors ?? 0) // Combine 0 for nil floors value
    }
    
    // Define primary key
    public static var databaseTableName: String {
        return "territory_addresses"
    }
    
    static var primaryKey: String {
        return "id"
    }
}

//MARK: - House
public struct House: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    var territory_address: String
    var number: String
    var floor: String?
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(territory_address)
        hasher.combine(number)
        hasher.combine(floor ?? "") // Combine an empty string for optional floor
    }
    
    // Define primary key
    public static var databaseTableName: String {
        return "houses"
    }
    
    static var primaryKey: String {
        return "id"
    }
}

//MARK: - Visit
public struct Visit: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    var house: String
    var date: Int64
    var symbol: String
    var notes: String
    var user: String
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(house)
        hasher.combine(date)
        hasher.combine(symbol)
        hasher.combine(notes)
        hasher.combine(user)
    }
    
    // Define primary key
    public static var databaseTableName: String {
        return "visits"
    }
    
    static var primaryKey: String {
        return "id"
    }
}

//MARK: - Token

public struct Token: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    var name: String
    var owner: String
    var congregation: String
    var moderator: Bool
    var expire: Int64?
    var user: String?
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(owner)
        hasher.combine(congregation)
        hasher.combine(moderator)
        hasher.combine(expire ?? 0) // Combine 0 for nil expire value
    }
    
    // Define primary key
    public static var databaseTableName: String {
        return "tokens"
    }
    
    static var primaryKey: String {
        return "id"
    }
}

//MARK: - Server Token Struct
// For the specific problematic endpoint
public struct CreateTokenResponse: Decodable, Sendable {
    let token: Token
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Use the custom decoding logic here
        let id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        let name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        let owner = try container.decodeIfPresent(String.self, forKey: .owner) ?? ""
        
        // Handle congregation
        let congregation: String
        if let congregationInt = try container.decodeIfPresent(Int64.self, forKey: .congregation) {
            congregation = String(congregationInt)
        } else if let congregationStr = try container.decodeIfPresent(String.self, forKey: .congregation) {
            congregation = congregationStr
        } else {
            congregation = ""
        }
        
        let moderator = try container.decodeIfPresent(Bool.self, forKey: .moderator) ?? false
        let expire = try container.decodeIfPresent(Int64.self, forKey: .expire)
        let user = try container.decodeIfPresent(String.self, forKey: .user)
        
        // Create the Token using the normal initializer
        self.token = Token(id: id,
                          name: name,
                          owner: owner,
                          congregation: congregation,
                          moderator: moderator,
                          expire: expire,
                          user: user)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, owner, congregation, moderator, expire, user
    }
}

//MARK: - TokenTerritory
public struct TokenTerritory: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable, Sendable {
    
    var token: String
    var territory: String
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(token)
        hasher.combine(territory)
    }
    
    // Define custom CodingKeys to ensure `id` is not used during encoding/decoding
    enum CodingKeys: String, CodingKey {
        case token
        case territory
    }
    
    // Define primary key as an array of both `token` and `territory`
    public static var databaseTableName: String {
        return "token_territories"
    }
    
    // Using an array to specify composite primary keys
    static var primaryKey: [String] {
        return ["token", "territory"]
    }
    
    // Equatable comparison
    public static func == (lhs: TokenTerritory, rhs: TokenTerritory) -> Bool {
        return lhs.token == rhs.token && lhs.territory == rhs.territory
    }
}

//MARK: - Other Models
struct UserAction {
    var userToken: UserToken
    var isBlocked: Bool
}
