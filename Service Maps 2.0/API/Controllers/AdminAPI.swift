//
//  AdminAPI.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation
import Alamofire

class AdminAPI {
    let baseURL = "admin/"
    
    //MARK: GET
    func allData() async throws -> AllDataResponse {
        do {
            let response = try await ApiRequestAsync().getRequest(url: baseURL + "alldata")
            
            let decoder = JSONDecoder()
            
            let jsonData = response.data(using: .utf8)!
            
            let allDataResponse = try decoder.decode(AllDataResponse.self, from: jsonData)
            
            return allDataResponse
        } catch {
            throw error.self
        }
    }
    
    //MARK: TERRITORY
    func addTerritory(territory: TerritoryModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "territories/add", body: territory)
        } catch {
            throw error.self
        }
    }
    
    //PENDING UPLOAD PHOTOS ADDTERRITORYFUNC
    
//    func addTerritory(territory: TerritoryModel, image: UIImage) async -> Result<Bool, Error> {
//        do {
//            var body =
//        } catch {
//            
//        }
//    }
    
    func updateTerritory(territory: TerritoryModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "territories/update", body: territory)
        } catch {
            throw error.self
        }
    }
    
    //PENDING UPLOAD PHOTOS UPDATETERRITORYFUNC
    
    func deleteTerritory(territory: TerritoryModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "territories/delete", body: territory)
        } catch {
            throw error.self
        }
    }
    
    //MARK: TERRITORY
    func addTerritoryAddress(territoryAddress: TerritoryAddressModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "territories/address/add", body: territoryAddress)
        } catch {
            throw error.self
        }
    }
    
    //PENDING UPLOAD PHOTOS ADDTERRITORYFUNC
    
    
    func updateTerritoryAddress(territoryAddress: TerritoryAddressModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "territories/address/update", body: territoryAddress)
        } catch {
            throw error.self
        }
    }
    
    //PENDING UPLOAD PHOTOS UPDATETERRITORYFUNC
    
    func deleteTerritoryAddress(territoryAddress: TerritoryAddressModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "territories/address/delete", body: territoryAddress)
        } catch {
            throw error.self
        }
    }
    
    //MARK: House
    func addHouse(house: HouseModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "houses/add", body: house)
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
    
    func deleteHouse(house: HouseModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "houses/delete", body: house)
        } catch {
            throw error.self
        }
    }
    
    //MARK: Visit
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
    
    func deleteVisit(visit: VisitModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "visits/delete", body: visit)
        } catch {
            throw error.self
        }
    }
}
