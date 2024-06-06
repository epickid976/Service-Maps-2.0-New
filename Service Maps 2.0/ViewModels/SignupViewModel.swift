//
//  SignupViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/9/23.
//

import Foundation
import SwiftUI

@MainActor
class SignupViewModel: ObservableObject {
    
    //ENVIRONMENT
    @Environment(\.colorScheme) var colorScheme
    
    // API
    var authenticationManager = AuthenticationManager()
    let authorizationProvider = AuthorizationProvider.shared
    let storageManager = StorageManager.shared
    
    // Input properties
    @Published var name: String = ""
    @Published var lastName: String = ""
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var passwordConfirmation: String = ""
    
    
    @State var loading = false
    
    // Output properties
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
    
    func validate() -> Bool {
        
        if self.username.isEmpty || self.password.isEmpty || self.name.isEmpty || self.lastName.isEmpty || self.passwordConfirmation.isEmpty {
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
        
        if self.password.count < 8 {
            DispatchQueue.main.async {
                withAnimation {
                    self.loginErrorText =  NSLocalizedString("Password must be more than 8 characters.", comment: "")
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
    
    // Signup function
    func signUp(completion: @escaping (Result<Bool, Error>) -> Void) async {
        Task {
            let result = await authenticationManager.signUp(signUpForm: SignUpForm(name: "\(name) \(lastName)", email: username, password: password, password_confirmation: password))
            
            
            switch result {
            case .success(_):
                DispatchQueue.main.async { // Update properties on the main thread
                    withAnimation { self.loading = false
                        // Handle success case
                        completion(Result.success(true))
                    }
                }
            case .failure(let error):
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
                } else if error.asAFError?.responseCode == 422 {
                    DispatchQueue.main.async {
                        self.alertTitle =  NSLocalizedString("Email Taken", comment: "")
                        self.alertMessage =  NSLocalizedString("It seems this email is taken. Try logging in.", comment: "")
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
            return completion(Result.success(true))
        }
    }
}

