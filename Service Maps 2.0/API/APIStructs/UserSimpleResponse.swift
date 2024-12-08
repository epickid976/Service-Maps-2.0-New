//
//  UserSimpleResponse.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 6/5/24.
//

import Foundation

// MARK: - User Simple Response
public struct UserSimpleResponse: Codable, Sendable {
    var id: Int
    var name: String
    var blocked: Bool
}
