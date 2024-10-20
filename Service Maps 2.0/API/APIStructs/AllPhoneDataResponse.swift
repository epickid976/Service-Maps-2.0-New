//
//  AllPhoneDataResponse.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/30/24.
//

import Foundation

struct AllPhoneDataResponse: Codable {
    var territories: [PhoneTerritory]
    var numbers: [PhoneNumber]
    var calls: [PhoneCall]
}
