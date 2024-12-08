//
//  UserResponse.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation

// MARK: - User Response

public struct UserResponse: Codable, Sendable {
    var id: Int
    var name: String
    var email: String
}

// MARK: - TokensWithAll
public struct MyTokenWithAll: Codable, Sendable {
    var id: String
    var name: String
    var owner: String
    var user: String?
    var congregation: String
    var expire: Int64?
    var moderator: Bool
    var created_at: String
    var updated_at: String
    var user_token: SimpleUserTokenResponse?
    var token_users: [UserTokenResponse]
    var token_territories: [TokenTerritory]
}

// MARK: - UserTokenResponse

public struct UserTokenResponse: Codable, Sendable {
    var id: String
    var user: String
    var token: String
    var created_at: String
    var updated_at: String
    var blocked: Bool

    enum CodingKeys: String, CodingKey {
        case id, user, token, created_at, updated_at, blocked
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode `id` as either a String or a Number
        if let idAsString = try? container.decode(String.self, forKey: .id) {
            id = idAsString
        } else if let idAsNumber = try? container.decode(Int.self, forKey: .id) {
            id = String(idAsNumber)
        } else {
            throw DecodingError.typeMismatch(
                String.self,
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Expected `id` to be a String or a Number"
                )
            )
        }

        // Decode other fields normally
        user = try container.decode(String.self, forKey: .user)
        token = try container.decode(String.self, forKey: .token)
        created_at = try container.decode(String.self, forKey: .created_at)
        updated_at = try container.decode(String.self, forKey: .updated_at)
        blocked = try container.decode(Bool.self, forKey: .blocked)
    }
}

// MARK: - SimpleUserTokenResponse
public struct SimpleUserTokenResponse: Codable, Sendable {
    var user: String
    var token: String
}

