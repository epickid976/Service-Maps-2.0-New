//
//  PhoneStructs.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 10/17/24.
//

import GRDB
import ModifiedCopy

//MARK: - Phone Structs


//MARK: - Territory
public struct PhoneTerritory: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    var congregation: String
    var number: Int64
    var description: String
    var image: String?
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(congregation)
        hasher.combine(description)
        hasher.combine(number)
        hasher.combine(image) // Combine an empty string for optional floor
    }
    
    func getImageURL() -> String {
        let baseURL = "https://servicemaps.ejvapps.online/api/"
        if image != nil {
            return baseURL + "phone/territories/" + String(congregation) + "/" + image!
        } else {
            return ""
        }
    }
    
    // Define primary key
    public static var databaseTableName: String {
        return "phone_territories"
    }
    
    static var primaryKey: String {
            return "id"
        }
}

//MARK: - Number

public struct PhoneNumber: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    var congregation: String
    var number: String
    var territory: String
    var house: String?
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(congregation)
        hasher.combine(number)
        hasher.combine(territory)
        hasher.combine(house)// Combine an empty string for optional floor
    }
    
    // Define primary key
    public static var databaseTableName: String {
        return "phone_numbers"
    }
    
    static var primaryKey: String {
            return "id"
        }
}

//MARK: - Call

@Copyable
public struct PhoneCall: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    var phonenumber: String
    var date: Int64
    var notes: String
    var user: String
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(phonenumber)
        hasher.combine(date)
        hasher.combine(notes)
        hasher.combine(user)// Combine an empty string for optional floor
    }
    
    // Define primary key
    public static var databaseTableName: String {
        return "phone_calls"
    }
    
    static var primaryKey: String {
            return "id"
        }
}

//MARK: - User Token

public struct UserToken: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable, Identifiable, Sendable {
    
    // This `id` will not be decoded from JSON
    public var id: String {
        return "\(token)-\(userId)"
    }
    
    var token: String
    var userId: String
    var name: String
    var blocked: Bool
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(token)
        hasher.combine(userId)
        hasher.combine(name)
        hasher.combine(blocked)
    }
    
    // Define primary key
    public static var databaseTableName: String {
        return "user_tokens"
    }
    
    static var primaryKey: [String] {
            return ["token", "userId"]
        }
}

//MARK: - Recalls

public struct Recalls: Codable, FetchableRecord, MutablePersistableRecord, Equatable, Hashable, Identifiable, Sendable {
    
    public var id: Int64
    var user: String
    var house: String
    
    func getId() -> String {
        return "\(user)-\(house)"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(user)
        hasher.combine(house)
    }
    
    static var primaryKey: String {
            return "id"
        }
    
    public static var databaseTableName: String {
        return "recalls"
    }
}
