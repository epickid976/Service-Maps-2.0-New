//
//  AuthenticationRoutes.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 10/22/24.
//

import Foundation
import Alamofire
@preconcurrency import Papyrus


//MARK: - Authentication Routes

@API
public protocol AuthenticationRoutes: Sendable  {
    
    //MARK: - Login
    @POST("auth/login")
    func login(logInForm: Body<LoginForm>) async throws -> LoginResponse
    
    @POST("auth/loginemail")
    func loginEmail(loginForm: Body<LoginForm>) async throws
    
    @POST("auth/loginemailtoken")
    func loginEmailToken(singleTokenForm: Body<SingleTokenForm>) async throws -> LoginResponse
    
    //MARK: - Sign up
    @POST("auth/signup")
    func signup(signupForm: Body<SignUpForm>) async throws
    
    //MARK: - Logout
    @GET("auth/logout")
    func logout() async throws
    
    //MARK: - User
    @GET("auth/user")
    func user() async throws -> UserResponse
    
    //MARK: - Validation
    @GET("auth/signup/activate/resend/:email")
    func resendEmailValidation(email: Path<String>) async throws
    
    @GET("auth/signup/activate/:token")
    func activateEmail(token: Path<String>) async throws
    
    //MARK: - Delete Account
    @GET("auth/delete")
    func deleteAccount() async throws
    
    //MARK: - Edit Name
    @POST("auth/editusername")
    func editUserName(newUserNameForm: Body<NewUserNameForm>) async throws
}

