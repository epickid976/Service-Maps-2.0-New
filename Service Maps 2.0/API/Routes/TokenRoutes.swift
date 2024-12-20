//
//  TokenRoutes.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 10/22/24.
//

@preconcurrency import Papyrus

//MARK: - Token Routes

@API
public protocol TokenRoutes: Sendable  {
    
    //MARK: - Load All
    
    @GET("tokens/load")
    func loadAllTokens() async throws -> [MyTokenWithAll]
    
    @GET("tokens/loadown")
    func loadOwnedTokens() async throws -> [Token]

    @GET("tokens/loaduser")
    func loadUserTokens() async throws -> [Token]

    //MARK: - Load Specific
    
    @GET("tokens/territories/:token")
    func getTerritoriesOfToken(token: Path<String>) async throws -> [TokenTerritory]
    
    //MARK: - Token CRUD
    
    @POST("tokens/new")
    func createToken(newTokenForm: Body<NewTokenForm>) async throws -> CreateTokenResponse

    @POST("tokens/edit")
    func editToken(editTokenForm: Body<EditTokenForm>) async throws

    @POST("tokens/delete")
    func deleteToken(deleteTokenForm: Body<DeleteTokenForm>) async throws

    //MARK: - Token Registration
    
    @POST("tokens/unregister")
    func unregister(deleteTokenForm: Body<DeleteTokenForm>) async throws

    @POST("tokens/register")
    func register(deleteTokenForm: Body<DeleteTokenForm>) async throws

    //MARK: - Token Users
    
    @POST("tokens/tokenusers")
    func usersOfToken(deleteTokenForm: Body<DeleteTokenForm>) async throws -> [UserSimpleResponse]

    @POST("tokens/tokenuserremove")
    func removeUserFromToken(tokenAndUserIdForm: Body<TokenAndUserIdForm>) async throws

    @POST("tokens/blockunblock")
    func blockUnblockUserFromToken(tokenAndUserIdForm: Body<TokenAndUserIdForm>) async throws
}

