//
//  RecallObject.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/8/24.
//

import Foundation
import RealmSwift

class RecallObject: Object, Identifiable {
    @Persisted(primaryKey: true) var id: Int64
    @Persisted var user: String
    @Persisted var house: String
    
    static func == (lhs: RecallObject, rhs: Recall) -> Bool {
        return lhs.id == rhs.id &&
               lhs.user == rhs.user &&
               lhs.house == rhs.house
      }
    
    func createRecallObject(from model: Recall) -> RecallObject {
      let recallObject = RecallObject()
      recallObject.id = model.id
      recallObject.user = model.user
      recallObject.house = model.house
      return recallObject
    }
    
    func createRecall(from object: RecallObject) -> Recall {
      return Recall(id: object.id, user: object.user, house: object.house, created_at: "", updated_at: "")
    }
    
    func getId() -> String {
        return "\(user)-\(house)"
    }
}
