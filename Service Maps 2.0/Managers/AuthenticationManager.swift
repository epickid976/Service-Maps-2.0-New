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
    private var authenticationApi = AuthenticationAPI()
    private var congregationApi = CongregationAPI()
    private var passwordResetApi = PasswordResetAPI()
    private var dataStore = StorageManager.shared
    
    func signUp(signUpForm: SignUpForm) async -> Result<Bool, Error> {
        do {
            try await authenticationApi.signUp(name: signUpForm.name, email: signUpForm.email, password: signUpForm.password)
            
            dataStore.userName = signUpForm.name
            dataStore.userEmail = signUpForm.email
            dataStore.passTemp = signUpForm.password
            
            return Result.success(true)
            
        } catch {
            return Result.failure(error)
        }
    }
    
    func login(logInForm: LoginForm) async -> Result<LoginResponse, Error> {
        do {
            let loginResponse = try await authenticationApi.login(email: logInForm.email, password: logInForm.password)
            
            dataStore.passTemp = nil
            authorizationProvider.authorizationToken = loginResponse.access_token
            
            _ = await getUser()
            
            return Result.success(loginResponse)
            
        } catch {
            return Result.failure(error)
        }
    }
    
    func getUser() async -> Result<UserResponse, Error> {
        do {
            let userResponse = try await authenticationApi.user()
            
            DispatchQueue.main.async {
                self.dataStore.userEmail = userResponse.email
                self.dataStore.userName = userResponse.name
            }
            
            return Result.success(userResponse)
            
        } catch {
            print(error.self)
            return Result.failure(error)
        }
    }
    
    func logout() async -> Result<Bool, Error> {
        do {
            _ = try await authenticationApi.logout()
            dataStore.userEmail = nil
            dataStore.passTemp = nil
            dataStore.userName = nil
            dataStore.congregationName = nil
           authorizationProvider.authorizationToken = nil
            
            return Result.success(true)
        } catch {
            return Result.failure(error)
        }
    }
    
    func resendVerificationEmail() async -> Result<Bool, Error> {
        
        if let userEmail = dataStore.userEmail {
            return await authenticationApi.resendEmailValidation(email: userEmail)
        } else {
            return Result.failure(CustomErrors.NotFound)
        }
    }
    
    func signInAdmin(congregationSignInForm: CongregationSignInForm) async -> Result<CongregationResponse, Error> {
        do {
            let congregationResponse = try await congregationApi.signIn(congregationId: congregationSignInForm.id, congregationPass: congregationSignInForm.password)
            
            authorizationProvider.congregationId = Int64(congregationResponse.id)
            authorizationProvider.congregationPass = congregationSignInForm.password
            dataStore.congregationName = congregationResponse.name
            
            return Result.success(congregationResponse)
            
        } catch {
            if error.asAFError?.responseCode == -1009 || error.asAFError?.responseCode == nil {
                return Result.failure(CustomErrors.NoInternet)
            } else if error.asAFError?.responseCode == 401 {
                return Result.failure(CustomErrors.WrongCredentials)
            } else if error.asAFError?.responseCode == 404 {
                return Result.failure(CustomErrors.NoCongregation)
            } else {
                return Result.failure(error)
            }
        }
    }
    
    
    func requestPasswordReset(email: String) async -> Result<Bool, Error> {
        do {
            _ = try await passwordResetApi.requestReset(email: email)
            
            return Result.success(true)
        } catch {
            return Result.failure(error)
        }
        
    }
    
    func resetPassword(email: String, password: String, token: String) async -> Result<UserResponse, Error> {
        do {
            let userResponse = try await passwordResetApi.resetPassword(email: email, password: password, token: token)
            
            _ = await login(logInForm: LoginForm(email: email, password: password))
            
            return Result.success(userResponse)
            
        } catch {
            return Result.failure(error)
        }
    }
    
    func activateEmail(token: String) async -> Result<Bool, Error> {
        return await authenticationApi.activateEmail(token: token)
    }
    
    func deleteAccount() async -> Result<Bool, Error> {
        var result = await authenticationApi.deleteAccount()
        
        switch result {
        case .success(true):
            dataStore.clear()
            authorizationProvider.clear()
        default:
            print("delete account entered default")
        }
        
        return result
    }
    
    func exitAdministrator() {
        AuthorizationLevelManager().exitAdministrator()
    }
}
