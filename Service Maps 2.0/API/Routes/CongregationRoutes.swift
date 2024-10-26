//
//  CongregationRoutes.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 10/22/24.
//

import Foundation
import Alamofire
import Papyrus

//MARK: Papyrus API Protocol
@API
public protocol CongregationRoutes {
    
    @POST("congregation/sign")
    func signIn(congregationSignInForm: Body<CongregationSignInForm>) async throws -> CongregationResponse
    
    @POST("congregation/phone/sign")
    func phoneSignIn(congregationSignInForm: Body<CongregationSignInForm>) async throws -> CongregationResponse
}

