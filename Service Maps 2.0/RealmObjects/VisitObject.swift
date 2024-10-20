////
////  Visit.swift
////  Service Maps 2.0
////
////  Created by Jose Blanco on 4/15/24.
////
//
//import Foundation
//Swift
//
//class Visit: Object, Identifiable {
//    @Persisted(primaryKey: true) var id: String
//    @Persisted var house: String
//    @Persisted var date: Int64
//    @Persisted var symbol: String
//    @Persisted var notes: String
//    @Persisted var user: String
//
//    static func == (lhs: Visit, rhs: Visit) -> Bool {
//        return lhs.id == rhs.id &&
//               lhs.house == rhs.house &&
//               lhs.date == rhs.date &&
//               lhs.symbol == rhs.symbol &&
//               lhs.notes == rhs.notes &&
//               lhs.user == rhs.user
//      }
//    
//    func createVisitObject(from model: Visit) -> Visit {
//      let visitObject = Visit()
//      visitObject.id = model.id
//      visitObject.house = model.house
//      visitObject.date = model.date
//      visitObject.symbol = model.symbol
//      visitObject.notes = model.notes
//      visitObject.user = model.user
//      return visitObject
//    }
//
//}
