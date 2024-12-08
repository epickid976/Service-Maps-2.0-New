//
//  EditTokenForm.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 6/12/24.
//

import Foundation

// MARK: - Edit Token Form
public struct EditTokenForm: Codable, Sendable{
    var token: String
    var territories: String
}
