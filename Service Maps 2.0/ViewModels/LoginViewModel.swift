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
    @Published var resetError = false
    @Published var resetFeedbackText = ""
    @Published var passwordError = ""
    
    @Published var loginErrorText = ""
    @Published var loginError = false
    
    
    func validate(forReset: Bool = false) -> Bool {
        
        if !forReset {
            if !self.isValidEmail(self.username) {
                DispatchQueue.main.async {
                    withAnimation {
                        self.loginErrorText =  NSLocalizedString("Not a valid email.", comment: "")
                        self.loginError = true
                    }
                }
                return false
            }
            
            if self.username.contains(" ") {
                DispatchQueue.main.async {
                    withAnimation {
                        self.loginErrorText =  NSLocalizedString("Email cannot contain spaces.", comment: "")
                        self.loginError = true
                    }
                }
                return false
            }
        }
        
        if forReset {
            if self.password.count < 6 {
                DispatchQueue.main.async {
                    withAnimation {
                        self.loginErrorText =  NSLocalizedString("Password must be more than 6 characters.", comment: "")
                        self.loginError = true
                    }
                }
                return false
            }
            
            if self.password != self.username {
                DispatchQueue.main.async {
                    withAnimation {
                        self.loginErrorText =  NSLocalizedString("Passwords must match.", comment: "")
                        self.loginError = true
                    }
                }
                return false
            }
        }
        
        if self.username.isEmpty || self.password.isEmpty {
            DispatchQueue.main.async {
                withAnimation {
                    self.loginErrorText =  NSLocalizedString("Fields cannot be empty", comment: "")
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
                        self.alertTitle =  NSLocalizedString("No Internet Connection", comment: "")
                        self.alertMessage =  NSLocalizedString("There was a problem with the internet connection. \nPlease check your internet connection and try again.", comment: "")
                        self.loading = false
                        self.showAlert = true
                    }
                    completion(Result.failure(error))
                } else if error.asAFError?.responseCode == 401 {
                    DispatchQueue.main.async {
                        self.alertTitle =  NSLocalizedString("Invalid Credentials", comment: "")
                        self.alertMessage =  NSLocalizedString("Email or Password is incorrect. Please try again.", comment: "")
                        self.loading = false
                        self.showAlert = true
                    }
                    completion(Result.failure(error))
                } else {
                    DispatchQueue.main.async {
                        self.alertTitle =  NSLocalizedString("Error", comment: "")
                        self.alertMessage =  NSLocalizedString("Error logging in. \nPlease try again.", comment: "")
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
            HapticManager.shared.trigger(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    UniversalLinksManager.shared.resetLink()
                }
            }
        case .failure(let error):
            HapticManager.shared.trigger(.error)
            if error.asAFError?.responseCode == -1009 || error.asAFError?.responseCode == nil {
                DispatchQueue.main.async {
                    self.loginErrorText =  NSLocalizedString("No Internet Connection. Please try again later.", comment: "")
                }
            } else {
                DispatchQueue.main.async {
                    self.loginErrorText =  NSLocalizedString("Error Resetting Password. Please try again later", comment: "")
                }
            }
            self.loginError = true
            withAnimation { self.loading = false}
        }
    }
}


