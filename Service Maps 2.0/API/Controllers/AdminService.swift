//
//  AdminService.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation
import Alamofire
import SwiftUI
import Papyrus

class AdminService {
    private lazy var api: AdminRoutes = AdminRoutesAPI(provider: APIProvider.shared.provider)

    // Fetch all data
    func allData() async -> Result<AllDataResponse, Error> {
        do {
            let data = try await api.allData()
            return .success(data)
        } catch {
            return .failure(error)
        }
    }

    // Fetch all phone data
    func allPhoneData() async -> Result<AllPhoneDataResponse, Error> {
        do {
            let data = try await api.allPhoneData()
            return .success(data)
        } catch {
            return .failure(error)
        }
    }

    // Add a new territory
    func addTerritory(territory: Territory) async -> Result<Void, Error> {
        do {
            try await api.addTerritory(territory: territory)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    func addTerritory(territory: Territory, image: UIImage) async -> Result<Void, Error> {
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

            // Call the API
            try await api.addTerritory(
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

    // Update a territory
    func updateTerritory(territory: Territory) async -> Result<Void, Error> {
        do {
            try await api.updateTerritory(territory: territory)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    // Update a territory with image (multipart)
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

    // Delete a territory
    func deleteTerritory(territory: Territory) async -> Result<Void, Error> {
        do {
            try await api.deleteTerritory(territory: territory)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    // Add a territory address
    func addTerritoryAddress(territoryAddress: TerritoryAddress) async -> Result<Void, Error> {
        do {
            try await api.addTerritoryAddress(territoryAddress: territoryAddress)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    // Update a territory address
    func updateTerritoryAddress(territoryAddress: TerritoryAddress) async -> Result<Void, Error> {
        do {
            try await api.updateTerritoryAddress(territoryAddress: territoryAddress)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    // Delete a territory address
    func deleteTerritoryAddress(territoryAddress: TerritoryAddress) async -> Result<Void, Error> {
        do {
            try await api.deleteTerritoryAddress(territoryAddress: territoryAddress)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    // Add, Update, and Delete House functions follow the same pattern:
    func addHouse(house: House) async -> Result<Void, Error> {
        do {
            try await api.addHouse(house: house)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func updateHouse(house: House) async -> Result<Void, Error> {
        do {
            try await api.updateHouse(house: house)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func deleteHouse(house: House) async -> Result<Void, Error> {
        do {
            try await api.deleteHouse(house: house)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    // Similarly, add, update, and delete Visit:
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

    func deleteVisit(visit: Visit) async -> Result<Void, Error> {
        do {
            try await api.deleteVisit(visit: visit)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    // Add, update, and delete Phone Call:
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

    // Add a phone territory
    func addPhoneTerritory(phoneTerritory: PhoneTerritory) async -> Result<Void, Error> {
        do {
            try await api.addPhoneTerritory(phoneTerritory: phoneTerritory)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    // Add a phone territory with image (multipart)
    func addPhoneTerritory(phoneTerritory: PhoneTerritory, image: UIImage) async -> Result<Void, Error> {
        do {
            // Convert UIImage to Data
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                return .failure(NSError(domain: "ImageConversionError", code: 0, userInfo: nil))
            }
            
            // Prepare parts for the API call
            let filePart = Part(data: imageData, name: "file", fileName: "territory.jpg", mimeType: "image/jpeg")
            let congregationPart = phoneTerritory.congregation
            let numberPart = String(phoneTerritory.number)
            let descriptionPart = phoneTerritory.description
            let imagePart = phoneTerritory.image ?? ""
            
            try await api.addPhoneTerritory(
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

    // Update a phone territory
    func updatePhoneTerritory(phoneTerritory: PhoneTerritory) async -> Result<Void, Error> {
        do {
            try await api.updatePhoneTerritory(phoneTerritory: phoneTerritory)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    // Update a phone territory with image (multipart)
    func updatePhoneTerritory(phoneTerritory: PhoneTerritory, image: UIImage) async -> Result<Void, Error> {
        do {
            // Convert UIImage to Data
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                return .failure(NSError(domain: "ImageConversionError", code: 0, userInfo: nil))
            }
            
            // Prepare parts for the API call
            let filePart = Part(data: imageData, name: "file", fileName: "territory.jpg", mimeType: "image/jpeg")
            let congregationPart = phoneTerritory.congregation
            let numberPart = String(phoneTerritory.number)
            let descriptionPart = phoneTerritory.description
            let imagePart = phoneTerritory.image ?? ""
            
            try await api.updatePhoneTerritory(
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

    // Delete a phone territory
    func deletePhoneTerritory(phoneTerritory: PhoneTerritory) async -> Result<Void, Error> {
        do {
            try await api.deletePhoneTerritory(phoneTerritory: phoneTerritory)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    // Add a phone number
    func addPhoneNumber(phoneNumber: PhoneNumber) async -> Result<Void, Error> {
        do {
            try await api.addPhoneNumber(phoneNumber: phoneNumber)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    // Update a phone number
    func updatePhoneNumber(phoneNumber: PhoneNumber) async -> Result<Void, Error> {
        do {
            try await api.updatePhoneNumber(phoneNumber: phoneNumber)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    // Delete a phone number
    func deletePhoneNumber(phoneNumber: PhoneNumber) async -> Result<Void, Error> {
        do {
            try await api.deletePhoneNumber(phoneNumber: phoneNumber)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}
