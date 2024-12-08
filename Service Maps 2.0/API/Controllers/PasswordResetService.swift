//
//  PasswordReset.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation
import Alamofire
import PapyrusCore

//MARK: - Password Reset Service

@BackgroundActor
class PasswordResetService: @unchecked Sendable {
    //MARK: - API
    private lazy var api: PasswordResetRoutes = PasswordResetRoutesAPI(provider: APIProvider().provider)

    //MARK: - Request
    // Request password reset
    func requestReset(email: String) async -> Result<Void, Error> {
        do {
            try await api.requestReset(requestResetForm: RequestResetForm(email: email))
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    //MARK: - Reset
    // Reset password with token
    func resetPassword(password: String, token: String) async -> Result<UserResponse, Error> {
        do {
           let result = try await api.resetPassword(resetPasswordForm: ResetPasswordForm(password: password, password_confirmation: password, token: token))
            return .success(result)
        } catch {
            return .failure(error)
        }
    }
}
