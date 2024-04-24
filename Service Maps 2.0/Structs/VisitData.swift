//
//  VisitData.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/21/24.
//

import Foundation

struct VisitData: Hashable, Identifiable {
    var id: UUID
    var visit: VisitModel
    var accessLevel: AccessLevel?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(visit)
        hasher.combine(accessLevel)
    }
    
    static func ==(lhs: VisitData, rhs: VisitData) -> Bool {
        return lhs.visit == rhs.visit &&
        lhs.accessLevel == rhs.accessLevel
    }
}
