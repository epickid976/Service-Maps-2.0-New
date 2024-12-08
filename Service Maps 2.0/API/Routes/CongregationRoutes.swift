//
//  CongregationRoutes.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 10/22/24.
//

import Foundation
@preconcurrency import Papyrus

//MARK: - Congregation Routes

@API
public protocol CongregationRoutes: Sendable  {
    
    //MARK: - Congregation Sign In
    
    @POST("congregation/sign")
    func signIn(congregationSignInForm: Body<CongregationSignInForm>) async throws -> CongregationResponse
    
    //MARK: - Congregation Phone Sign In
    
    @POST("congregation/phone/sign")
    func phoneSignIn(congregationSignInForm: Body<CongregationSignInForm>) async throws -> CongregationResponse
}

