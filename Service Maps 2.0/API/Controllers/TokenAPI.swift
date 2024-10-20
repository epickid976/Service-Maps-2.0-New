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
    func loadOwnedTokens() async throws -> [Token] {
        
        do {
            let response = try await ApiRequestAsync().getRequest(url: baseURL + "loadown")
            
            let decoder = JSONDecoder()
            
            let jsonData = response.data(using: .utf8)!
            
            let reply = try decoder.decode([Token].self, from: jsonData)
            
            return reply
        } catch {
            throw error.self
        }
    }
    
    func loadUserTokens() async throws -> [Token] {
        
        
        do {
            let response = try await ApiRequestAsync().getRequest(url: baseURL + "loaduser")
            
            let decoder = JSONDecoder()
            
            let jsonData = response.data(using: .utf8)!
            
            let reply = try decoder.decode([Token].self, from: jsonData)
            
            return reply
        } catch {
            throw error.self
        }
    }
    
    func getTerritoriesOfToken(token: String) async throws -> [TokenTerritory] {
        
        do {
            let response = try await ApiRequestAsync().getRequest(url: baseURL + "territories/\(token)")
            
            let decoder = JSONDecoder()
            
            let jsonData = response.data(using: .utf8)!
            
            let reply = try decoder.decode([TokenTerritory].self, from: jsonData)
            
            return reply
        } catch {
            
            throw error.self
        }
    }
    
    //MARK: DELETE
    func createToken(name: String, moderator: Bool, territories: String, congregation: Int64, expire: Int64?) async throws -> Token {
        do {
            let response = try await ApiRequestAsync().postRequest(url: baseURL + "new", body: NewTokenForm(name: name, moderator: moderator, territories: territories, congregation: congregation, expire: expire))
            
            _ = JSONDecoder()
            
            let jsonData = response.data(using: .utf8)!
            
            
            
            let reply = try createTokenManually(from: jsonData)
            
            return reply
        } catch {
            throw error.self
        }
    }
    
    func editToken(tokenId: String, territories: String) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "edit", body: EditTokenForm(token: tokenId, territories: territories))
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
    
    func unregister(token: String) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "unregister", body: DeleteTokenForm(token: token))
        } catch {
            throw error.self
        }
    }
    
    func register(token: String) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "register", body: DeleteTokenForm(token: token))
        } catch {
            
            throw error.self
        }
    }
    
    func usersOfToken(token: String) async  -> Result<[UserSimpleResponse], Error> {
        do {
            let response = try await ApiRequestAsync().postRequest(url: baseURL + "tokenusers", body: DeleteTokenForm(token: token))
            
            let decoder = JSONDecoder()
            
            let jsonData = response.data(using: .utf8)!
            
            let reply = try decoder.decode([UserSimpleResponse].self, from: jsonData)
            
            return Result.success(reply)
        } catch {
            return .failure(error)
        }
    }
    
    func removeUserFromToken(token: String, userId: String) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "tokenuserremove", body: TokenAndUserIdForm(token: token, userid: userId))
        } catch {
            throw error.self
        }
    }
    
    func blockUnblockUserFromToken(token: String, userId: String, blocked: Bool) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "blockunblock", body: TokenAndUserIdForm(token: token, userid: userId, blocked: blocked))
        } catch {
            throw error.self
        }
    }
    
    func createTokenManually(from jsonData: Data) throws -> Token {
      guard let jsonDictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
          throw CustomErrors.NotFound // Define an error type
      }

      var name: String = ""
      var id: String = ""
      var owner: String? = nil
      var congregation: String = ""
      var moderator: Bool = false
      var expire: Int64? = nil
      var user: String? = nil

      if let nameValue = jsonDictionary["name"] as? String {
        name = nameValue
      }

      if let idValue = jsonDictionary["id"] as? String {
        id = idValue
      }

      // Handle optional properties
      owner = jsonDictionary["owner"] as? String
      congregation = String(describing: jsonDictionary["congregation"] ?? "") // Handle potential non-string value

      if let moderatorValue = jsonDictionary["moderator"] as? Bool {
        moderator = moderatorValue
      }

      expire = jsonDictionary["expire"] as? Int64

      user = jsonDictionary["user"] as? String

        return Token(id: id, name: name, owner: owner ?? "", congregation: congregation, moderator: moderator, expire: expire, user: user)
    }

}
