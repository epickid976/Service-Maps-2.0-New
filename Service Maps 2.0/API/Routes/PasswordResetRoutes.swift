//
//  PasswordResetRoutes.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 10/22/24.
//

import Foundation
import Papyrus

@API
public protocol PasswordResetRoutes {
    
    @POST("password/create")
    func requestReset(requestResetForm: Body<RequestResetForm>) async throws

    @POST("password/reset")
    func resetPassword(resetPasswordForm: Body<ResetPasswordForm>) async throws -> UserResponse
}