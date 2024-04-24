//
//  Symbols.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/25/23.
//

import Foundation

enum Symbols: String, CaseIterable, Identifiable {
    var id: Self { self }
    
    case none = "-"
    case NC = "NC"
    case NT = "NT"
    case O = "O"
    case H = "H"
    case M = "M"
    
    var forServer : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .NC: return "nc"
        case .H: return "h"
        case .M: return "m"
        case .O: return "o"
        case .NT: return "nt"
        case .none: return "error none"
        }
      }
}
