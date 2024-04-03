//
//  AuthorizationLevelManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/27/23.
//

import Foundation

class AuthorizationLevelManager: ObservableObject {
    @Published private var dataController = DataController.shared
    
    
    
    @Published private var authorizationProvider = AuthorizationProvider.shared
    private var dataStore = StorageManager.shared
    
    func userHasLogged() -> Bool {
        return authorizationProvider.authorizationToken != nil
    }
    
    func userNeedLogin() async -> Bool {
        
        if !userHasLogged() {
            return true
        }
        
        do {
            _ = try await AuthenticationAPI().user()
        } catch {
            if let error = error.asAFError {
                if error.responseCode == 401 {
                    authorizationProvider.authorizationToken = nil
                    return true
                }
            }
        }
        return false
    }
    
    func getAccessLevel<T>(model: T) async -> AccessLevel? {
        if let token = await findToken(model: model) {
            if token.moderator {
                return .Moderator
            } else {
                return .User
            }
        } else if existsAdminCredentials() {
            return .Admin
        } else {
            return nil
        }
    }
    
    func setAuthorizationTokenFor<T>(model: T) async {
        if let token = await findToken(model: model) {
            authorizationProvider.token = token.id
        }
    }
    
    func setUserCredential(logInResponse: LoginResponse) {
        authorizationProvider.authorizationToken = logInResponse.access_token
    }
    
    func setAdminCredentials(password: String, congregationResponse: CongregationResponse) {
        authorizationProvider.congregationId = Int64(congregationResponse.id)
        authorizationProvider.congregationPass = password
    }
    
    func findToken<T>(model: T) async -> MyToken? {
        return switch model {
        case is Territory:
            await findToken(territory: model as! Territory)
        case is TerritoryAddress:
            await findToken(territoryAddress: model as! TerritoryAddress)
        case is House:
            await findToken(house: model as! House)
        case is Visit:
            await findToken(visit: model as! Visit)
        default:
            nil
        }
    }
    
    func adminNeedLogin() async -> Bool {
        if existsAdminCredentials() {
            do {
                _ = try await CongregationAPI().signIn(congregationId: authorizationProvider.congregationId!, congregationPass: authorizationProvider.congregationPass!)
            } catch {
                if let error = error.asAFError {
                    if error.responseCode == 401 {
                        authorizationProvider.authorizationToken = nil
                        return true
                    }
                }
            }
        }
        return false
    }
    
    func existsAdminCredentials() -> Bool {
        return authorizationProvider.congregationId != nil && authorizationProvider.congregationPass != nil
    }
    
    func existsModeratorAccess() -> Bool {
        for token in dataController.getMyTokens() {
            if token.moderator {
                return true
            }
        }
        
        return false
    }
    
    func findToken(territory: Territory) async -> MyToken? {
        var tokens = [MyToken]()
        let tokensDb = dataController.getMyTokens()
        let tokenTerritories = dataController.getTokenTerritories()
        
        tokenTerritories.filter { tokenTerritory in
            return tokenTerritory.territory == territory.id
        }.forEach { tokenTerritory in
            do {
                if let token = tokensDb.first(where: { $0.id == tokenTerritory.token }) {
                    tokens.append(token)
                }
            }
        }
        
        if let moderatorToken = tokens.first(where: { $0.moderator }) {
            return moderatorToken
        }
        
        return tokens.first(where: { $0.expires > Int64(Date().timeIntervalSince1970 * 1000) })
    }
    
    func findToken(territoryAddress: TerritoryAddress) async -> MyToken? {
        let territories = dataController.getTerritories()
        
        if let territory = territories.first(where: { $0.id == territoryAddress.territory }) {
            return await findToken(territory: territory)
        }
        
        return nil
    }
    
    func findToken(house: House) async -> MyToken? {
        let territoriesAddresses = dataController.getTerritoryAddresses()
        
        if let territoryAddress = territoriesAddresses.first(where: { $0.id == house.territoryAddress }) {
            return await findToken(territoryAddress: territoryAddress)
        }
        
        return nil
    }
    
    func findToken(visit: Visit) async -> MyToken? {
        let houses = dataController.getHouses()
        
        if let house = houses.first(where: { $0.id == visit.house }) {
            return await findToken(house: house)
        }
        
        return nil
    }
    
    func exitAdministrator() {
        authorizationProvider.congregationId = nil
        authorizationProvider.congregationPass = nil
        dataStore.congregationName = nil
    }
}
