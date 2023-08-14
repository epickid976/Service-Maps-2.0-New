//
//  PasswordReset.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation
import Alamofire

class PasswordResetAPI {
    let baseURL = "password/"
    
    func requestReset(email: String) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "create", body: RequestResetForm(email: email))
        } catch {
            throw error.self
        }
    }
    
    func resetPassword(email: String, password: String, token: String) async throws -> UserResponse{
        do {
            let response = try await ApiRequestAsync().postRequest(url: baseURL + "reset", body: ResetPasswordForm(email: email, password: password, password_confirmation: password, token: token))
            
            let decoder = JSONDecoder()
            
            let jsonData = response.data(using: .utf8)!
            
            let userResponse = try decoder.decode(UserResponse.self, from: jsonData)
            
            return userResponse
        } catch {
            throw error.self
        }
    }

}
