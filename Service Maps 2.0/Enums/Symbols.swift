//
//  Symbols.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/25/23.
//

import Foundation
import SwiftUI

// MARK: - Symbols
enum Symbols: String, CaseIterable, Identifiable {
    var id: Self { self }
    
    case none = "-"
    case NC = "NC"
    case NT = "NT"
    case O = "O"
    case H = "H"
    case M = "M"
    case N = "N"
    case V = "V"
    case OV = "OV"
    case MV = "MV"
    case HV = "HV"
    
    // MARK: - Server Mapping
    var forServer : String {
        switch self {
            // Use Internationalization, as appropriate.
        case .NC: return "nc"
        case .H: return "h"
        case .M: return "m"
        case .O: return "o"
        case .NT: return "nt"
        case .N: return "n"
        case .V: return "v"
        case .OV: return "ov"
        case .MV: return "mv"
        case .HV: return "hv"
        case .none: return "uk"
        }
    }
    
    static func fromServer(raw: String) -> Symbols {
        switch raw {
        case "nc": return .NC
        case "nt": return .NT
        case "o": return .O
        case "h": return .H
        case "m": return .M
        case "n": return .N
        case "v": return .V
        case "ov": return .OV
        case "mv": return .MV
        case "hv": return .HV
        case "uk", "": return .none
        default: return .none
        }
    }
    
    // MARK: - Legend
    var legend: String {
        switch self {
        case .none:
            return NSLocalizedString("", comment: "")
        case .NC:
            return NSLocalizedString("No en casa", comment: "")
        case .NT:
            return NSLocalizedString("No Tocar", comment: "")
        case .O:
            return NSLocalizedString("Ocupado", comment: "")
        case .H:
            return NSLocalizedString("Hombre", comment: "")
        case .M:
            return NSLocalizedString("Mujer", comment: "")
        case .N:
            return NSLocalizedString("Niño", comment: "")
        case .V:
            return NSLocalizedString("Volver", comment: "")
        case .OV:
            return NSLocalizedString("Ocupado Volver", comment: "")
        case .MV:
            return NSLocalizedString("Mujer Volver", comment: "")
        case .HV:
            return NSLocalizedString("Hombre Volver", comment: "")
        }
    }
    
    // MARK: - Localization
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
        case .N:
            return NSLocalizedString("N", comment: "")
        case .V:
            return NSLocalizedString("V", comment: "")
        case .OV:
            return NSLocalizedString("OV", comment: "")
        case .MV:
            return NSLocalizedString("MV", comment: "")
        case .HV:
            return NSLocalizedString("HV", comment: "")
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
        case Symbols.N.localizedString:
            return .N
        case Symbols.V.localizedString:
            return .V
        case Symbols.OV.localizedString:
            return .OV
        case Symbols.MV.localizedString:
            return .MV
        case Symbols.HV.localizedString:
            return .HV
        default:
            return .none
        }
    }
}
