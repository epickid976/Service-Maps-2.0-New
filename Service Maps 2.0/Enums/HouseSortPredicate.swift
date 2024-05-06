//
//  HouseSortPredicate.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 5/2/24.
//

import Foundation

enum HouseSortPredicate: CaseIterable {
    case increasing
    case decreasing
}

enum HouseFilterPredicate: String, CaseIterable {
    case normal = "Normal"
    case oddEven = "Odd & Even"
}
