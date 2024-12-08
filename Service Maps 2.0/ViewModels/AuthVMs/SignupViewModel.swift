//
//  SignupViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/9/23.
//

import Foundation
import SwiftUI
import Papyrus

// MARK: - Signup View Model

@MainActor
class SignupViewModel: ObservableObject {
    
    // MARK: - Environment
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Dependencies
    var authenticationManager = AuthenticationManager()
    let authorizationProvider = AuthorizationProvider.shared
    let storageManager = StorageManager.shared
    
    // MARK: - Properties
    @Published var name: String = ""
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var passwordConfirmation: String = ""
    
    @State var loading = false
    
    
    @Published var usernameError = ""
    @Published var passwordError = ""
    
    @Published var showAlert = false {
        didSet {
            if !showAlert {
                alertTitle = ""
                alertMessage = ""
            }
        }
    }
    
    @Published  var alertTitle = ""
    @Published  var alertMessage = ""
    
    @Published var loginErrorText = ""
    @Published var loginError = false
    
    // MARK: - Validate
    
    func validate() -> Bool {
        
        if self.username.isEmpty || self.password.isEmpty || self.name.isEmpty || self.passwordConfirmation.isEmpty {
            DispatchQueue.main.async {
                withAnimation {
                    self.loginErrorText = NSLocalizedString("Fields cannot be empty", comment: "")
                    self.loginError = true
                }
            }
            return false
        }
        
        if self.password != self.passwordConfirmation {
            DispatchQueue.main.async {
                withAnimation {
                    self.loginErrorText =  NSLocalizedString("Passwords must match.", comment: "")
                    self.loginError = true
                }
            }
            return false
        }
        
        if self.password.count < 6 {
            DispatchQueue.main.async {
                withAnimation {
                    self.loginErrorText =  NSLocalizedString("Password must be more than 6 characters.", comment: "")
                    self.loginError = true
                }
            }
            return false
        }
        
        
        
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
        return true
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    // MARK: - Signup
    // Signup function
    func signUp(completion: @escaping (Result<Bool, Error>) -> Void) async {
        Task {
            let result = await authenticationManager.signUp(signUpForm: SignUpForm(name: "\(name)", email: username, password: password, password_confirmation: password))
            
            switch result {
            case .success:
                DispatchQueue.main.async {
                    withAnimation {
                        self.loading = false
                        completion(.success(true))
                    }
                }
            case .failure(let error):
                handleSignUpError(error, completion: completion)
            }
        }
    }

    private func handleSignUpError(_ error: Error, completion: @escaping (Result<Bool, Error>) -> Void) {
        let errorTitle: String
        let errorMessage: String
        
        if let afError = error as? PapyrusError {
            switch afError.response?.statusCode {
            case -1009:
                errorTitle = NSLocalizedString("No Internet Connection", comment: "")
                errorMessage = NSLocalizedString("There was a problem with the internet connection. \nPlease check your internet connection and try again.", comment: "")
                
            case 401:
                errorTitle = NSLocalizedString("Invalid Credentials", comment: "")
                errorMessage = NSLocalizedString("Email or Password is incorrect. Please try again.", comment: "")
                
            case 422:
                errorTitle = NSLocalizedString("Email Taken", comment: "")
                errorMessage = NSLocalizedString("It seems this email is taken. Try logging in.", comment: "")
                
            default:
                errorTitle = NSLocalizedString("Error", comment: "")
                errorMessage = NSLocalizedString("Error signing up. \nPlease try again.", comment: "")
            }
        } else {
            errorTitle = NSLocalizedString("Error", comment: "")
            errorMessage = NSLocalizedString("An unexpected error occurred. Please try again.", comment: "")
        }
        
        // Show the error alert
        DispatchQueue.main.async {
            self.alertTitle = errorTitle
            self.alertMessage = errorMessage
            self.loading = false
            self.showAlert = true
        }
        
        completion(.failure(error))
    }
}

