//
//  LoginViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/8/23.
//

import Foundation
import SwiftUI

@MainActor
class LoginViewModel: ObservableObject {
    var authenticationManager = AuthenticationManager()
    
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
        self.loading = false
        self.showAlert = false
        self.alertTitle = ""
        self.alertMessage = ""
    }
    
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var loading = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    @Published var resetFeedback = false
    @Published var resetFeedbackText = ""
    @Published var passwordError = ""
    
    @Published var loginErrorText = ""
    @Published var loginError = false
    
    
    func validate(forReset: Bool = false) -> Bool {
        
        if !forReset {
            if !self.isValidEmail(self.username) {
                DispatchQueue.main.async {
                    withAnimation {
                        self.loginErrorText = "Not a valid email."
                        self.loginError = true
                    }
                }
                return false
            }
            
            if self.username.contains(" ") {
                DispatchQueue.main.async {
                    withAnimation {
                        self.loginErrorText = "Email cannot contain spaces."
                        self.loginError = true
                    }
                }
                return false
            }
        }
        
        if forReset {
            if self.password.count < 8 {
                DispatchQueue.main.async {
                    withAnimation {
                        self.loginErrorText = "Password must be more than 8 characters."
                        self.loginError = true
                    }
                }
                return false
            }
            
            if self.password != self.username {
                DispatchQueue.main.async {
                    withAnimation {
                        self.loginErrorText = "Passwords must match."
                        self.loginError = true
                    }
                }
                return false
            }
        }
        
        if self.username.isEmpty || self.password.isEmpty {
            DispatchQueue.main.async {
                withAnimation {
                    self.loginErrorText = "Fields cannot be empty"
                    self.loginError = true
                }
            }
            return false
        }
        
        
        return true
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    
    func login(completion: @escaping (Result<Bool, Error>) -> Void) async {
        
        if !username.isEmpty && !password.isEmpty {
            
            DispatchQueue.main.async { withAnimation { self.loading = true } }
            
            let result = await self.authenticationManager.login(logInForm: LoginForm(email: self.username, password: self.password))
            
            switch result {
            case .success(_):
                DispatchQueue.main.async { // Update properties on the main thread
                    withAnimation { self.loading = false; self.loginErrorText = "" }
                }
                completion(Result.success(true))
            case .failure(let error):
                // Handle any errors here
                print(error.asAFError?.responseCode ?? "")
                print(error.asAFError?.errorDescription ?? "")
                print(error.asAFError?.failureReason ?? "")
                print(error.asAFError?.url ?? "")
                print(error.localizedDescription)
                if error.asAFError?.responseCode == -1009 || error.asAFError?.responseCode == nil {
                    DispatchQueue.main.async {
                        self.alertTitle = "No Internet Connection"
                        self.alertMessage = "There was a problem with the internet connection. \nPlease check your internet connection and try again."
                        self.loading = false
                        self.showAlert = true
                    }
                    completion(Result.failure(error))
                } else if error.asAFError?.responseCode == 401 {
                    DispatchQueue.main.async {
                        self.alertTitle = "Invalid Credentials"
                        self.alertMessage = "Email or Password is incorrect. Please try again."
                        self.loading = false
                        self.showAlert = true
                    }
                    completion(Result.failure(error))
                } else {
                    DispatchQueue.main.async {
                        self.alertTitle = "Error"
                        self.alertMessage = "Error logging in. \nPlease try again."
                        self.loading = false
                        self.showAlert = true
                    }
                    completion(Result.failure(error))
                }
            }
        }
    }
    
    func resetPassword(password: String, token: String ) async {
        switch await authenticationManager.resetPassword( password: password, token: token) {
        case .success(_):
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    UniversalLinksManager.shared.resetLink()
                }
            }
        case .failure(let error):
            if error.asAFError?.responseCode == -1009 || error.asAFError?.responseCode == nil {
                DispatchQueue.main.async {
                    self.loginErrorText = "No Internet Connection. Please try again later."
                }
            } else {
                DispatchQueue.main.async {
                    self.loginErrorText = "Error Resetting Password. Please try again later"
                }
            }
            self.loginError = true
            withAnimation { self.loading = false}
        }
    }
}


