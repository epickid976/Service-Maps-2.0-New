//
//  PhoneTerritoryObject.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/30/24.
//

import Foundation
import RealmSwift

class PhoneTerritoryObject: Object, Identifiable {
    @Persisted var id: String
    @Persisted var congregation: String
    @Persisted var number: Int64
    @Persisted var territoryDescription: String
    @Persisted var image: String?
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    static func == (lhs: PhoneTerritoryObject, rhs: PhoneTerritoryModel) -> Bool {
        return lhs.id == rhs.id &&
               lhs.congregation == rhs.congregation &&
               lhs.number == rhs.number &&
               lhs.territoryDescription == rhs.description && // Match description property name
               lhs.image == rhs.image
      }
    
    func createTerritoryObject(from model: PhoneTerritoryModel) -> PhoneTerritoryObject {
      let territoryObject = PhoneTerritoryObject()
      territoryObject.id = model.id
      territoryObject.congregation = model.congregation
      territoryObject.number = model.number
      territoryObject.territoryDescription = model.description  // Match description property name
      territoryObject.image = model.image
      return territoryObject
    }
    
    func getImageURL() -> String {
        let baseURL = "https://servicemaps.ejvapps.online/api/"
        if let imageToSend = image {
            return baseURL + "phone/territories/" + String(congregation) + "/" + imageToSend
        } else {
            return "https://www.google.com/url?sa=i&url=https%3A%2F%2Flottiefiles.com%2Fanimations%2Fno-data-bt8EDsKmcr&psig=AOvVaw2p2xZlutsRFWRoLRsg6LJ2&ust=1712619221457000&source=images&cd=vfe&opi=89978449&ved=0CBEQjRxqFwoTCPjeiPihsYUDFQAAAAAdAAAAABAE"
        }
    }
}
