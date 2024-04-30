//
//  PhoneCallModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/30/24.
//

import Foundation

struct PhoneCallModel: Codable, Equatable, Hashable, Identifiable{
    var id: String
    var phoneNumber: String
    var date: Int64
    var notes: String
    var user: String
    
    static func == (lhs: PhoneCallModel, rhs: PhoneCallModel) -> Bool {
        return lhs.id == rhs.id &&
        lhs.phoneNumber == rhs.phoneNumber &&
        lhs.date == rhs.date &&
        lhs.notes == rhs.notes &&
        lhs.user == rhs.user
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(phoneNumber)
        hasher.combine(date)
        hasher.combine(notes)
        hasher.combine(user)// Combine an empty string for optional floor
      }
}
