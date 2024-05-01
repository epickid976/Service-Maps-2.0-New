//
//  PhoneTerritory.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/30/24.
//

import Foundation

struct PhoneTerritoryModel: Codable, Equatable, Hashable, Identifiable{
    var id: String
    var congregation: String
    var number: Int64
    var description: String
    var image: String?
    var created_at: String
    var updated_at: String
    
    static func == (lhs: PhoneTerritoryModel, rhs: PhoneTerritoryModel) -> Bool {
        return lhs.id == rhs.id &&
        lhs.congregation == rhs.congregation &&
        lhs.number == rhs.number &&
        lhs.description == rhs.description &&
        lhs.image == rhs.image
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(congregation)
        hasher.combine(description)
        hasher.combine(number)
        hasher.combine(image) // Combine an empty string for optional floor
      }
    
    func getImageURL() -> String {
        let baseURL = "https://servicemaps.ejvapps.online/api/"
        if image != nil {
            return baseURL + "phone/territories/" + String(congregation) + "/" + image!
        } else {
            return ""
        }
    }
}
