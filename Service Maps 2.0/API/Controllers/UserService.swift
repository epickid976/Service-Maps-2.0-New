//
//  UserService.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation
import Alamofire
import SwiftUI
import Papyrus

// MARK: - User Service

@BackgroundActor
class UserService {
    // MARK: - API
    private lazy var api: UserRoutes = UserRoutesAPI(provider: APIProvider().provider)

    // MARK: - Load Data
    func loadTerritoriesNew() async -> Result<[TerritoryWithAll], Error> {
        do {
            let territories = try await api.loadTerritoriesNew()
            return .success(territories)
        } catch {
            return .failure(error)
        }
    }
    
    func loadTerritories() async -> Result<AllDataResponse, Error> {
        do {
            let response = try await api.loadTerritories()
            return .success(response)
        } catch {
            return .failure(error)
        }
    }
    
    func loadPhonesNew() async -> Result<CongregationWithAllPhone, Error> {
        do {
            let phones = try await api.loadPhoneNew()
            return .success(phones)
        } catch {
            print("Error \(error)")
            return .failure(error)
        }
    }

    func allPhoneData() async -> Result<AllPhoneDataResponse, Error> {
        do {
            let response = try await api.allPhoneData()
            return .success(response)
        } catch {
            return .failure(error)
        }
    }

    //MARK: Territory CRUD
    func updateTerritory(territory: Territory) async -> Result<Void, Error> {
        do {
            try await api.updateTerritory(territory: territory)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func updateTerritory(territory: Territory, image: UIImage) async -> Result<Void, Error> {
        do {
            // Convert UIImage to Data
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                return .failure(NSError(domain: "ImageConversionError", code: 0, userInfo: nil))
            }
            
            // Prepare parts for the API call
            let filePart = Part(data: imageData, name: "file", fileName: "territory.jpg", mimeType: "image/jpeg")
            let congregationPart = territory.congregation
            let numberPart = String(territory.number)
            let descriptionPart = territory.description
            let imagePart = territory.image ?? ""
            
            try await api.updateTerritory(
                file: filePart,
                congregation: congregationPart,
                number: numberPart,
                description: descriptionPart,
                image: imagePart
            )
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    //MARK: Territory Address CRUD
    
    func updateTerritoryAddress(territoryAddress: TerritoryAddress) async -> Result<Void, Error> {
        do {
            try await api.updateTerritoryAddress(territoryAddress: territoryAddress)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    //MARK: House CRUD
    
    func updateHouse(house: House) async -> Result<Void, Error> {
        do {
            try await api.updateHouse(house: house)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    //MARK: Visit CRUD
    func addVisit(visit: Visit) async -> Result<Void, Error> {
        do {
            try await api.addVisit(visit: visit)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func updateVisit(visit: Visit) async -> Result<Void, Error> {
        do {
            try await api.updateVisit(visit: visit)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    //MARK: Phone Call CRUD
    
    func addPhoneCall(phoneCall: PhoneCall) async -> Result<Void, Error> {
        do {
            try await api.addPhoneCall(phoneCall: phoneCall)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func updatePhoneCall(phoneCall: PhoneCall) async -> Result<Void, Error> {
        do {
            try await api.updatePhoneCall(phoneCall: phoneCall)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func deletePhoneCall(phoneCall: PhoneCall) async -> Result<Void, Error> {
        do {
            try await api.deletePhoneCall(phoneCall: phoneCall)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    //MARK: Recalls - Get, Add, Remove
    func getRecalls() async -> Result<[Recalls], Error> {
        do {
            let recalls = try await api.getRecalls()
            return .success(recalls)
        } catch {
            return .failure(error)
        }
    }

    func addRecall(recall: Recalls) async -> Result<Void, Error> {
        do {
            try await api.addRecall(recall: recall)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func removeRecall(recall: Recalls) async -> Result<Void, Error> {
        do {
            try await api.removeRecall(recall: recall)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}
