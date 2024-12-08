//
//  HouseSortPredicate.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 5/2/24.
//

import Foundation

// MARK: - House Sort Predicates
enum HouseSortPredicate: String, CaseIterable {
    case increasing = "Increasing"
    case decreasing = "Decreasing"
    
    var localized: String {
        switch self {
        case .increasing:
            return NSLocalizedString("Increasing", comment: "")
        case .decreasing:
            return NSLocalizedString("Decreasing", comment: "")
        }
    }
}

// MARK: - House Filter Predicates
enum HouseFilterPredicate: String, CaseIterable {
    case normal = "Normal"
    case oddEven = "Odd & Even"
    
    var localized: String {
        switch self {
        case .normal:
            return NSLocalizedString("Normal", comment: "")
        case .oddEven:
            return NSLocalizedString("Odd & Even", comment: "")
        }
    }
}
