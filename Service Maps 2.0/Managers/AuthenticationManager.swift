//
//  AuthenticationManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/8/23.
//

import Foundation
import Alamofire

@MainActor
class AuthenticationManager: ObservableObject, Sendable {
    
    private let authorizationProvider = AuthorizationProvider.shared
    private let authenticationApi = AuthenticationService()
    private let congregationApi = CongregationService()
    private let passwordResetApi = PasswordResetService()
    private let dataStore = StorageManager.shared
    private let authorizationLevelManager = AuthorizationLevelManager()
    
    @BackgroundActor
    func signUp(signUpForm: SignUpForm) async -> Result<Void, Error> {
        let result = await authenticationApi.signUp(signUpForm: signUpForm)
        
        if result.isSuccess {
            await MainActor.run {
                dataStore.userName = signUpForm.name
                dataStore.userEmail = signUpForm.email
                dataStore.passTemp = signUpForm.password
            }
        }
        return result
        
    }
    @BackgroundActor
    func login(logInForm: LoginForm) async -> Result<LoginResponse, Error> {
        let result = await authenticationApi.login(logInForm: logInForm)
        
        print("Result: \(result)")
        if let logInResponse = try? result.get() {
            await MainActor.run {
                self.dataStore.passTemp = nil
                self.authorizationProvider.authorizationToken = logInResponse.access_token
            }
        }
        
        _ = await getUser()
        
        return result
    }
    @BackgroundActor
    func loginEmail(email: String) async -> Result<Void, Error> {
        return await authenticationApi.loginEmail(email: email)
    }
    @BackgroundActor
    func loginEmailToken(token: String) async -> Result<LoginResponse, Error> {
        let result = await authenticationApi.loginEmailToken(token: token)
        
        if let loginResponse = try? result.get() {
            await MainActor.run {
                self.dataStore.passTemp = nil
                self.authorizationProvider.authorizationToken = loginResponse.access_token
            }
        }
        
        _ = await getUser()
        
        return result
    }
    @BackgroundActor
    func getUser() async -> Result<UserResponse, Error> {
        let result = await authenticationApi.user()
        
        if let userResponse = try? result.get() {
            await MainActor.run {
                self.dataStore.userEmail = userResponse.email
                self.dataStore.userName = userResponse.name
            }
        }
        
        return result
    }
    @BackgroundActor
    func logout() async -> Result<Void, Error> {
        let result = await authenticationApi.logout()
        
        if result.isSuccess {
            await logoutProcess()
        }
        
        return result
    }
    @BackgroundActor
    func resendVerificationEmail() async -> Result<Void, Error> {
        guard let userEmail = await dataStore.userEmail else { return .failure(CustomErrors.NotFound) }
        return await authenticationApi.resendEmailValidation(email: userEmail)
    }
    
    @BackgroundActor
    func signInAdmin(congregationSignInForm: CongregationSignInForm) async -> Result<CongregationResponse, Error> {
        let result = await congregationApi.signIn(congregationSignInForm: congregationSignInForm)
        
        if let congregationResponse = try? result.get() {
            await MainActor.run {
                authorizationProvider.congregationId = Int64(congregationResponse.id)
                authorizationProvider.congregationPass = congregationSignInForm.password
                dataStore.congregationName = congregationResponse.name
            }
        }
        
        return result
    }
    @BackgroundActor
    func requestPasswordReset(email: String) async -> Result<Void, Error> {
        return await passwordResetApi.requestReset(email: email)
    }
    @BackgroundActor
    func resetPassword(password: String, token: String) async -> Result<UserResponse, Error> {
        let result = await passwordResetApi.resetPassword(password: password, token: token)
        
        if let userResponse = try? result.get() { _ = await login(logInForm: LoginForm(email: userResponse.email, password: password)) }
        
        return result
    }
    @BackgroundActor
    func activateEmail(token: String) async -> Result<Void, Error> {
        return await authenticationApi.activateEmail(token: token)
    }
    @BackgroundActor
    func deleteAccount() async -> Result<Void, Error> {
        let result = await authenticationApi.deleteAccount()
        
        if result.isSuccess {
            await self.dataStore.clear()
            await self.authorizationProvider.clear()
        }
        
        await SynchronizationManager.shared.startupProcess(synchronizing: true)
        
        return result
    }
    
    @MainActor func exitAdministrator() { AuthorizationLevelManager().exitAdministrator() }
    
    @MainActor func exitPhoneLogin() { AuthorizationLevelManager().exitPhoneLogin() }
    @BackgroundActor
    func signInPhone(congregationSignInForm: CongregationSignInForm) async -> Result<CongregationResponse, Error> {
        let result = await congregationApi.phoneSignIn(congregationSignInForm: congregationSignInForm)
        
        if let congregationResponse = try? result.get() {
            await MainActor.run {
                authorizationLevelManager.setPhoneCredentials(password: congregationSignInForm.password, congregationResponse: congregationResponse)
                dataStore.phoneCongregationName = congregationResponse.name
            }
        }
        
        return result
        
    }
    @BackgroundActor
    func editUserName(userName: String) async -> Result<Void, Error> {
        let result = await authenticationApi.editUserName(userName: userName)
        
        if result.isSuccess {
            await MainActor.run {
                dataStore.userName = userName
            }
        }
        
        return result
    }
    @MainActor
    fileprivate func logoutProcess() {
        dataStore.userEmail = nil
        dataStore.passTemp = nil
        dataStore.userName = nil
        dataStore.congregationName = nil
        authorizationProvider.authorizationToken = nil
    }
}
