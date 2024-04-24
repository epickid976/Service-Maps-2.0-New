//
//  KeyData.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/22/24.
//

import Foundation

struct KeyData: Hashable, Identifiable {
    var id: UUID
    var key: MyTokenModel
    var territories: [TerritoryModel]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(territories)
    }
    
    static func ==(lhs: KeyData, rhs: KeyData) -> Bool {
        return lhs.key == rhs.key &&
        lhs.territories == rhs.territories
    }
    
    
}
func getShareLink(id: String) -> String {
    let baseUrl = "https://servicemaps.ejvapps.online/"
    return "\(baseUrl)app/registerkey/\(id)"
}
