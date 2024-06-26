//
//  TerritoryObject.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/15/24.
//

import Foundation
import RealmSwift

class TerritoryObject: Object, Identifiable{
    @Persisted var id: String
    @Persisted var congregation: String
    @Persisted var number: Int32
    @Persisted var territoryDescription: String
    @Persisted var image: String?
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    static func == (lhs: TerritoryObject, rhs: TerritoryModel) -> Bool {
        return lhs.id == rhs.id &&
               lhs.congregation == rhs.congregation &&
               lhs.number == rhs.number &&
               lhs.territoryDescription == rhs.description && // Match description property name
               lhs.image == rhs.image
      }
    
    func createTerritoryObject(from model: TerritoryModel) -> TerritoryObject {
      let territoryObject = TerritoryObject()
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
            return baseURL + "territories/" + congregation + "/" + imageToSend
        } else {
            return "https://www.google.com/url?sa=i&url=https%3A%2F%2Flottiefiles.com%2Fanimations%2Fno-data-bt8EDsKmcr&psig=AOvVaw2p2xZlutsRFWRoLRsg6LJ2&ust=1712619221457000&source=images&cd=vfe&opi=89978449&ved=0CBEQjRxqFwoTCPjeiPihsYUDFQAAAAAdAAAAABAE"
        }
    }
}
