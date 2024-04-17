//
//  VerificationViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/11/23.
//

import Foundation
import SwiftUI

@MainActor
class VerificationViewModel: ObservableObject {
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
    
    //MARK: API
    let authenticationManager = AuthenticationManager()
    @ObservedObject var storageManager = StorageManager.shared
    
    
    func checkVerification(completion: @escaping (Result<Bool, Error>) -> Void) async {
        
        let result = await authenticationManager.login(logInForm: LoginForm(email: storageManager.userEmail ?? "", password: storageManager.passTemp ?? ""))
        
        switch result {
        case .success(_):
            completion(Result.success(true))
        case .failure(let error):
            if error.asAFError?.responseCode == -1009 || error.asAFError?.responseCode == nil {
                DispatchQueue.main.async {
                    self.alertTitle = "No Internet Connection"
                    self.alertMessage = "There was a problem with the internet connection. \nPlease check your internet connection and try again."
                    self.showAlert = true
                }
                completion(Result.failure(error))
            } else if error.asAFError?.responseCode == 422 {
                DispatchQueue.main.async {
                    self.alertTitle = "Not Verified"
                    self.alertMessage = "Please check your email and verify your account."
                    self.showAlert = true
                }
                completion(Result.failure(error))
            } else {
                DispatchQueue.main.async {
                    self.alertTitle = "Error"
                    self.alertMessage = "Error checking verification status. \nPlease try again."
                    self.showAlert = true
                }
                completion(Result.failure(error))
            }
        }
    }
    
    func resendEmail(completion: @escaping (Result<Bool, Error>) -> Void) async {
        let result = await authenticationManager.resendVerificationEmail()
        
        switch result {
        case .success(_):
            completion(Result.success(true))
        case .failure(let error):
            if error.asAFError?.responseCode == -1009 || error.asAFError?.responseCode == nil {
                DispatchQueue.main.async {
                    self.alertTitle = "No Internet Connection"
                    self.alertMessage = "There was a problem with the internet connection. \nPlease check your internet connection and try again."
                    self.showAlert = true
                }
                completion(Result.failure(error))
            } else {
                DispatchQueue.main.async {
                    self.alertTitle = "Error"
                    self.alertMessage = "There was a problem resending the email. \nPlease try again later."
                    self.showAlert = true
                }
                completion(Result.failure(error))
            }
        }
    }
    
}
