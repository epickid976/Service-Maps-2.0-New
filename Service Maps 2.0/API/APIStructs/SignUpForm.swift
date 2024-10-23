//
//  SignUpForm.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation

public struct SignUpForm: Codable {
    var name: String
    var email: String
    var password: String
    var password_confirmation: String
}
