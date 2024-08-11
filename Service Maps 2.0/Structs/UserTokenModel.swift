//
//  UserTokenModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 6/5/24.
//

import Foundation

struct UserTokenModel: Codable, Equatable, Hashable, Identifiable {
    var id: String
    var token: String
    var userId: String
    var name: String
    var blocked = false
    
    static func == (lhs: UserTokenModel, rhs: UserTokenModel) -> Bool {
        return lhs.token == rhs.token &&
        lhs.userId == rhs.userId &&
        lhs.name == rhs.name &&
        lhs.blocked == rhs.blocked
        
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(token)
        hasher.combine(userId)
        hasher.combine(name)
        hasher.combine(blocked)
      }
}

func convertUserTokenToModel(model: UserTokenObject) -> UserTokenModel {
    return UserTokenModel(id: model.id, token: model.token, userId: model.userId, name: model.name, blocked: model.blocked)
}
