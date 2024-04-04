//
//  UserResponse.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation

struct UserResponse: Codable {
    var id: Int
    var name: String
    var email: String
    var email_verified_at: String
    var active: Int
    var created_at: String
    var updated_at: String
    var deleted_at: String?
}
