//
//  Symbols.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/25/23.
//

import Foundation
import SwiftUI

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
        case .none: return "uk"
        }
      }
    
    var localizedString: String {
        switch self {
        case .none:
            return NSLocalizedString("uk", comment: "")
        case .NC:
            return NSLocalizedString("NC", comment: "")
        case .NT:
            return NSLocalizedString("NT", comment: "")
        case .O:
            return NSLocalizedString("O", comment: "")
        case .H:
            return NSLocalizedString("H", comment: "")
        case .M:
            return NSLocalizedString("M", comment: "")
        }
    }
    
    static func symbol(localizedString: String) -> Symbols {
                switch localizedString {
                case Symbols.none.localizedString:
                    return .none
                case Symbols.NC.localizedString:
                    return .NC
                case Symbols.NT.localizedString:
                    return .NT
                case Symbols.O.localizedString:
                    return .O
                case Symbols.H.localizedString:
                    return .H
                case Symbols.M.localizedString:
                    return .M
                default:
                    return .none
                }
            }
}
