//
//  PhoneNumbersData.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 5/1/24.
//

import Foundation

//MARK: - Phone Numbers Data
struct PhoneNumbersData: Hashable, Identifiable {
    var id: UUID
    var phoneNumber: PhoneNumber
    var phoneCall: PhoneCall?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(phoneNumber)
        hasher.combine(phoneCall)
    }
    
    static func ==(lhs: PhoneNumbersData, rhs: PhoneNumbersData) -> Bool {
        return lhs.id == rhs.id &&
        lhs.phoneNumber == rhs.phoneNumber &&
        lhs.phoneCall == rhs.phoneCall
    }
}
