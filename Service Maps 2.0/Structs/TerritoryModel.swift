//
//  TerritoryModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation

struct TerritoryModel: Codable, Equatable, Hashable, Identifiable {
    var id: String
    var congregation: String
    var number: Int32
    var description: String
    var image: String?
    var created_at: String
    var updated_at: String
    
    static func == (lhs: TerritoryModel, rhs: TerritoryModel) -> Bool {
        return lhs.id == rhs.id &&
        lhs.congregation == rhs.congregation &&
        lhs.number == rhs.number &&
        lhs.description == rhs.description &&
        lhs.image == rhs.image
    }
    
    func hash(into hasher: inout Hasher) {
       hasher.combine(id)
       hasher.combine(congregation)
       hasher.combine(number)
       hasher.combine(description)
       hasher.combine(image ?? "") // Combine an empty string for optional image
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



func convertTerritoryToTerritoryModel(model: TerritoryObject) -> TerritoryModel {
    return TerritoryModel(id: model.id, congregation: model.congregation, number: model.number, description: model.territoryDescription, created_at: "", updated_at: "")
}
