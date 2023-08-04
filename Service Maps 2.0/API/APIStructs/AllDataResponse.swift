//
//  AllDataResponse.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation
import CoreData

struct AllDataResponse: Codable {
    var territories: [TerritoryModel]
    var houses: [HouseModel]
    var visits: [VisitModel]
}
