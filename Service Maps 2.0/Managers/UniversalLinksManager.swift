//
//  UniversalLinksManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/25/24.
//

import Foundation

class UniversalLinksManager: ObservableObject {
    
    @Published var linkState: LinkScreens? = nil
    @Published var dataFromUrl: String? = nil
    
    func handleIncomingURL(_ url: URL) {
        guard let host = url.host, host == "servicemaps.ejvapps.online" else {
            return // Ignore URLs with a different host
          }
        

      // Check for specific deep link patterns based on your constants

        if url.absoluteString.starts(with: LinkScreens.VALIDATE_EMAIL.rawValue) {
        // Handle account confirmation
        print("Confirmation link received, extract token from URL")
            linkState = .VALIDATE_EMAIL
            
        // Extract confirmation token from URL (logic depends on your URL structure)
        // Navigate to confirmation view with the token (your implementation)
      } else if url.absoluteString.starts(with: LinkScreens.REGISTER_KEY.rawValue) {
        // Handle registration key link
        print("Registration key link received, extract key from URL")
          linkState = .REGISTER_KEY
        // Extract registration key from URL (logic depends on your URL structure)
        // Navigate to registration view with the key (your implementation)
      } else if url.absoluteString.starts(with: LinkScreens.RESET_PASSWORD.rawValue) {
        // Handle password reset link
        print("Password reset link received, extract token from URL")
          linkState = .RESET_PASSWORD
        // Extract password reset token from URL (logic depends on your URL structure)
        // Navigate to password reset view with the token (your implementation)
      } else if url.absoluteString.starts(with: LinkScreens.PRIVACY_POLICY.rawValue) {
        // Handle privacy policy link
        print("Privacy policy link received")
          linkState = .PRIVACY_POLICY
        // Navigate to privacy policy view (your implementation)
      } else {
        print("Unknown URL, we can't handle this one!")
          linkState = nil
      }
        
        dataFromUrl = extractFromURL(urlString: url.absoluteString)
    }
    
    func extractFromURL(urlString: String, after separator: String = "/") -> String? {
       let components = urlString.components(separatedBy: separator)
      return components.last // Assuming the desired content is the last component
    }
    
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
        default:
            return nil
        }
    }
    
    func resetLink() {
        linkState = nil
        dataFromUrl = nil
    }

        
    class var shared: UniversalLinksManager {
        struct Static {
            static let instance = UniversalLinksManager()
        }
        
        return Static.instance
    }
}
