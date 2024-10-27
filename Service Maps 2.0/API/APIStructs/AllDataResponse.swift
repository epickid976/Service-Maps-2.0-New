//
//  AllDataResponse.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation
import CoreData

public struct AllDataResponse: Codable, Sendable {
    var territories: [Territory]
    var addresses: [TerritoryAddress]
    var houses: [House]
    var visits: [Visit]
}
