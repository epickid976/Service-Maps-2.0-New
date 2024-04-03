//
//  API_Manager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/27/23.
//

import Foundation
import Alamofire

class AuthenticationAPI {
    let baseURL = "auth/"

    
    //MARK: Login
    func login(email: String, password: String) async throws -> LoginResponse {
        do {
            let response = try await ApiRequestAsync().postRequest(url: baseURL + "login", body: LoginForm(email: email, password: password))
            let decoder = JSONDecoder()
            let jsonData = response.data(using: .utf8)!
            
            let loginResponse = try decoder.decode(LoginResponse.self, from: jsonData)
            
            return loginResponse
        } catch {
            throw error.self
        }
    }
    
    func signUp(name: String, email: String, password: String) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "signup", body: SignUpForm(name: name, email: email, password: password, password_confirmation: password))
        } catch {
            throw error.self
        }
    }
    
    func logout() async throws {
        do {
            
            _ = try await ApiRequestAsync().getRequest(url: baseURL + "logout")
            
        } catch {
            throw error.self
        }
    }
    
    func user() async throws -> UserResponse {
        do {
            let response = try await ApiRequestAsync().getRequest(url: baseURL + "user")
            
            let decoder = JSONDecoder()
            
            let jsonData = response.data(using: .utf8)!
            
            let userResponse = try decoder.decode(UserResponse.self, from: jsonData)
            
            return userResponse
        } catch {
            throw error.self
        }
    }
    
    func resendEmailValidation(email: String) async -> Result<Bool, Error> {
        do {
            _ = try await ApiRequestAsync().getRequest(url: baseURL + "signup/activate/resend/\(email)")
            
            return Result.success(true)
        } catch {
            return Result.failure(error)
        }
        
    }
    
    func activateEmail(token: String) async -> Result<Bool, Error> {
        do {
            _ = try await ApiRequestAsync().getRequest(url: baseURL + "signup/activate/\(token)")
            
            return Result.success(true)
        } catch {
            return Result.failure(error)
        }
    }
    
    func deleteAccount() async -> Result<Bool, Error> {
        do {
            _ = try await ApiRequestAsync().getRequest(url: baseURL + "delete")
            
            return Result.success(true)
        } catch {
            return Result.failure(error)
        }
    }
}
