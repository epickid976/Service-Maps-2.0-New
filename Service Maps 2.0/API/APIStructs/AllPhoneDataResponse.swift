//
//  AllPhoneDataResponse.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/30/24.
//

import Foundation

// MARK: - All Phone Data Response
public struct AllPhoneDataResponse: Codable, Sendable {
    var territories: [PhoneTerritory]
    var numbers: [PhoneNumber]
    var calls: [PhoneCall]
}
