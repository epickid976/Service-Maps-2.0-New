//
//  UserAPI.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation
import Alamofire
import SwiftUI

class UserAPI {
    let baseURL = "users/"
    
    func loadTerritories() async throws -> AllDataResponse {
        do {
            let response = try await ApiRequestAsync().getRequest(url: baseURL + "territories")
            
            let decoder = JSONDecoder()
            
            let jsonData = response.data(using: .utf8)!
            
            let reply = try decoder.decode(AllDataResponse.self, from: jsonData)
            
            return reply
        } catch {
            throw error.self
        }
    }
    
    //MARK: UPDATE
    func updateTerritory(territory: TerritoryModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "territories/update", body: territory)
        } catch {
            throw error.self
        }
    }
    
    
    func updateTerritory(territory: TerritoryModel, image: UIImage) async throws {
        do {
            let parameters: [String : Any] = ["congregation" : territory.congregation, "number" : territory.number, "description" : territory.description, "image" : territory.image as Any]
            
            _ = try await ApiRequestAsync().uploadWithImage(url: baseURL + "territories/update", withFile: image, parameters: parameters)
        } catch {
            throw error.self
        }
    }
    
    
    func updateTerritoryAddress(territoryAddress: TerritoryAddressModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "territories/address/update", body: territoryAddress)
        } catch {
            throw error.self
        }
    }
    
    func updateHouse(house: HouseModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "houses/update", body: house)
        } catch {
            throw error.self
        }
    }
    
    //MARK: VISIT
    func addVisit(visit: VisitModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "visits/add", body: visit)
        } catch {
            throw error.self
        }
    }
    
    func updateVisit(visit: VisitModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "visits/update", body: visit)
        } catch {
            throw error.self
        }
    }
}
