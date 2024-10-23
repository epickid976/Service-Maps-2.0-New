//
//  TokenRoutes.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 10/22/24.
//
import Papyrus

@API
public protocol TokenRoutes {
    
    @GET("tokens/loadown")
    func loadOwnedTokens() async throws -> [Token]

    @GET("tokens/loaduser")
    func loadUserTokens() async throws -> [Token]

    @GET("tokens/territories/{token}")
    func getTerritoriesOfToken(token: String) async throws -> [TokenTerritory]

    @POST("tokens/new")
    func createToken(newTokenForm: NewTokenForm) async throws -> Token

    @POST("tokens/edit")
    func editToken(editTokenForm: EditTokenForm) async throws

    @POST("tokens/delete")
    func deleteToken(deleteTokenForm: DeleteTokenForm) async throws

    @POST("tokens/unregister")
    func unregister(deleteTokenForm: DeleteTokenForm) async throws

    @POST("tokens/register")
    func register(deleteTokenForm: DeleteTokenForm) async throws

    @POST("tokens/tokenusers")
    func usersOfToken(deleteTokenForm: DeleteTokenForm) async throws -> [UserSimpleResponse]

    @POST("tokens/tokenuserremove")
    func removeUserFromToken(tokenAndUserIdForm: TokenAndUserIdForm) async throws

    @POST("tokens/blockunblock")
    func blockUnblockUserFromToken(tokenAndUserIdForm: TokenAndUserIdForm) async throws
}

