//
//  AuthorizationLevelManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/27/23.
//

import Foundation
import Alamofire
import GRDB
import SwiftUI

//MARK: - Authorization Level Manager

@MainActor
class AuthorizationLevelManager: ObservableObject {
    
    //MARK: - Dependencies
    
    private var grdbManager = GRDBManager.shared
    @ObservedObject private var authorizationProvider = AuthorizationProvider.shared
    @ObservedObject private var dataStore = StorageManager.shared
    
    //MARK: - Check Login
    // Check if the user is logged in
    func userHasLogged() -> Bool {
        return authorizationProvider.authorizationToken != nil
    }
    
    // Check if the user needs to log in
    @BackgroundActor
    func userNeedLogin() async -> Bool {
        if await !userHasLogged() {
            return true
        }
        
        do {
            _ = try await AuthenticationService().user().get()
        } catch {
            if let error = error.asAFError, error.responseCode == 401 {
                await MainActor.run { authorizationProvider.authorizationToken = nil }
                return true
            }
        }
        return false
    }
    
    // Check if the admin needs to log in
    @BackgroundActor
    func adminNeedLogin() async -> Bool {
        if await existsAdminCredentials() {
            do {
                _ = try await CongregationService().signIn(congregationSignInForm: CongregationSignInForm(id: authorizationProvider.congregationId!, password: authorizationProvider.congregationPass!)).get()
            } catch {
                if let error = error.asAFError {
                    if error.responseCode == 401 {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    // Check if phone login is required
    @BackgroundActor
    func phoneNeedLogin() async -> Bool {
        if await existsPhoneCredentials() {
            do {
                _ = try await CongregationService().phoneSignIn(congregationSignInForm: CongregationSignInForm(
                    id: Int64(authorizationProvider.phoneCongregationId!)!,
                    password: authorizationProvider.phoneCongregationPass!)
                ).get()
            } catch {
                if let error = error.asAFError, error.responseCode == 401 {
                    return true
                }
            }
        }
        return false
    }
    
    //MARK: - Set Credentials
    // Set user credentials from login response
    @MainActor
    func setUserCredential(logInResponse: LoginResponse) {
        authorizationProvider.authorizationToken = logInResponse.access_token
    }
    
    // Set admin credentials
    @MainActor
    func setAdminCredentials(password: String, congregationResponse: CongregationResponse) {
        authorizationProvider.congregationId = Int64(congregationResponse.id)
        authorizationProvider.congregationPass = password
    }
    
    // Set phone credentials
    func setPhoneCredentials(password: String, congregationResponse: CongregationResponse) {
        DispatchQueue.main.async {
            self.authorizationProvider.phoneCongregationId = congregationResponse.id
            self.authorizationProvider.phoneCongregationPass = password
        }
    }
    
    //MARK: - Check Access
    // Check if admin credentials exist
    @MainActor
    func existsAdminCredentials() -> Bool {
        return authorizationProvider.congregationId != nil && authorizationProvider.congregationPass != nil
    }
    
    // Check if the user has moderator access using GRDB
    @MainActor
    func existsModeratorAccess() -> Bool {
        do {
            return try grdbManager.dbPool.read { db in
                try Token.filter(Column("user") == dataStore.userEmail).fetchCount(db) > 0
            }
        } catch {
            print("Error checking moderator access: \(error)")
            return false
        }
    }
    
    // Check if phone credentials exist
    @MainActor
    func existsPhoneCredentials() -> Bool {
        return authorizationProvider.phoneCongregationId != nil && authorizationProvider.phoneCongregationPass != nil
    }
    
    //MARK: - Get Access Level
    // Get access level for a model using GRDB
    func getAccessLevel<T>(model: T) -> AccessLevel? where T: FetchableRecord & MutablePersistableRecord {
        if existsAdminCredentials() {
            return .Admin
        }
        
        if let token = findToken(model: model) {
            return dataStore.userEmail == token.user ? .Moderator : .User
        }
        
        return nil
    }
    
    // Set authorization token for a specific model
    func setAuthorizationTokenFor<T>(model: T) async where T: FetchableRecord & MutablePersistableRecord {
        if let token = findToken(model: model) {
            authorizationProvider.token = token.id
        }
    }
    
    // Find a token for the given model
    func findToken<T>(model: T) -> Token? where T: FetchableRecord & MutablePersistableRecord {
        do {
            return try grdbManager.dbPool.read { db in
                switch model {
                case let territory as Territory:
                    return try self.findTokenForTerritory(territory.id, in: db)
                case let territoryAddress as TerritoryAddress:
                    return try self.findTokenForTerritory(territoryAddress.territory, in: db)
                case let house as House:
                    if let territoryAddress = try TerritoryAddress.filter(Column("id") == house.territory_address).fetchOne(db) {
                        return try self.findTokenForTerritory(territoryAddress.territory, in: db)
                    }
                case let visit as Visit:
                    if let house = try House.filter(Column("id") == visit.house).fetchOne(db),
                       let territoryAddress = try TerritoryAddress.filter(Column("id") == house.territory_address).fetchOne(db) {
                        return try self.findTokenForTerritory(territoryAddress.territory, in: db)
                    }
                default:
                    return nil
                }
                return nil
            }
        } catch {
            print("Error fetching token: \(error)")
            return nil
        }
    }
    
    // Find token for a territory using GRDB
    private func findTokenForTerritory(_ territoryId: String, in db: Database) throws -> Token? {
        let tokenTerritories = try TokenTerritory.filter(Column("territory") == territoryId).fetchAll(db)
        let tokenIds = tokenTerritories.map { $0.token }
        
        // First, try to find a moderator token
        if let moderatorToken = try Token.filter(tokenIds.contains(Column("id")) && Column("moderator") == true).fetchOne(db) {
            return moderatorToken
        }
        
        // If no moderator token, find the earliest non-expired token
        let currentTimestamp = Int64(Date().timeIntervalSince1970 * 1000)
        return try Token.filter(tokenIds.contains(Column("id")) && (Column("expire") >= currentTimestamp || Column("expire") == nil))
            .order(Column("expire").asc)
            .fetchOne(db)
    }
    
    // Find token for a territory address
    func findToken(territoryAddress: TerritoryAddress) -> Token? {
        do {
            return try grdbManager.dbPool.read { db in
                if let territory = try Territory.filter(Column("id") == territoryAddress.territory).fetchOne(db) {
                    return findToken(model: territory)
                }
                return nil
            }
        } catch {
            print("Error fetching token for territory address: \(error)")
            return nil
        }
    }
    
    // Find token for a house
    func findToken(house: House) -> Token? {
        do {
            return try grdbManager.dbPool.read { db in
                if let territoryAddress = try TerritoryAddress.filter(Column("id") == house.territory_address).fetchOne(db) {
                    return findToken(territoryAddress: territoryAddress)
                }
                return nil
            }
        } catch {
            print("Error fetching token for house: \(error)")
            return nil
        }
    }
    
    // Find token for a visit
    func findToken(visit: Visit) -> Token? {
        do {
            return try grdbManager.dbPool.read { db in
                if let house = try House.filter(Column("id") == visit.house).fetchOne(db) {
                    return findToken(house: house)
                }
                return nil
            }
        } catch {
            print("Error fetching token for visit: \(error)")
            return nil
        }
    }
    
    //MARK: - Exit
    // Exit admin credentials
    @MainActor
    func exitAdministrator() {
        authorizationProvider.congregationId = nil
        authorizationProvider.congregationPass = nil
        dataStore.congregationName = nil
    }
    
    // Exit phone login
    @MainActor
    func exitPhoneLogin() {
        authorizationProvider.phoneCongregationId = nil
        authorizationProvider.phoneCongregationPass = nil
    }
}
