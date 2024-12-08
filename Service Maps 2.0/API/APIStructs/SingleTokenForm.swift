//
//  SingleTokenResponse.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 6/5/24.
//

import Foundation

// MARK: - Single Token Response
public struct SingleTokenForm: Codable, Sendable {
    var token: String
}
