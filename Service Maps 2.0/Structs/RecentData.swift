//
//  RecentData.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 5/13/24.
//

import Foundation

//MARK: - Recent Data
struct RecentTerritoryData: Hashable, Identifiable {
    var id: UUID
    var territory: Territory
    var lastVisit: Visit
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(territory)
        hasher.combine(lastVisit)
    }
    
    static func ==(lhs: RecentTerritoryData, rhs: RecentTerritoryData) -> Bool {
        return lhs.territory == rhs.territory &&
        lhs.lastVisit == rhs.lastVisit
    }
}

//MARK: - Recent Phone Data
struct RecentPhoneData: Hashable, Identifiable {
    var id: UUID
    var territory: PhoneTerritory
    var lastCall: PhoneCall
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(territory)
        hasher.combine(lastCall)
    }
    
    static func ==(lhs: RecentPhoneData, rhs: RecentPhoneData) -> Bool {
        return lhs.territory == rhs.territory &&
        lhs.lastCall == rhs.lastCall
    }
}
