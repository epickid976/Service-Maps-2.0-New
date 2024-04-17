//
//  TokenObject.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/15/24.
//

import Foundation
import RealmSwift

class TokenObject: Object, Identifiable {
    @Persisted var id: String
    @Persisted var name: String
    @Persisted var owner: String
    @Persisted var congregation: String
    @Persisted var moderator: Bool
    @Persisted var expire: Int64?
    @Persisted var user: String?
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    static func == (lhs: TokenObject, rhs: MyTokenModel) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.owner == rhs.owner &&
               lhs.congregation == rhs.congregation &&
               lhs.moderator == rhs.moderator &&
               lhs.expire == rhs.expire &&
               lhs.user == rhs.user
      }
    
    func createTokenObject(from model: MyTokenModel) -> TokenObject {
      let tokenObject = TokenObject()
      tokenObject.id = model.id
      tokenObject.name = model.name
      tokenObject.owner = model.owner
      tokenObject.congregation = model.congregation
      tokenObject.moderator = model.moderator
      tokenObject.expire = model.expire
      tokenObject.user = model.user
      return tokenObject
    }
}
