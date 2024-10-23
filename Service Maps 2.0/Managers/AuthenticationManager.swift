//
//  AuthenticationManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/8/23.
//

import Foundation
import Alamofire

class AuthenticationManager: ObservableObject {
    
    private var authorizationProvider = AuthorizationProvider.shared
    private var authenticationApi = AuthenticationService()
    private var congregationApi = CongregationService()
    private var passwordResetApi = PasswordResetService()
    private var dataStore = StorageManager.shared
    private var authorizationLevelManager = AuthorizationLevelManager()
    
    func signUp(signUpForm: SignUpForm) async -> Result<Void, Error> {
        let result = await authenticationApi.signUp(signUpForm: signUpForm)
        
        if result.isSuccess {
            dataStore.userName = signUpForm.name
            dataStore.userEmail = signUpForm.email
            dataStore.passTemp = signUpForm.password
        }
        return result
        
    }
    
    func login(logInForm: LoginForm) async -> Result<LoginResponse, Error> {
        let result = await authenticationApi.login(loginForm: logInForm)
        
        if let logInResponse = try? result.get() {
            self.dataStore.passTemp = nil
            self.authorizationProvider.authorizationToken = logInResponse.access_token
        }
        
        _ = await getUser()
        
        return result
    }
    
    func loginEmail(email: String) async -> Result<Void, Error> {
        return await authenticationApi.loginEmail(email: email)
    }
    
    func loginEmailToken(token: String) async -> Result<LoginResponse, Error> {
        let result = await authenticationApi.loginEmailToken(token: token)
        
        if let loginResponse = try? result.get() {
                self.dataStore.passTemp = nil
                self.authorizationProvider.authorizationToken = loginResponse.access_token
        }
        
        _ = await getUser()
        
        return result
    }
    
    func getUser() async -> Result<UserResponse, Error> {
        let result = await authenticationApi.user()
        
        if let userResponse = try? result.get() {
            self.dataStore.userEmail = userResponse.email
            self.dataStore.userName = userResponse.name
        }
        
        return result
    }
    
    func logout() async -> Result<Void, Error> {
        let result = await authenticationApi.logout()
        
        if result.isSuccess {
            logoutProcess()
        }
        
        return result
    }
    
    func resendVerificationEmail() async -> Result<Void, Error> {
        guard let userEmail = dataStore.userEmail else { return .failure(CustomErrors.NotFound) }
        return await authenticationApi.resendEmailValidation(email: userEmail)
    }
    
    func signInAdmin(congregationSignInForm: CongregationSignInForm) async -> Result<CongregationResponse, Error> {
        let result = await congregationApi.signIn(congregationSignInForm: congregationSignInForm)
        
        if let congregationResponse = try? result.get() {
            authorizationProvider.congregationId = Int64(congregationResponse.id)
            authorizationProvider.congregationPass = congregationSignInForm.password
            dataStore.congregationName = congregationResponse.name
        }
        
        return result
    }
    
    func requestPasswordReset(email: String) async -> Result<Void, Error> {
        return await passwordResetApi.requestReset(email: email)
    }
    
    func resetPassword(password: String, token: String) async -> Result<UserResponse, Error> {
        let result = await passwordResetApi.resetPassword(password: password, token: token)
        
        if let userResponse = try? result.get() { _ = await login(logInForm: LoginForm(email: userResponse.email, password: password)) }
        
        return result
    }
    
    func activateEmail(token: String) async -> Result<Void, Error> {
        return await authenticationApi.activateEmail(token: token)
    }
    
    func deleteAccount() async -> Result<Void, Error> {
        let result = await authenticationApi.deleteAccount()
        
        if result.isSuccess {
            self.dataStore.clear()
            self.authorizationProvider.clear()
        }
        
        SynchronizationManager.shared.startupProcess(synchronizing: true)
        
        return result
    }
    
    @MainActor func exitAdministrator() { AuthorizationLevelManager().exitAdministrator() }
    
    @MainActor func exitPhoneLogin() { AuthorizationLevelManager().exitPhoneLogin() }
    
    func signInPhone(congregationSignInForm: CongregationSignInForm) async -> Result<CongregationResponse, Error> {
        let result = await congregationApi.phoneSignIn(congregationSignInForm: congregationSignInForm)
        
        if let congregationResponse = try? result.get() {
            await authorizationLevelManager.setPhoneCredentials(password: congregationSignInForm.password, congregationResponse: congregationResponse)
            dataStore.phoneCongregationName = congregationResponse.name
        }
        
        return result
        
    }
    
    func editUserName(userName: String) async -> Result<Void, Error> {
        let result = await authenticationApi.editUserName(userName: userName)
        
        if result.isSuccess {
            dataStore.userName = userName
        }
        
        return result
    }
    
    fileprivate func logoutProcess() {
        dataStore.userEmail = nil
        dataStore.passTemp = nil
        dataStore.userName = nil
        dataStore.congregationName = nil
        authorizationProvider.authorizationToken = nil
    }
}
