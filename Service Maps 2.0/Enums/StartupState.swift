//
//  StartupState.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/8/23.
//

import Foundation

// MARK: - Startup State
enum StartupState {
    case Unknown, Welcome, Login, AdminLogin, PhoneLogin, Validate, Loading, Empty, Ready
}
