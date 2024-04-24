//
//  Error.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/8/23.
//

import Foundation

enum CustomErrors: Error {
    case NotFound
    case NothingToSave
    case ErrorUploading
    case WrongCredentials
    case NoInternet
    case NoCongregation
    case GenericError
    
    var localizedDescription: String {
        switch self {
        case .NotFound:
            return "Not Found"
        case .NothingToSave:
            return "No changes to save"
        case .ErrorUploading:
            return "Error uploading Info"
        case .WrongCredentials:
            return "Wrong Credentials"
        case .NoInternet:
            return "No Internet"
        case .NoCongregation:
            return "No Congregation"
        case .GenericError:
            return "ERROR ERROR"
        }
    }
}
