//
//  UserTokenObject.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 6/5/24.
//

import Foundation
import RealmSwift

class UserTokenObject: Object, Identifiable {
    @Persisted var id: String
    @Persisted var token: String
    @Persisted var userId: String
    @Persisted var blocked: Bool
    @Persisted var name: String
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    static func == (lhs: UserTokenObject, rhs: UserTokenModel) -> Bool {
        return lhs.token == rhs.token &&
               lhs.userId == rhs.userId &&
               lhs.name == rhs.name &&
                lhs.blocked == rhs.blocked
      }
    
    func createUserTokenObject(from model: UserTokenModel) -> UserTokenObject {
      let userTokenObject = UserTokenObject()
        userTokenObject.id = model.id
        userTokenObject.token = model.token
        userTokenObject.userId = model.userId
        userTokenObject.name = model.name
        userTokenObject.blocked = model.blocked
      return userTokenObject
    }

}
