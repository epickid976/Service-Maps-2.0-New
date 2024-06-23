//
//  MyTokenModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation

struct MyTokenModel: Codable, Equatable, Identifiable, Hashable {
    var id: String
    var name: String
    var owner: String
    var congregation: String
    var moderator: Bool
    var expire: Int64?
    var user: String?
    var created_at: String
    var updated_at: String
    
    
    static func == (lhs: MyTokenModel, rhs: MyTokenModel) -> Bool {
        return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.owner == rhs.owner &&
        lhs.congregation == rhs.congregation &&
        lhs.moderator == rhs.moderator &&
        lhs.expire == rhs.expire &&
        lhs.user == rhs.user
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(owner)
        hasher.combine(congregation)
        hasher.combine(moderator)
        hasher.combine(expire ?? 0) // Combine 0 for nil expire value
      }
    
   
}
func convertTokenToMyTokenModel(model: TokenObject) -> MyTokenModel {
    return MyTokenModel(id: model.id, name: model.name, owner: model.owner, congregation: model.congregation, moderator: model.moderator, created_at: "", updated_at: "")
}
