//
//  PhoneData.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/30/24.
//

import Foundation

//MARK: - Phone Data
struct PhoneData: Hashable, Identifiable {
    var id: UUID
    var territory: PhoneTerritory
    var numbersQuantity: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(territory)
        hasher.combine(numbersQuantity)
    }
    
    static func ==(lhs: PhoneData, rhs: PhoneData) -> Bool {
        return lhs.id == rhs.id &&
        lhs.territory == rhs.territory &&
        lhs.numbersQuantity == rhs.numbersQuantity
    }
}
