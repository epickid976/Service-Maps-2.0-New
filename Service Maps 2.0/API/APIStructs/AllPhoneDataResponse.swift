//
//  AllPhoneDataResponse.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/30/24.
//

import Foundation

struct AllPhoneDataResponse: Codable {
    var territories: [PhoneTerritoryModel]
    var numbers: [PhoneNumberModel]
    var calls: [PhoneCallModel]
}
