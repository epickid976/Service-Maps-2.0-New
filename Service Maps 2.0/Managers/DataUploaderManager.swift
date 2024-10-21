//
//  DataUploaderManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/27/23.
//

import Foundation
import BackgroundTasks
import SwiftUI
import Combine

import Foundation
import SwiftUI


class DataUploaderManager: ObservableObject {

    @Published private var authorizationLevelManager = AuthorizationLevelManager()
    @Published private var dataStore = StorageManager.shared
    @Published private var synchronizationManager = SynchronizationManager.shared

    private var adminApi = AdminAPI()
    private var userApi = UserAPI()
    private var tokenApi = TokenAPI()

    @ObservedObject private var grdbManager = GRDBManager.shared

    // MARK: - Territory Methods
    @BackgroundActor
    func addTerritory(territory: Territory, image: UIImage? = nil) async -> Result<Bool, Error> {
        do {
            if image == nil {
                try await adminApi.addTerritory(territory: territory)
            } else {
                try await adminApi.addTerritory(territory: territory, image: image!)
            }
            
            _ = await grdbManager.addAsync(territory)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    @BackgroundActor
    func updateTerritory(territory: Territory, image: UIImage? = nil) async -> Result<Bool, Error> {
        do {
            if await authorizationLevelManager.existsAdminCredentials() {
                if image == nil {
                    try await adminApi.updateTerritory(territory: territory)
                } else {
                    try await adminApi.updateTerritory(territory: territory, image: image!)
                }
            } else {
                await authorizationLevelManager.setAuthorizationTokenFor(model: territory)
                if image == nil {
                    try await userApi.updateTerritory(territory: territory)
                } else {
                    try await userApi.updateTerritory(territory: territory, image: image!)
                }
            }
            _ = await grdbManager.editAsync(territory)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    @BackgroundActor
    func deleteTerritory(territoryId: String) async -> Result<Bool, Error> {
        do {
            let territoryResult = await grdbManager.fetchByIdAsync(Territory.self, id: territoryId)

            switch territoryResult {
            case .success(let territory):
                guard let territory = territory else {
                    return .failure(CustomErrors.NotFound)
                }
                try await adminApi.deleteTerritory(territory: territory)
                _ = await grdbManager.deleteAsync(territory)
                return .success(true)
                
            case .failure(let error):
                return .failure(error)
            }
        } catch {
            return .failure(error)
        }
    }

    // MARK: - TerritoryAddress Methods
    @BackgroundActor
    func addTerritoryAddress(territoryAddress: TerritoryAddress) async -> Result<Bool, Error> {
        do {
            try await adminApi.addTerritoryAddress(territoryAddress: territoryAddress)
            _ = await grdbManager.addAsync(territoryAddress)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    @BackgroundActor
    func updateTerritoryAddress(territoryAddress: TerritoryAddress) async -> Result<Bool, Error> {
        do {
            try await adminApi.updateTerritoryAddress(territoryAddress: territoryAddress)
            _ = await grdbManager.editAsync(territoryAddress)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    @BackgroundActor
    func deleteTerritoryAddress(territoryAddressId: String) async -> Result<Bool, Error> {
        do {
            let territoryAddressResult = await grdbManager.fetchByIdAsync(TerritoryAddress.self, id: territoryAddressId)
            
            switch territoryAddressResult {
            case .success(let territoryAddress):
                guard let territoryAddress = territoryAddress else {
                    return .failure(CustomErrors.NotFound)
                }
                try await adminApi.deleteTerritoryAddress(territoryAddress: territoryAddress)
                _ = await grdbManager.deleteAsync(territoryAddress)
                return .success(true)
                
            case .failure(let error):
                return .failure(error)
            }
        } catch {
            return .failure(error)
        }
    }

    // MARK: - House Methods
    @BackgroundActor
    func addHouse(house: House) async -> Result<Bool, Error> {
        do {
            try await adminApi.addHouse(house: house)
            _ = await grdbManager.addAsync(house)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    @BackgroundActor
    func updateHouse(house: House) async -> Result<Bool, Error> {
        do {
            try await adminApi.updateHouse(house: house)
            _ = await grdbManager.editAsync(house)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    @BackgroundActor
    func deleteHouse(houseId: String) async -> Result<Bool, Error> {
        do {
            let houseResult = await grdbManager.fetchByIdAsync(House.self, id: houseId)
            
            switch houseResult {
            case .success(let house):
                guard let house = house else {
                    return .failure(CustomErrors.NotFound)
                }
                try await adminApi.deleteHouse(house: house)
                _ = await grdbManager.deleteAsync(house)
                return .success(true)
                
            case .failure(let error):
                return .failure(error)
            }
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Visit Methods
    @BackgroundActor
    func addVisit(visit: Visit) async -> Result<Bool, Error> {
        do {
            if await authorizationLevelManager.existsAdminCredentials() {
                try await adminApi.addVisit(visit: visit)
            } else {
                await authorizationLevelManager.setAuthorizationTokenFor(model: visit)
                try await userApi.addVisit(visit: visit)
            }
            _ = await grdbManager.addAsync(visit)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    @BackgroundActor
    func updateVisit(visit: Visit) async -> Result<Bool, Error> {
        do {
            if await authorizationLevelManager.existsAdminCredentials() {
                try await adminApi.updateVisit(visit: visit)
            } else {
                await authorizationLevelManager.setAuthorizationTokenFor(model: visit)
                try await userApi.updateVisit(visit: visit)
            }
            _ = await grdbManager.editAsync(visit)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    @BackgroundActor
    func deleteVisit(visitId: String) async -> Result<Bool, Error> {
        do {
            let visitResult = await grdbManager.fetchByIdAsync(Visit.self, id: visitId)
            
            switch visitResult {
            case .success(let visit):
                guard let visit = visit else {
                    return .failure(CustomErrors.NotFound)
                }
                try await adminApi.deleteVisit(visit: visit)
                _ = await grdbManager.deleteAsync(visit)
                return .success(true)
                
            case .failure(let error):
                return .failure(error)
            }
        } catch {
            return .failure(error)
        }
    }

    // MARK: - PhoneTerritory Methods
    @BackgroundActor
    func addPhoneTerritory(territory: PhoneTerritory, image: UIImage? = nil) async -> Result<Bool, Error> {
        do {
            if image == nil {
                try await adminApi.addPhoneTerritory(territory: territory)
            } else {
                try await adminApi.addPhoneTerritory(territory: territory, image: image!)
            }
            _ = await grdbManager.addAsync(territory)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    @BackgroundActor
    func updatePhoneTerritory(territory: PhoneTerritory, image: UIImage? = nil) async -> Result<Bool, Error> {
        do {
            if await authorizationLevelManager.existsAdminCredentials() {
                if image == nil {
                    try await adminApi.updatePhoneTerritory(territory: territory)
                } else {
                    try await adminApi.updatePhoneTerritory(territory: territory, image: image!)
                }
            }
            _ = await grdbManager.editAsync(territory)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    @BackgroundActor
    func deletePhoneTerritory(territoryId: String) async -> Result<Bool, Error> {
        do {
            let territoryResult = await grdbManager.fetchByIdAsync(PhoneTerritory.self, id: territoryId)

            switch territoryResult {
            case .success(let territory):
                guard let territory = territory else {
                    return .failure(CustomErrors.NotFound)
                }
                try await adminApi.deletePhoneTerritory(territory: territory)
                _ = await grdbManager.deleteAsync(territory)
                return .success(true)
                
            case .failure(let error):
                return .failure(error)
            }
        } catch {
            return .failure(error)
        }
    }

    // MARK: - PhoneNumber Methods
    @BackgroundActor
    func addPhoneNumber(phoneNumber: PhoneNumber) async -> Result<Bool, Error> {
        do {
            try await adminApi.addPhoneNumber(number: phoneNumber)
            _ = await grdbManager.addAsync(phoneNumber)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    @BackgroundActor
    func updatePhoneNumber(phoneNumber: PhoneNumber) async -> Result<Bool, Error> {
        do {
            try await adminApi.updatePhoneNumber(number: phoneNumber)
            _ = await grdbManager.editAsync(phoneNumber)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    @BackgroundActor
    func deletePhoneNumber(phoneNumberId: String) async -> Result<Bool, Error> {
        do {
            let phoneNumberResult = await grdbManager.fetchByIdAsync(PhoneNumber.self, id: phoneNumberId)

            switch phoneNumberResult {
            case .success(let phoneNumber):
                guard let phoneNumber = phoneNumber else {
                    return .failure(CustomErrors.NotFound)
                }
                try await adminApi.deletePhoneNumber(number: phoneNumber)
                _ = await grdbManager.deleteAsync(phoneNumber)
                return .success(true)
                
            case .failure(let error):
                return .failure(error)
            }
        } catch {
            return .failure(error)
        }
    }

    // MARK: - PhoneCall Methods
    @BackgroundActor
    func addPhoneCall(phoneCall: PhoneCall) async -> Result<Bool, Error> {
        do {
            if await authorizationLevelManager.existsAdminCredentials() {
                try await adminApi.addCall(call: phoneCall)
            } else {
                try await userApi.addCall(call: phoneCall)
            }
            _ = await grdbManager.addAsync(phoneCall)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    @BackgroundActor
    func updatePhoneCall(phoneCall: PhoneCall) async -> Result<Bool, Error> {
        do {
            if await authorizationLevelManager.existsAdminCredentials() {
                try await adminApi.updateCall(call: phoneCall)
            } else {
                try await userApi.updateCall(call: phoneCall)
            }
            _ = await grdbManager.editAsync(phoneCall)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    @BackgroundActor
    func deletePhoneCall(phoneCallId: String) async -> Result<Bool, Error> {
        do {
            let phoneCallResult = await grdbManager.fetchByIdAsync(PhoneCall.self, id: phoneCallId)

            switch phoneCallResult {
            case .success(let phoneCall):
                guard let phoneCall = phoneCall else {
                    return .failure(CustomErrors.NotFound)
                }
                try await adminApi.deleteCall(call: phoneCall)
                _ = await grdbManager.deleteAsync(phoneCall)
                return .success(true)
                
            case .failure(let error):
                return .failure(error)
            }
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Token and TokenTerritory Methods
    @BackgroundActor
    func createToken(newTokenForm: NewTokenForm, territories: [Territory]) async -> Result<Token, Error> {
        do {
            let token = try await tokenApi.createToken(name: newTokenForm.name, moderator: newTokenForm.moderator, territories: newTokenForm.territories, congregation: newTokenForm.congregation, expire: newTokenForm.expire)
            
            var tokenTerritories = [TokenTerritory]()
            
            _ = await grdbManager.addAsync(token)
            
            for territory in territories {
                let newTokenTerritory = TokenTerritory(token: token.id, territory: territory.id)
                tokenTerritories.append(newTokenTerritory)
            }
            
            for tokenTerritory in tokenTerritories {
                _ = await grdbManager.addAsync(tokenTerritory)
            }
            
            return .success(token)
            
        } catch {
            return .failure(error)
        }
    }
    @BackgroundActor
    func editToken(token: String, territories: [Territory]) async -> Result<Bool, Error> {
        do {
            var territoriesToSend = [String]()
            territories.forEach { territory in
                territoriesToSend.append(territory.id)
            }
            
            try await tokenApi.editToken(tokenId: token, territories: territoriesToSend.description)
            
            do {
                // Fetching data using fetchAll that returns a Result type
                let fetchResult = await grdbManager.fetchAllAsync(TokenTerritory.self)
                
                // Unwrapping the result
                switch fetchResult {
                case .success(let tokenTerritoryEntities):
                    // Proceed with the list of token territories
                    for oldTokenTerritory in tokenTerritoryEntities where oldTokenTerritory.token == token {
                        _ = await grdbManager.deleteAsync(oldTokenTerritory)
                    }
                case .failure(let error):
                    // Handle error case
                    print("Error fetching token territories: \(error)")
                    throw error
                }
            } catch {
                return .failure(error)
            }
            
            for territory in territories {
                let newTokenTerritory = TokenTerritory(token: token, territory: territory.id)
                _ = await grdbManager.addAsync(newTokenTerritory)
            }
            
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    @BackgroundActor
    func deleteToken(tokenId: String) async -> Result<Bool, Error> {
        do {
            let tokenResult = await grdbManager.fetchByIdAsync(Token.self, id: tokenId)

            switch tokenResult {
            case .success(let token):
                guard let token = token else {
                    return .failure(CustomErrors.NotFound)
                }
                try await tokenApi.deleteToken(token: token.id)
                _ = await grdbManager.deleteAsync(token)
                return .success(true)
                
            case .failure(let error):
                return .failure(error)
            }
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Recalls Methods
    @BackgroundActor
    func addRecall(user: String, house: String) async -> Result<Bool, Error> {
        do {
            let recall = Recalls(id: Date.now.millisecondsSince1970, user: user, house: house)
            try await userApi.addRecall(recall: recall)
            _ = await grdbManager.addAsync(recall)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    @BackgroundActor
    func deleteRecall(recall: Recalls) async -> Result<Bool, Error> {
        do {
            try await userApi.removeRecall(recall: recall)
            _ = await grdbManager.deleteAsync(recall)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    @BackgroundActor
    func unregisterToken(myToken: String) async -> Result<Bool, Error> {
        do {
            try await tokenApi.unregister(token: myToken)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    @BackgroundActor
    func registerToken(myToken: String) async -> Result<Bool, Error> {
        do {
            try await tokenApi.register(token: myToken)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    @BackgroundActor
    func deleteUserFromToken(userToken: String) async -> Result<Bool, Error> {
        do {
            // Fetch user token from database using GRDB
            let userTokenResult = await grdbManager.fetchByIdAsync(UserToken.self, id: userToken)
            
            switch userTokenResult {
            case .success(let userTokenEntity):
                // Ensure the user token exists
                guard let userTokenEntity = userTokenEntity else {
                    return .failure(CustomErrors.NotFound)
                }
                
                // Remove the user from the token using the API
                try await tokenApi.removeUserFromToken(token: userTokenEntity.token, userId: userTokenEntity.userId)
                
                // Delete the user token from the local database
                _ = await grdbManager.deleteAsync(userTokenEntity)
                
                return .success(true)
            case .failure(let error):
                return .failure(error)
            }
        } catch {
            return .failure(error)
        }
    }
    @BackgroundActor
    func blockUnblockUserFromToken(userToken: String, blocked: Bool) async -> Result<Bool, Error> {
        do {
            // Fetch user token from database using GRDB
            let userTokenResult = await grdbManager.fetchByIdAsync(UserToken.self, id: userToken)
            
            switch userTokenResult {
            case .success(let userTokenEntity):
                // Ensure the user token exists
                guard let userTokenEntity = userTokenEntity else {
                    return .failure(CustomErrors.NotFound)
                }
                
                // Block or unblock the user using the API
                try await tokenApi.blockUnblockUserFromToken(token: userTokenEntity.token, userId: userTokenEntity.userId, blocked: blocked)
                
                // Update the local database with the new blocked status
                let updatedUserToken = UserToken(id: userTokenEntity.id, token: userTokenEntity.token, userId: userTokenEntity.userId, name: userTokenEntity.name, blocked: blocked)
                _ = await grdbManager.editAsync(updatedUserToken)
                
                return .success(true)
            case .failure(let error):
                return .failure(error)
            }
        } catch {
            return .failure(error)
        }
    }
}
