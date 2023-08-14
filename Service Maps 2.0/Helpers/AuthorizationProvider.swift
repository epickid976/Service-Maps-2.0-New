//
//  AuthorizationProvider.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation
import SwiftUI

class AuthorizationProvider: ObservableObject {
    let defaults = UserDefaults.standard
    
    init() {
        self.authorizationToken = defaults.string(forKey: authorizationTokenKey)
        self.token = defaults.string(forKey: tokenKey)
        self.congregationId = Int64(defaults.integer(forKey: congregationIdKey))
        self.congregationPass = defaults.string(forKey: congregationPassKey)
    }
    
    //MARK: Keys
    private var authorizationTokenKey = "authorizationTokenKey"
    private var tokenKey = "tokenKey"
    private var congregationIdKey = "congregationIdKey"
    private var congregationPassKey = "congregationPassKey"
    
    //MARK: Published Variables
    @Published var authorizationToken: String? = nil {
        didSet {
            defaults.set(authorizationToken, forKey: authorizationTokenKey)
        }
    }
    @Published var token: String? = nil {
        didSet {
            defaults.set(token, forKey: tokenKey)
        }
    }
    @Published var congregationId: Int64? = nil {
        didSet {
            defaults.set(congregationId, forKey: congregationIdKey)
        }
    }
    @Published var congregationPass: String? = nil {
        didSet {
            defaults.set(congregationPass, forKey: congregationPassKey)
        }
    }
    
    @Published var isLoggedOut = false
    
    class var shared: AuthorizationProvider {
        struct Static {
            static let instance = AuthorizationProvider()
        }
        
        return Static.instance
    }
}

