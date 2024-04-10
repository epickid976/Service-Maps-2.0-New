//
//  Error.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/8/23.
//

import Foundation

enum CustomErrors: Error {
    case NotFound
    case
    
    var localizedDescription: String {
        switch self {
        case .NotFound:
            return "Not Found"
        }
    }
}
