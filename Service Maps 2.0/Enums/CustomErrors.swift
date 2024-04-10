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
    
    var localizedDescription: String {
        switch self {
        case .NotFound:
            return "Not Found"
        case .NothingToSave:
            return "No changes to save"
        }
    }
}
