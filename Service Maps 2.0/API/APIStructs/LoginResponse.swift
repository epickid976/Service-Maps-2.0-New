//
//  LoginResponse.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation

public struct LoginResponse: Codable {
    var access_token: String
    var token_type: String
    var expires_at: String
}
