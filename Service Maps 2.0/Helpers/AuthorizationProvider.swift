//
//  AuthorizationProvider.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation
import SwiftUI

@MainActor
class AuthorizationProvider: ObservableObject {
    static let shared = AuthorizationProvider()
    
    let defaults = UserDefaults.standard
    
    private init() {
        self.authorizationToken = defaults.string(forKey: authorizationTokenKey)
        self.token = defaults.string(forKey: tokenKey)
        self.congregationId = Int64(defaults.integer(forKey: congregationIdKey))
        self.congregationPass = defaults.string(forKey: congregationPassKey)
        self.phoneCongregationId = defaults.string(forKey: phoneCongregationIdKey)
        self.phoneCongregationPass = defaults.string(forKey: phoneCongregationPassKey)
    }
    
    //MARK: Keys
    private var authorizationTokenKey = "authorizationTokenKey"
    private var tokenKey = "tokenKey"
    private var congregationIdKey = "congregationIdKey"
    private var congregationPassKey = "congregationPassKey"
    
    private var phoneCongregationIdKey = "phoneCongregationIdKey"
    private var phoneCongregationPassKey = "phoneCongregationPassKey"
    
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
    
    @Published var phoneCongregationId: String? = nil {
        didSet {
            defaults.set(phoneCongregationId, forKey: phoneCongregationIdKey)
        }
    }
    
    @Published var phoneCongregationPass: String? = nil {
        didSet {
            defaults.set(phoneCongregationPass, forKey: phoneCongregationPassKey)
        }
    }
    
    @Published var isLoggedOut = false
    
    func clear() {
        authorizationToken = nil
        token = nil
        congregationId = nil
        congregationPass = nil
        phoneCongregationId = nil
        phoneCongregationPass = nil
    }
}

