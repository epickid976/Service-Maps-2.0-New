//
//  UniversalLinksManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/25/24.
//

import Foundation
import SwiftUI

//MARK: - Universal Links Manager

@MainActor
class UniversalLinksManager: ObservableObject {
    //MARK: - Properties
    static let shared = UniversalLinksManager()
    @Published var linkState: LinkScreens? = nil
    @Published var dataFromUrl: String? = nil
    
    //MARK: - Handle URL
    func handleIncomingURL(_ url: URL) {
        guard let host = url.host, host == "servicemaps.ejvapps.online" else {
            return // Ignore URLs with a different host
          }
        

      // Check for specific deep link patterns based on your constants

        if url.absoluteString.starts(with: LinkScreens.VALIDATE_EMAIL.rawValue) {
        // Handle account confirmation
        
            linkState = .VALIDATE_EMAIL
            
        // Extract confirmation token from URL (logic depends on your URL structure)
        // Navigate to confirmation view with the token (your implementation)
      } else if url.absoluteString.starts(with: LinkScreens.REGISTER_KEY.rawValue) {
        // Handle registration key link
        
          linkState = .REGISTER_KEY
        // Extract registration key from URL (logic depends on your URL structure)
        // Navigate to registration view with the key (your implementation)
      } else if url.absoluteString.starts(with: LinkScreens.RESET_PASSWORD.rawValue) {
        // Handle password reset link
        
          
          linkState = .RESET_PASSWORD
          
        // Extract password reset token from URL (logic depends on your URL structure)
        // Navigate to password reset view with the token (your implementation)
      } else if url.absoluteString.starts(with: LinkScreens.PRIVACY_POLICY.rawValue) {
          // Handle privacy policy link
          
          linkState = .PRIVACY_POLICY
          // Navigate to privacy policy view (your implementation)
      } else if url.absoluteString.starts(with: LinkScreens.LOGIN_EMAIL.rawValue) {
          // Handle login email link
          
          linkState = .LOGIN_EMAIL
          // Navigate to login email view (your implementation)
      } else {
        
          linkState = nil
      }
        
        dataFromUrl = extractFromURL(urlString: url.absoluteString)
    }
    
    func extractFromURL(urlString: String, after separator: String = "/") -> String? {
       let components = urlString.components(separatedBy: separator)
      return components.last // Assuming the desired content is the last component
    }
    
    //MARK: - Determine Destination
    func determineDestination() -> DestinationEnum? {
        switch linkState {
        case .VALIDATE_EMAIL:
            return .ActivateEmail
        case .REGISTER_KEY:
            return .RegisterKeyView
        case .RESET_PASSWORD:
            return .ResetPasswordView
        case .PRIVACY_POLICY:
            return .PrivacyPolicyView
        case .LOGIN_EMAIL:
            return .loginWithEmailView
        default:
            return nil
        }
    }
    
    //MARK: - Reset
    func resetLink() {
        linkState = nil
        dataFromUrl = nil
    }
}
