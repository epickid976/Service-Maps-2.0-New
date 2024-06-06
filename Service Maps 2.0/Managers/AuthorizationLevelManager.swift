//
//  AuthorizationLevelManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/27/23.
//

import Foundation
import RealmSwift
import Alamofire

class AuthorizationLevelManager: ObservableObject {
    @Published private var realmManager = RealmManager.shared
    
    
    
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
    @MainActor
    func getAccessLevel<T>(model: T) -> AccessLevel?  where T: Object{
        if existsAdminCredentials() {
            return .Admin
        }
        
        if let token = findToken(model: model) {
            if (dataStore.userEmail == token.user) {
                return .Moderator
            } else {
                return .User
            }
        }
        
        return nil
    }
    
    @MainActor
    func setAuthorizationTokenFor<T>(model: T) async  where T: Object {
        if let token =  findToken(model: model) {
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
    @MainActor
    func findToken<T>(model: T) -> TokenObject? where T: Object {
      switch model {
      case let territory as TerritoryObject:
        return findToken(territory: territory)
      case let territoryAddress as TerritoryAddressObject:
        return findToken(territoryAddress: territoryAddress)
      case let house as HouseObject:
        return findToken(house: house)
      case let visit as VisitObject:
        return findToken(visit: visit)
      default:
        return nil
      }
    }

    
    func adminNeedLogin() async -> Bool {
        if existsAdminCredentials() {
            do {
                _ = try await CongregationAPI().signIn(congregationId: authorizationProvider.congregationId!, congregationPass: authorizationProvider.congregationPass!)
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
    
    func existsAdminCredentials() -> Bool {
        return authorizationProvider.congregationId != nil && authorizationProvider.congregationPass != nil
    }
    
    func existsModeratorAccess() -> Bool {
        for token in Array(realmManager.tokensFlow) {
            if token.user == dataStore.userEmail {
                return true
            }
        }
        
        return false
    }
    
    func findToken(territory: TerritoryObject) -> TokenObject? {
        var tokens = [TokenObject]()
        let tokensDb = Array(realmManager.tokensFlow)
        let tokenTerritories = Array(realmManager.tokenTerritoriesFlow)
        
        
        
        tokenTerritories.filter { tokenTerritory in
            tokenTerritory.territory == territory.id
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
        print(tokens.first(where: { $0.expire ?? Int64(Date().timeIntervalSince1970 * 1000) >= Int64(Date().timeIntervalSince1970 * 1000) }))
        return tokens.first(where: { $0.expire ?? Int64(Date().timeIntervalSince1970 * 1000) >= Int64(Date().timeIntervalSince1970 * 1000) })
    }
    
    func findToken(territoryAddress: TerritoryAddressObject) -> TokenObject? {
        let territories = Array(realmManager.territoriesFlow)
        
        if let territory = territories.first(where: { $0.id == territoryAddress.territory }) {
            return findToken(territory: territory)
        }
        
        return nil
    }
    
    func findToken(house: HouseObject) -> TokenObject? {
        let territoriesAddresses = Array(realmManager.addressesFlow)
        
        if let territoryAddress = territoriesAddresses.first(where: { $0.id == house.territory_address }) {
            return findToken(territoryAddress: territoryAddress)
        }
        
        return nil
    }
    
    @MainActor
    func findToken(visit: VisitObject) -> TokenObject? {
        let houses = Array(realmManager.housesFlow)
        
        if let house = houses.first(where: { $0.id == visit.house }) {
            return findToken(house: house)
        }
        
        return nil
    }
    
    func exitAdministrator() {
        authorizationProvider.congregationId = nil
        authorizationProvider.congregationPass = nil
        dataStore.congregationName = nil
    }
    
    func exitPhoneLogin() {
        authorizationProvider.phoneCongregationId = nil
        authorizationProvider.phoneCongregationPass = nil
    }
    
    func existsPhoneCredentials() -> Bool {
        return authorizationProvider.phoneCongregationId != nil && authorizationProvider.phoneCongregationPass != nil
    }
    
    func phoneNeedLogin() async -> Bool {
        if existsPhoneCredentials() {
            do {
                _ = try await CongregationAPI().phoneSignIn(congregationSignInForm: CongregationSignInForm(
                    id: Int64(authorizationProvider.phoneCongregationId!)!,
                    password: authorizationProvider.phoneCongregationPass!)
                    )
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
    
    func setPhoneCredentials(password: String, congregationResponse: CongregationResponse) {
        DispatchQueue.main.async {
            self.authorizationProvider.phoneCongregationId = congregationResponse.id
            self.authorizationProvider.phoneCongregationPass = password
        }
    }
}
