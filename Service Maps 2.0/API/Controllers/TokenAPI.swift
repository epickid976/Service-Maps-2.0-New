//
//  TokenAPI.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation
import Alamofire

class TokenAPI {
    let baseURL = "tokens/"
    
    //MARK: LOADING
    func loadOwnedTokens() async throws -> [MyTokenModel] {
        
        do {
            let response = try await ApiRequestAsync().getRequest(url: baseURL + "loadown")
            
            let decoder = JSONDecoder()
            
            let jsonData = response.data(using: .utf8)!
            
            let reply = try decoder.decode([MyTokenModel].self, from: jsonData)
            
            return reply
        } catch {
            throw error.self
        }
    }
    
    func loadUserTokens() async throws -> [MyTokenModel] {
        
        
        do {
            let response = try await ApiRequestAsync().getRequest(url: baseURL + "loaduser")
            
            let decoder = JSONDecoder()
            
            let jsonData = response.data(using: .utf8)!
            
            let reply = try decoder.decode([MyTokenModel].self, from: jsonData)
            
            return reply
        } catch {
            throw error.self
        }
    }
    
    func getTerritoriesOfToken(token: String) async throws -> [TokenTerritoryModel] {
        
        do {
            let response = try await ApiRequestAsync().getRequest(url: baseURL + "territories/\(token)")
            
            let decoder = JSONDecoder()
            
            let jsonData = response.data(using: .utf8)!
            
            let reply = try decoder.decode([TokenTerritoryModel].self, from: jsonData)
            
            return reply
        } catch {
            throw error.self
        }
    }
    
    //MARK: DELETE
    func createToken(name: String, moderator: Bool, territories: String, congregation: Int64, expire: Int64?) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "new", body: NewTokenForm(name: name, moderator: moderator, territories: territories, congregation: congregation, expire: expire))
        } catch {
            throw error.self
        }
    }
    
    func deleteToken(token: String) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "delete", body: DeleteTokenForm(token: token))
        } catch {
            throw error.self
        }
    }
}
