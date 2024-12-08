//
//  CongregationSignInForm.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation

// MARK: - Congregation Sign In Form
public struct CongregationSignInForm: Codable, Sendable {
    var id: Int64
    var password: String
}
