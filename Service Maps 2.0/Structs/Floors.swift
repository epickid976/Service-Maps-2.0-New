//
//  Floors.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 3/20/25.
//

import Foundation

/// Represents a single floor (i.e. an address) with its knocked date.
/// The knocked date is determined as the date of the 5th most recent visit among the houses for that address,
/// if available.
struct FloorDetail {
    let address: TerritoryAddress
    let knockedDate: Date?
}

/// Aggregates all floor details for a given territory.
struct FloorData {
    let territory: Territory
    let floors: [FloorDetail]
}
