////
////  PhoneCall.swift
////  Service Maps 2.0
////
////  Created by Jose Blanco on 4/30/24.
////
//
//import Foundation
//Swift
//
//class PhoneCall: Object, Identifiable {
//    @Persisted(primaryKey: true) var id: String
//    @Persisted var phoneNumber: String
//    @Persisted var date: Int64
//    @Persisted var notes: String
//    @Persisted var user: String
//    
//    static func == (lhs: PhoneCall, rhs: PhoneCall) -> Bool {
//        return lhs.id == rhs.id &&
//               lhs.phoneNumber == rhs.phonenumber &&
//               lhs.date == rhs.date &&
//               lhs.notes == rhs.notes && // Match description property name
//               lhs.user == rhs.user
//      }
//    
//    func createTerritoryObject(from model: PhoneCall) -> PhoneCall {
//      let territoryObject = PhoneCall()
//      territoryObject.id = model.id
//      territoryObject.phoneNumber = model.phonenumber
//      territoryObject.date = model.date
//      territoryObject.notes = model.notes  // Match description property name
//      territoryObject.user = model.user
//      return territoryObject
//    }
//}
