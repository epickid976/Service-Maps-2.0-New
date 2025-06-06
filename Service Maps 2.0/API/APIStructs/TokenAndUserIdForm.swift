//
//  TokenAndUserIdForm.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 6/5/24.
//

import Foundation

// MARK: - Token and User ID Form
public struct TokenAndUserIdForm: Codable, Sendable {
    var token: String
    var userid: String
    var blocked: Bool = false
}
