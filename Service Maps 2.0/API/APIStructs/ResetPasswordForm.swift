//
//  ResetPasswordForm.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation

// MARK: - Reset Password Form
public struct ResetPasswordForm: Codable , Sendable{
    var password: String
    var password_confirmation: String
    var token: String
}
