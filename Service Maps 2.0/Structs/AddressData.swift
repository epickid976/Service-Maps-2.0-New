//
//  AddressData.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/17/24.
//

import Foundation

//MARK: - Address Data
struct AddressData: Hashable, Identifiable {
    var id: UUID
    var address: TerritoryAddress
    var houseQuantity: Int
    var accessLevel: AccessLevel
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(address)
        hasher.combine(houseQuantity)
        hasher.combine(accessLevel)
    }
    
    static func ==(lhs: AddressData, rhs: AddressData) -> Bool {
        return lhs.address == rhs.address &&
        lhs.houseQuantity == rhs.houseQuantity &&
        lhs.accessLevel == rhs.accessLevel
    }
}
