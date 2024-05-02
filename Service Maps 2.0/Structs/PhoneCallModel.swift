//
//  PhoneCallModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/30/24.
//

import Foundation

struct PhoneCallModel: Codable, Equatable, Hashable, Identifiable{
    var id: String
    var phonenumber: String
    var date: Int64
    var notes: String
    var user: String
    var created_at: String
    var updated_at: String
    
    static func == (lhs: PhoneCallModel, rhs: PhoneCallModel) -> Bool {
        return lhs.id == rhs.id &&
        lhs.phonenumber == rhs.phonenumber &&
        lhs.date == rhs.date &&
        lhs.notes == rhs.notes &&
        lhs.user == rhs.user
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(phonenumber)
        hasher.combine(date)
        hasher.combine(notes)
        hasher.combine(user)// Combine an empty string for optional floor
      }
}

func convertPhoneTerritoryModelToPhoneTerritoryModel(model: PhoneTerritoryObject) -> PhoneTerritoryModel {
  return PhoneTerritoryModel(
    id: model.id,
    congregation: model.congregation,
    number: model.number,
    description: model.territoryDescription,
    image: model.image,
    created_at: "",
    updated_at: ""
  )
}

func convertPhoneNumberModelToPhoneNumberModel(model: PhoneNumberObject) -> PhoneNumberModel {
  return PhoneNumberModel(
    id: model.id,
    congregation: model.congregation,
    number: model.number,
    territory: model.territory,
    house: model.house,
    created_at: "",
    updated_at: ""
  )
}

func convertPhoneCallModelToPhoneCallModel(model: PhoneCallObject) -> PhoneCallModel {
  return PhoneCallModel(
    id: model.id,
    phonenumber: model.phoneNumber,
    date: model.date,
    notes: model.notes,
    user: model.user,
    created_at: "",
    updated_at: ""
  )
}

