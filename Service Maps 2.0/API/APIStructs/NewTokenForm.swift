//
//  NewTokenForm.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation

// MARK: - New Token Form
public struct NewTokenForm: Codable, Sendable {
    var name: String
    var moderator: Bool
    var territories: String
    var congregation: Int64
    var expire: Int64?
}
