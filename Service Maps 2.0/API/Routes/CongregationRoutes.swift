//
//  CongregationRoutes.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 10/22/24.
//

import Foundation
@preconcurrency import Papyrus
//MARK: Papyrus API Protocol
@API
public protocol CongregationRoutes: Sendable  {
    
    @POST("congregation/sign")
    func signIn(congregationSignInForm: Body<CongregationSignInForm>) async throws -> CongregationResponse
    
    @POST("congregation/phone/sign")
    func phoneSignIn(congregationSignInForm: Body<CongregationSignInForm>) async throws -> CongregationResponse
}

