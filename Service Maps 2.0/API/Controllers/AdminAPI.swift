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
    
    func getTerritories() async throws -> [TerritoryModel] {
        do {
            let response = try await ApiRequestAsync().getRequest(url: baseURL + "territories")
            
            let decoder = JSONDecoder()
            
            let jsonData = response.data(using: .utf8)!
            
            let reply = try decoder.decode([TerritoryModel].self, from: jsonData)
            
            return reply
        } catch {
            throw error.self
        }
    }
    
    func getHouses() async throws -> [HouseModel] {
        do {
            let response = try await ApiRequestAsync().getRequest(url: baseURL + "houses")
            
            let decoder = JSONDecoder()
            
            let jsonData = response.data(using: .utf8)!
            
            let reply = try decoder.decode([HouseModel].self, from: jsonData)
            
            return reply
        } catch {
            throw error.self
        }
    }
    
    func getVisits() async throws -> [VisitModel] {
        do {
            let response = try await ApiRequestAsync().getRequest(url: baseURL + "visits")
            
            let decoder = JSONDecoder()
            
            let jsonData = response.data(using: .utf8)!
            
            let reply = try decoder.decode([VisitModel].self, from: jsonData)
            
            return reply
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
    
    func updateTerritory(territory: TerritoryModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "territories/update", body: territory)
        } catch {
            throw error.self
        }
    }
    
    func deleteTerritory(territory: TerritoryModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "territories/delete", body: territory)
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
