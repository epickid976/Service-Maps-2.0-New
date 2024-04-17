//
//  VisitModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation

struct VisitModel: Codable, Equatable, Hashable, Identifiable {
    var id: String
    var house: String
    var date: Int64
    var symbol: String
    var notes: String
    var user: String
    var created_at: String
    var updated_at: String
    
    static func == (lhs: VisitModel, rhs: VisitModel) -> Bool {
        return lhs.id == rhs.id &&
        lhs.house == rhs.house &&
        lhs.date == rhs.date &&
        lhs.symbol == rhs.symbol &&
        lhs.notes == rhs.notes &&
        lhs.user == rhs.user
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(house)
        hasher.combine(date)
        hasher.combine(symbol)
        hasher.combine(notes)
        hasher.combine(user)
      }
}

func convertVisitToVisitModel(model: Visit) -> VisitModel {
    return VisitModel(id: model.id ?? "", house: model.house ?? "", date: model.date, symbol: model.symbol ?? "", notes: model.notes ?? "", user: model.user ?? "", created_at: "", updated_at: "")
}
