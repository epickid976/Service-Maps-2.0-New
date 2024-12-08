//
//  CongregationService.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation
import Papyrus

//MARK: - Congregation Service

@BackgroundActor
class CongregationService: @unchecked Sendable {
    //MARK: - API
    private lazy var api: CongregationRoutes = CongregationRoutesAPI(provider: APIProvider().provider)

    //MARK: - Sign In
    // Congregation Sign-In
    func signIn(congregationSignInForm: CongregationSignInForm) async -> Result<CongregationResponse, Error> {
        do {
            let congregation = try await api.signIn(congregationSignInForm: congregationSignInForm)
            return .success(congregation)
        } catch {
            return .failure(error)
        }
    }

    //MARK: - Phone Sign-In
    // Phone Sign-In
    func phoneSignIn(congregationSignInForm: CongregationSignInForm) async -> Result<CongregationResponse, Error> {
        do {
            let congregation = try await api.phoneSignIn(congregationSignInForm: congregationSignInForm)
            return .success(congregation)
        } catch {
            return .failure(error)
        }
    }
}
