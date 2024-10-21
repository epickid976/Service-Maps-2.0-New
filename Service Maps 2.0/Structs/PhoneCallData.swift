//
//  PhoneCallData.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 5/1/24.
//

import Foundation

struct PhoneCallData: Hashable, Identifiable {
    var id: UUID
    var phoneCall: PhoneCall
    var accessLevel: AccessLevel?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(phoneCall)
        hasher.combine(accessLevel)
    }
    
    static func ==(lhs: PhoneCallData, rhs: PhoneCallData) -> Bool {
        return lhs.id == rhs.id &&
        lhs.phoneCall == rhs.phoneCall &&
        lhs.accessLevel == rhs.accessLevel
    }
}
