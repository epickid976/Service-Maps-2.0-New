//
//  Recall.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/8/24.
//

import Foundation

struct Recall: Codable, Hashable, Identifiable {
    var id: Int64
    var user: String
    var house: String
    var created_at: String
    var updated_at: String
    
    func getId() -> String {
        return "\(user)-\(house)"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(user)
        hasher.combine(house)
    }
    
    static func ==(lhs: Recall, rhs: Recall) -> Bool {
        return lhs.user == rhs.user &&
        lhs.house == rhs.house
    }
}
