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
            print(error)
            throw error.self
        }
    }
    
    func allPhoneData() async -> Result<AllPhoneDataResponse, Error> {
        do {
            let response = try await ApiRequestAsync().getRequest(url: baseURL + "allphonedata")
            
            let decoder = JSONDecoder()
            
            let jsonData = response.data(using: .utf8)!
            
            let reply = try decoder.decode(AllPhoneDataResponse.self, from: jsonData)
            
            return Result.success(reply)
        } catch {
            print(error)
            return Result.failure(error)
        }
    }
    
    //MARK: UPDATE
    func updateTerritory(territory: Territory) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "territories/update", body: territory)
        } catch {
            throw error.self
        }
    }
    
    
    func updateTerritory(territory: Territory, image: UIImage) async throws {
        do {
            let parameters: [String : Any] = ["congregation" : territory.congregation, "number" : territory.number, "description" : territory.description, "image" : territory.image as Any]
            
            _ = try await ApiRequestAsync().uploadWithImage(url: baseURL + "territories/update", withFile: image, parameters: parameters)
        } catch {
            throw error.self
        }
    }
    
    
    func updateTerritoryAddress(territoryAddress: TerritoryAddress) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "territories/address/update", body: territoryAddress)
        } catch {
            throw error.self
        }
    }
    
    func updateHouse(house: House) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "houses/update", body: house)
        } catch {
            throw error.self
        }
    }
    
    //MARK: VISIT
    func addVisit(visit: Visit) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "visits/add", body: visit)
        } catch {
            print(error)
            throw error.self
        }
    }
    
    func updateVisit(visit: Visit) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "visits/update", body: visit)
        } catch {
            throw error.self
        }
    }
    
    func addPhoneCall(phoneCall: PhoneCall) async -> Result<Bool, Error> {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "phone/calls/add", body: phoneCall)
            return Result.success(true)
        } catch {
            return Result.failure(error)
        }
    }
    
    func updatePhoneCall(phoneCall: PhoneCall) async -> Result<Bool, Error> {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "phone/calls/update", body: phoneCall)
            return Result.success(true)
        } catch {
            return Result.failure(error)
        }
    }
    
    func deletePhoneCall(phoneCall: PhoneCall) async -> Result<Bool, Error> {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "phone/calls/delete", body: phoneCall)
            return Result.success(true)
        } catch {
            return Result.failure(error)
        }
    }
    
    func deleteCall(call: PhoneCall) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "phone/calls/delete", body: call)
        } catch {
            throw error.self
        }
    }
    
    func addCall(call: PhoneCall) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "phone/calls/add", body: call)
        } catch {
            throw error.self
        }
    }
    
    func updateCall(call: PhoneCall) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "phone/calls/update", body: call)
        } catch {
            throw error.self
        }
    }
    
    func getRecalls() async throws -> [Recalls] {
        do {
            let response = try await ApiRequestAsync().getRequest(url: baseURL + "recalls")
            
            let decoder = JSONDecoder()
            
            let jsonData = response.data(using: .utf8)!
            
            let reply = try decoder.decode([Recalls].self, from: jsonData)
            
            return reply
        } catch {
            
            throw error.self
        }
    }
    
    func addRecall(recall: Recalls) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "addRecall", body: recall)
        } catch {
            throw error.self
        }
    }
    
    func removeRecall(recall: Recalls) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "removeRecall", body: recall)
        } catch {
            throw error.self
        }
    }
}
