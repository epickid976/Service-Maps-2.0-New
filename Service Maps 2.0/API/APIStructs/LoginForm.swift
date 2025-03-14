//
//  Login.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation

// MARK: - Login Form

public struct LoginForm: Codable, Sendable {
    var email: String
    var password: String
}
