//
//  LoginViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/8/23.
//

import Foundation
import SwiftUI
import Papyrus

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
    
    @Published var goToLoginView = false
    
    @Published var emailSent = false
    @Published var errorEmailSent = false
    
    
    
    func validate(forReset: Bool = false) -> Bool {
        self.username = self.username.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
        
        if !forReset {
            guard self.isValidEmail(self.username) else {
                showError(NSLocalizedString("Not a valid email.", comment: ""))
                return false
            }
            
            guard !self.username.contains(" ") else {
                showError(NSLocalizedString("Email cannot contain spaces.", comment: ""))
                return false
            }
        }
        
        if forReset {
            guard self.password.count >= 6 else {
                showError(NSLocalizedString("Password must be more than 6 characters.", comment: ""))
                return false
            }
            
            guard self.password == self.username else {
                showError(NSLocalizedString("Passwords must match.", comment: ""))
                return false
            }
        }
        
        guard !self.username.isEmpty && !self.password.isEmpty else {
            showError(NSLocalizedString("Fields cannot be empty", comment: ""))
            return false
        }
        
        return true
    }

    private func showError(_ message: String) {
        DispatchQueue.main.async {
            withAnimation {
                self.loginErrorText = message
                self.loginError = true
            }
        }
    }
    
    func validateForEmailLogin() -> Bool {
        guard isValidEmail(self.username) else {
            showError(NSLocalizedString("Not a valid email.", comment: ""))
            return false
        }
        
        guard !self.username.contains(" ") else {
            showError(NSLocalizedString("Email cannot contain spaces.", comment: ""))
            return false
        }
        
        return true
    }

    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }
    
    
    func login() async -> Result<Void, Error> {
        // Ensure both username and password are non-empty
        guard !username.isEmpty, !password.isEmpty else {
            DispatchQueue.main.async {
                self.showAlert(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Fields cannot be empty", comment: ""))
            }
            return .failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Fields cannot be empty"]))
        }

        // Start loading animation
        DispatchQueue.main.async { withAnimation { self.loading = true } }

        // Perform login using Papyrus
        let result = await self.authenticationManager.login(logInForm: LoginForm(email: self.username, password: self.password))

        // Stop loading animation
        DispatchQueue.main.async {
            withAnimation { self.loading = false }
        }

        // Handle login result
        switch result {
        case .success:
            DispatchQueue.main.async {
                self.loginErrorText = ""
            }
            return .success(())

        case .failure(let error):
            DispatchQueue.main.async {
                self.handleLoginError(error)
            }
            return .failure(error)
        }
    }

    private func handleLoginError(_ error: Error) {
        let errorMessage: String
        let errorTitle: String

        // Handle different types of Papyrus errors
        if let papyrusError = error as? PapyrusError {
            switch papyrusError.response?.statusCode {
            case -1099:
                errorTitle = NSLocalizedString("No Internet Connection", comment: "")
                errorMessage = NSLocalizedString("There was a problem with the internet connection. \nPlease check your internet connection and try again.", comment: "")
                
            case 401:
                errorTitle = NSLocalizedString("Invalid Credentials", comment: "")
                errorMessage = NSLocalizedString("Email or Password is incorrect. Please try again.", comment: "")
                
            default:
                errorTitle = NSLocalizedString("Error", comment: "")
                errorMessage = NSLocalizedString("Error logging in. \nPlease try again.", comment: "")
            }
        } else {
            // Fallback for any other error types
            errorTitle = NSLocalizedString("Error", comment: "")
            errorMessage = NSLocalizedString("An unexpected error occurred. Please try again.", comment: "")
        }

        // Show the alert
        showAlert(title: errorTitle, message: errorMessage)
    }

    private func showAlert(title: String, message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.showAlert = true
    }
    
    // Function to send login email
    func sendLoginEmail() async {
        if validateForEmailLogin() {
            DispatchQueue.main.async { withAnimation { self.loading = true } }

            let result = await authenticationManager.loginEmail(email: self.username)
            DispatchQueue.main.async { withAnimation { self.loading = false } }

            switch result {
            case .success:
                HapticManager.shared.trigger(.success)
                DispatchQueue.main.async {
                    self.loginErrorText = ""
                    self.loginError = false
                    self.emailSent = true
                    UniversalLinksManager.shared.resetLink()
                }
            case .failure(let error):
                HapticManager.shared.trigger(.error)
                DispatchQueue.main.async {
                    self.handleLoginError(error)
                }
                self.loginError = true
                self.errorEmailSent = true
            }
        }
    }

    // Function to login with email token
    func loginWithEmail(token: String) async {
        DispatchQueue.main.async { withAnimation { self.loading = true } }

        let result = await authenticationManager.loginEmailToken(token: token)
        DispatchQueue.main.async { withAnimation { self.loading = false } }

        switch result {
        case .success:
            HapticManager.shared.trigger(.success)
            DispatchQueue.main.async {
                self.loginErrorText = ""
                self.loginError = false
                UniversalLinksManager.shared.resetLink()
            }
        case .failure(let error):
            HapticManager.shared.trigger(.error)
            DispatchQueue.main.async {
                self.handleLoginError(error)
            }
            self.loginError = true
        }
    }

    // Function to reset password
    func resetPassword(password: String, token: String) async {
        let result = await authenticationManager.resetPassword(password: password, token: token)

        switch result {
        case .success:
            HapticManager.shared.trigger(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    UniversalLinksManager.shared.resetLink()
                }
            }
        case .failure(let error):
            HapticManager.shared.trigger(.error)
            DispatchQueue.main.async {
                self.handleLoginError(error)
            }
            self.loginError = true
        }
    }
}


