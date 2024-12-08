//
//  PasswordResetRoutes.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 10/22/24.
//

import Foundation
@preconcurrency import Papyrus

//MARK: - Password Reset Routes

@API
public protocol PasswordResetRoutes: Sendable  {
    
    //MARK: - Create Request
    @POST("password/create")
    func requestReset(requestResetForm: Body<RequestResetForm>) async throws

    //MARK: - Reset Request
    @POST("password/reset")
    func resetPassword(resetPasswordForm: Body<ResetPasswordForm>) async throws -> UserResponse
}
