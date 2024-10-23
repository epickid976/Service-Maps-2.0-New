//
//  AuthenticationRoutes.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 10/22/24.
//

import Foundation
import Alamofire
import Papyrus


//MARK: Papyrus API Protocol
@API
public protocol AuthenticationRoutes {
    
    ///# Login
    @POST("auth/login")
    func login(loginForm: LoginForm) async throws -> LoginResponse
    
    
    @POST("auth/loginemail")
    func loginEmail(loginForm: LoginForm) async throws
    
    @POST("auth/loginemailtoken")
    func loginEmailToken(singleTokenForm: SingleTokenForm) async throws -> LoginResponse
    
    ///# Sign up
    @POST("auth/signup")
    func signup(signupForm: SignUpForm) async throws
    
    ///# Logout
    @GET("auth/logout")
    func logout() async throws
    
    ///# User
    @GET("auth/user")
    func user() async throws -> String
    
    ///# Validation
    @GET("auth/signup/activate/resend/:email")
    func resendEmailValidation(email: String) async throws
    
    @GET("auth/signup/activate/:token")
    func activateEmail(token: String) async throws
    
    /// # Delete Account
    @GET("auth/delete")
    func deleteAccount() async throws
    
    /// # Edit Name
    @POST("auth/editusername")
    func editUserName(newUserNameForm: NewUserNameForm) async throws
}

