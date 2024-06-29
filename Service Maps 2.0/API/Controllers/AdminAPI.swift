//
//  AdminAPI.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation
import Alamofire
import SwiftUI

class AdminAPI: ApiService {
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
            print(error.self)
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
            return Result.failure(error)
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
    
    func addTerritory(territory: TerritoryModel, image: UIImage) async throws {
        do {
            let parameters: [String : Any] = ["congregation" : territory.congregation, "number" : territory.number, "description" : territory.description, "image" : territory.image as Any]
            
            _ = try await ApiRequestAsync().uploadWithImage(url: baseURL + "territories/add", withFile: image, parameters: parameters)
        } catch {
            throw error.self
        }
    }
    
    func updateTerritory(territory: TerritoryModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "territories/update", body: territory)
        } catch {
            print(error)
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
    
    func addPhoneCall(phoneCall: PhoneCallModel) async -> Result<Bool, Error> {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "phone/calls/add", body: phoneCall)
            return Result.success(true)
        } catch {
            return Result.failure(error)
        }
    }
    
    func updatePhoneCall(phoneCall: PhoneCallModel) async -> Result<Bool, Error> {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "phone/calls/update", body: phoneCall)
            return Result.success(true)
        } catch {
            return Result.failure(error)
        }
    }
    
    func deletePhoneCall(phoneCall: PhoneCallModel) async -> Result<Bool, Error> {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "phone/calls/delete", body: phoneCall)
            return Result.success(true)
        } catch {
            return Result.failure(error)
        }
    }
    
    //MARK: TERRITORY
    func addPhoneTerritory(territory: PhoneTerritoryModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "phone/territories/add", body: territory)
        } catch {
            throw error.self
        }
    }
    
    //PENDING UPLOAD PHOTOS ADDTERRITORYFUNC
    
    func addPhoneTerritory(territory: PhoneTerritoryModel, image: UIImage) async throws {
        do {
            let parameters: [String : Any] = ["congregation" : territory.congregation, "number" : territory.number, "description" : territory.description, "image" : territory.image as Any]
            
            _ = try await ApiRequestAsync().uploadWithImage(url: baseURL + "phone/territories/add", withFile: image, parameters: parameters)
        } catch {
            throw error.self
        }
    }
    
    func updatePhoneTerritory(territory: PhoneTerritoryModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "phone/territories/update", body: territory)
        } catch {
            print(error)
            throw error.self
        }
    }
    
    func updatePhoneTerritory(territory: PhoneTerritoryModel, image: UIImage) async throws {
        do {
            let parameters: [String : Any] = ["congregation" : territory.congregation, "number" : territory.number, "description" : territory.description, "image" : territory.image as Any]
            
            _ = try await ApiRequestAsync().uploadWithImage(url: baseURL + "phone/territories/update", withFile: image, parameters: parameters)
        } catch {
            throw error.self
        }
        
    }
    //PENDING UPLOAD PHOTOS UPDATETERRITORYFUNC
    
    func deletePhoneTerritory(territory: PhoneTerritoryModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "phone/territories/delete", body: territory)
        } catch {
            throw error.self
        }
    }
    
    func deletePhoneNumber(number: PhoneNumberModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "phone/numbers/delete", body: number)
        } catch {
            throw error.self
        }
    }
    
    func addPhoneNumber(number: PhoneNumberModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "phone/numbers/add", body: number)
        } catch {
            throw error.self
        }
    }
    
    func updatePhoneNumber(number: PhoneNumberModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "phone/numbers/update", body: number)
        } catch {
            throw error.self
        }
    }
    
    func deleteCall(call: PhoneCallModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "phone/calls/delete", body: call)
        } catch {
            throw error.self
        }
    }
    
    func addCall(call: PhoneCallModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "phone/calls/add", body: call)
        } catch {
            throw error.self
        }
    }
    
    func updateCall(call: PhoneCallModel) async throws {
        do {
            _ = try await ApiRequestAsync().postRequest(url: baseURL + "phone/calls/update", body: call)
        } catch {
            throw error.self
        }
    }
}
protocol ApiService {
    var baseURL: String { get }
    
    func getRequest<T: Decodable>(url: String) async throws -> T
    func postRequest<T: Encodable>(url: String, body: T) async throws
    func uploadWithImage(url: String, withFile image: UIImage, parameters: [String: Any]) async throws
}

extension ApiService {
    func getRequest<T: Decodable>(url: String) async throws -> T {
        let response = try await ApiRequestAsync().getRequest(url: url)
        let decoder = JSONDecoder()
        let jsonData = response.data(using: .utf8)!
        return try decoder.decode(T.self, from: jsonData)
    }
    
    func postRequest<T: Encodable>(url: String, body: T) async throws {
        _ = try await ApiRequestAsync().postRequest(url: url, body: body)
    }
    
    func uploadWithImage(url: String, withFile image: UIImage, parameters: [String: Any]) async throws {
        _ = try await ApiRequestAsync().uploadWithImage(url: url, withFile: image, parameters: parameters)
    }
}
