//
//  API_Manager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/27/23.
//

import Foundation


class AuthenticationService: @unchecked Sendable {
    private lazy var api: AuthenticationRoutes = AuthenticationRoutesAPI(provider: APIProvider().provider)
    
    // Sign up a new user with their details
    func signUp(signUpForm: SignUpForm) async -> Result<Void, Error> {
        do {
            try await api.signup(signupForm: signUpForm)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    // Log in the user and return the login response
    func login(logInForm: LoginForm) async -> Result<LoginResponse, Error> {
        do {
            let response = try await api.login(logInForm: logInForm)
            return .success(response)
        } catch {
            return .failure(error)
        }
    }
    
    // Log in the user using just an email (no password)
    func loginEmail(email: String) async -> Result<Void, Error> {
        do {
            try await api.loginEmail(loginForm: LoginForm(email: email, password: ""))
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    // Log in using a token sent via email
    func loginEmailToken(token: String) async -> Result<LoginResponse, Error> {
        do {
            let response = try await api.loginEmailToken(singleTokenForm: SingleTokenForm(token: token))
            return .success(response)
        } catch {
            return .failure(error)
        }
    }
    
    // Resend email validation to a user
    func resendEmailValidation(email: String) async -> Result<Void, Error> {
        do {
            try await api.resendEmailValidation(email: email)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    // Activate a user’s account using a token
    func activateEmail(token: String) async -> Result<Void, Error> {
        do {
            try await api.activateEmail(token: token)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    // Log out the current user
    func logout() async -> Result<Void, Error> {
        do {
            try await api.logout()
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    // Fetch details of the currently authenticated user
    func user() async -> Result<UserResponse, Error> {
        do {
            let response = try await api.user()
            return Result.success(response)
        } catch {
            return .failure(error)
        }
    }
    
    // Delete the current user’s account
    func deleteAccount() async -> Result<Void, Error> {
        do {
            try await api.deleteAccount()
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    // Edit the username of the current user
    func editUserName(userName: String) async -> Result<Void, Error> {
        do {
            try await api.editUserName(newUserNameForm: NewUserNameForm(username: userName))
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}
