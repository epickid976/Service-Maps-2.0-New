//
//  TokenService 2.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 10/22/24.
//
import Foundation
import Papyrus


class TokenService: @unchecked Sendable {
    private let api: TokenRoutes = TokenRoutesAPI(provider: APIProvider().provider)
    
    // Load owned tokens
    func loadOwnedTokens() async -> Result<[Token], Error> {
        do {
            let tokens = try await api.loadOwnedTokens()
            return .success(tokens)
        } catch {
            return .failure(error)
        }
    }
    
    // Load user tokens
    func loadUserTokens() async -> Result<[Token], Error> {
        do {
            let tokens = try await api.loadUserTokens()
            return .success(tokens)
        } catch {
            return .failure(error)
        }
    }
    
    // Get territories of a token
    func getTerritoriesOfToken(token: String) async -> Result<[TokenTerritory], Error> {
        do {
            let territories = try await api.getTerritoriesOfToken(token: token)
            return .success(territories)
        } catch {
            return .failure(error)
        }
    }
    
    // Create token
    func createToken(name: String, moderator: Bool, territories: String, congregation: Int64, expire: Int64?) async -> Result<Token, Error> {
        print("Territories String: \(territories)")
        do {
            let token = try await api.createToken(newTokenForm: NewTokenForm(name: name, moderator: moderator, territories: territories, congregation: congregation, expire: expire))
            return .success(token.token)
        } catch {
            return .failure(error)
        }
    }
    
    // Edit token
    func editToken(tokenId: String, territories: String) async -> Result<Void, Error> {
        do {
            try await api.editToken(editTokenForm: EditTokenForm(token: tokenId, territories: territories))
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    // Delete token
    func deleteToken(token: String) async -> Result<Void, Error> {
        do {
            try await api.deleteToken(deleteTokenForm: DeleteTokenForm(token: token))
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    // Unregister token
    func unregister(token: String) async -> Result<Void, Error> {
        do {
            try await api.unregister(deleteTokenForm: DeleteTokenForm(token: token))
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    // Register token
    func register(token: String) async -> Result<Void, Error> {
        do {
            try await api.register(deleteTokenForm: DeleteTokenForm(token: token))
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    // Get users of a token
    func usersOfToken(token: String) async -> Result<[UserSimpleResponse], Error> {
        do {
            let users = try await api.usersOfToken(deleteTokenForm: DeleteTokenForm(token: token))
            return .success(users)
        } catch {
            return .failure(error)
        }
    }
    
    // Remove user from a token
    func removeUserFromToken(token: String, userId: String) async -> Result<Void, Error> {
        do {
            try await api.removeUserFromToken(tokenAndUserIdForm: TokenAndUserIdForm(token: token, userid: userId))
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    // Block or unblock a user from a token
    func blockUnblockUserFromToken(token: String, userId: String, blocked: Bool) async -> Result<Void, Error> {
        do {
            try await api.blockUnblockUserFromToken(tokenAndUserIdForm: TokenAndUserIdForm(token: token, userid: userId, blocked: blocked))
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}
