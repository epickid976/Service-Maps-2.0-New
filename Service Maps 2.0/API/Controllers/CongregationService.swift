//
//  CongregationService.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation
import Papyrus

class CongregationService {
    private lazy var api: CongregationRoutes = CongregationRoutesAPI(provider: APIProvider.shared.provider)

    // Congregation Sign-In
    func signIn(congregationSignInForm: CongregationSignInForm) async -> Result<CongregationResponse, Error> {
        do {
            let congregation = try await api.signIn(congregationSignInForm: congregationSignInForm)
            return .success(congregation)
        } catch {
            return .failure(error)
        }
    }

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
