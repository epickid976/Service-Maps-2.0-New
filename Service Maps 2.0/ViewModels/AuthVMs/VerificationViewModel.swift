//
//  VerificationViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/11/23.
//

import Foundation
import SwiftUI
import Papyrus

// MARK: - Verification View Model

@MainActor
class VerificationViewModel: ObservableObject {
    // MARK: - Dependencies
    
    let authenticationManager = AuthenticationManager()
    @ObservedObject var storageManager = StorageManager.shared
    @ObservedObject var universalLinksManager = UniversalLinksManager.shared
    
    // MARK: - Properties
    
    @Published var showAlert = false {
        didSet {
            DispatchQueue.main.async {
                if !self.showAlert {
                    self.alertTitle = ""
                    self.alertMessage = ""
                }
            }
        }
    }
    @Published  var alertTitle = ""
    @Published  var alertMessage = ""
    
    // MARK: - Check Verification
    func checkVerification(completion: @escaping (Result<Bool, Error>) -> Void) async {
        let result = await authenticationManager.login(logInForm: LoginForm(email: storageManager.userEmail ?? "", password: storageManager.passTemp ?? ""))
        
        switch result {
        case .success:
            completion(Result.success(true))
        case .failure(let error):
            handleVerificationError(error, completion: completion)
        }
    }
    
    private func handleVerificationError(_ error: Error, completion: @escaping (Result<Bool, Error>) -> Void) {
        let errorTitle: String
        let errorMessage: String
        
        // Handle different types of errors
        if let afError = error as? PapyrusError {
            switch afError.response?.statusCode {
            case -1009:
                errorTitle = NSLocalizedString("No Internet Connection", comment: "")
                errorMessage = NSLocalizedString("There was a problem with the internet connection. \nPlease check your internet connection and try again.", comment: "")
                
            case 422:
                errorTitle = NSLocalizedString("Not Verified", comment: "")
                errorMessage = NSLocalizedString("Please check your email and verify your account.", comment: "")
                
            default:
                errorTitle = NSLocalizedString("Error", comment: "")
                errorMessage = NSLocalizedString("Error checking verification status. \nPlease try again.", comment: "")
            }
        } else {
            errorTitle = NSLocalizedString("Error", comment: "")
            errorMessage = NSLocalizedString("An unexpected error occurred. Please try again.", comment: "")
        }
        
        // Display the error
        DispatchQueue.main.async {
            self.alertTitle = errorTitle
            self.alertMessage = errorMessage
            self.showAlert = true
        }
        
        completion(Result.failure(error))
    }
    
    // MARK: - Resend Email
    func resendEmail(completion: @escaping (Result<Bool, Error>) -> Void) async {
        let result = await authenticationManager.resendVerificationEmail()
        
        switch result {
        case .success:
            completion(Result.success(true))
        case .failure(let error):
            handleResendEmailError(error, completion: completion)
        }
    }
    
    private func handleResendEmailError(_ error: Error, completion: @escaping (Result<Bool, Error>) -> Void) {
        let errorTitle: String
        let errorMessage: String
        
        // Handle different types of errors
        if let afError = error as? PapyrusError {
            switch afError.response?.statusCode {
            case -1009:
                errorTitle = NSLocalizedString("No Internet Connection", comment: "")
                errorMessage = NSLocalizedString("There was a problem with the internet connection. \nPlease check your internet connection and try again.", comment: "")
                
            default:
                errorTitle = NSLocalizedString("Error", comment: "")
                errorMessage = NSLocalizedString("There was a problem resending the email. \nPlease try again later.", comment: "")
            }
        } else {
            errorTitle = NSLocalizedString("Error", comment: "")
            errorMessage = NSLocalizedString("An unexpected error occurred. Please try again.", comment: "")
        }
        
        // Display the error
        DispatchQueue.main.async {
            self.alertTitle = errorTitle
            self.alertMessage = errorMessage
            self.showAlert = true
        }
        
        completion(Result.failure(error))
    }
}
