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
import GRDB

//MARK: - DataUploaderManager
@MainActor
class DataUploaderManager: ObservableObject {
    //MARK: - Dependencies
    
    @Published private var authorizationLevelManager = AuthorizationLevelManager()
    @Published private var dataStore = StorageManager.shared
    @Published private var synchronizationManager = SynchronizationManager.shared
    
    private var adminApi = AdminService()
    private var userApi = UserService()
    //private var tokenApi = TokenService()
    
    @ObservedObject private var grdbManager = GRDBManager.shared
    
    // MARK: - Territory Methods
    @BackgroundActor
    func addTerritory(territory: Territory, image: UIImage? = nil) async -> Result<Void, Error> {
        let apiResult = image == nil
            ? await adminApi.addTerritory(territory: territory)
            : await adminApi.addTerritory(territory: territory, image: image!)
        
        return await performApiAndDbUpdate(apiResult) {
            _ = try await grdbManager.addAsync(territory).get() // Ignore the result but handle any errors
        }
    }
    
    @BackgroundActor
    func updateTerritory(territory: Territory, image: UIImage? = nil) async -> Result<Void, Error> {
        let apiResult = image == nil
            ? await adminApi.updateTerritory(territory: territory)
            : await adminApi.updateTerritory(territory: territory, image: image!)

        return await performApiAndDbUpdate(apiResult) {
            _ = try await grdbManager.editAsync(territory).get() // Ignore the result but handle errors
        }
    }
    
    @BackgroundActor
    func deleteTerritory(territoryId: String) async -> Result<Void, Error> {
        // Attempt to fetch the territory, handling the optional result
        let fetchResult = await grdbManager.fetchByIdAsync(Territory.self, id: territoryId)
        
        guard case .success(let territory) = fetchResult, let unwrappedTerritory = territory else {
            return .failure(CustomErrors.NotFound)
        }

        // Proceed with deletion if territory was found
        let apiResult = await adminApi.deleteTerritory(territory: unwrappedTerritory)
        return await performGracefulDeleteUpdate(apiResult) {
            _ = try await grdbManager.deleteAsync(unwrappedTerritory).get() // Ignore result but handle errors
        }
    }
    
    // MARK: - TerritoryAddress Methods
    @BackgroundActor
    func addTerritoryAddress(territoryAddress: TerritoryAddress) async -> Result<Void, Error> {
        let apiResult = await adminApi.addTerritoryAddress(territoryAddress: territoryAddress)
        return await performApiAndDbUpdate(apiResult) {
            _ = try await grdbManager.addAsync(territoryAddress).get() // Ignore result but handle errors
        }
    }
    
    @BackgroundActor
    func deleteTerritoryAddress(territoryAddressId: String) async -> Result<Void, Error> {
        let fetchResult = await grdbManager.fetchByIdAsync(TerritoryAddress.self, id: territoryAddressId)

        guard case .success(let territoryAddress) = fetchResult, let unwrappedTerritoryAddress = territoryAddress else {
            return .failure(CustomErrors.NotFound)
        }
        
        let apiResult = await adminApi.deleteTerritoryAddress(territoryAddress: unwrappedTerritoryAddress)
        return await performGracefulDeleteUpdate(apiResult) {
            _ = try await grdbManager.deleteAsync(unwrappedTerritoryAddress).get() // Ignore result but handle errors
        }
    }
    
    @BackgroundActor
    func updateTerritoryAddress(territoryAddress: TerritoryAddress) async -> Result<Void, Error> {
        let apiResult = await adminApi.updateTerritoryAddress(territoryAddress: territoryAddress)
        return await performApiAndDbUpdate(apiResult) {
            _ = try await grdbManager.editAsync(territoryAddress).get() // Ignore result but handle errors
        }
    }
    
    // MARK: - House Methods
    @BackgroundActor
    func addHouse(house: House) async -> Result<Void, Error> {
        let apiResult = await adminApi.addHouse(house: house)
        return await performApiAndDbUpdate(apiResult) {
            _ = try await grdbManager.addAsync(house).get() // Ignore result but handle errors
        }
    }
    
    @BackgroundActor
    func deleteHouse(houseId: String) async -> Result<Void, Error> {
        let fetchResult = await grdbManager.fetchByIdAsync(House.self, id: houseId)

        guard case .success(let house) = fetchResult, let unwrappedHouse = house else {
            return .failure(CustomErrors.NotFound)
        }

        let apiResult = await adminApi.deleteHouse(house: unwrappedHouse)
        return await performGracefulDeleteUpdate(apiResult) {
            _ = try await grdbManager.deleteAsync(unwrappedHouse).get() // Ignore result but handle errors
        }
    }
    
    // MARK: - Visit Methods
    @BackgroundActor
    func addVisit(visit: Visit) async -> Result<Void, Error> {
        let apiResult: Result<Void, Error> = await authorizationLevelManager.existsAdminCredentials()
            ? await adminApi.addVisit(visit: visit)
            : {
                await authorizationLevelManager.setAuthorizationTokenFor(model: visit)
                return await userApi.addVisit(visit: visit)
            }()

        return await performApiAndDbUpdate(apiResult) {
            _ = try await grdbManager.addAsync(visit).get() // Ignore result but handle errors
        }
    }
    
    @BackgroundActor
    func updateVisit(visit: Visit) async -> Result<Void, Error> {
        let apiResult: Result<Void, Error> = await authorizationLevelManager.existsAdminCredentials()
            ? await adminApi.updateVisit(visit: visit)
            : {
                await authorizationLevelManager.setAuthorizationTokenFor(model: visit)
                return await userApi.updateVisit(visit: visit)
            }()

        return await performApiAndDbUpdate(apiResult) {
            _ = try await grdbManager.editAsync(visit).get() // Ignore result but handle errors
        }
    }
    
    @BackgroundActor
    func deleteVisit(visitId: String) async -> Result<Void, Error> {
        let fetchResult = await grdbManager.fetchByIdAsync(Visit.self, id: visitId)

        guard case .success(let visit) = fetchResult, let unwrappedVisit = visit else {
            return .failure(CustomErrors.NotFound)
        }

        let apiResult = await adminApi.deleteVisit(visit: unwrappedVisit)
        return await performGracefulDeleteUpdate(apiResult) {
            _ = try await grdbManager.deleteAsync(unwrappedVisit).get() // Ignore result but handle errors
        }
    }
    
    // MARK: - PhoneTerritory Methods
    @BackgroundActor
    func addPhoneTerritory(territory: PhoneTerritory, image: UIImage? = nil) async -> Result<Void, Error> {
        let apiResult = image == nil
            ? await adminApi.addPhoneTerritory(phoneTerritory: territory)
            : await adminApi.addPhoneTerritory(phoneTerritory: territory, image: image!)
        
        return await performApiAndDbUpdate(apiResult) {
            _ = try await grdbManager.addAsync(territory).get() // Ignore result but handle errors
        }
    }
    
    @BackgroundActor
    func updatePhoneTerritory(territory: PhoneTerritory, image: UIImage? = nil) async -> Result<Void, Error> {
        // Only proceed if admin credentials exist
        guard await authorizationLevelManager.existsAdminCredentials() else {
            return .failure(CustomErrors.ErrorUploading)
        }

        let apiResult = image == nil
            ? await adminApi.updatePhoneTerritory(phoneTerritory: territory)
            : await adminApi.updatePhoneTerritory(phoneTerritory: territory, image: image!)
        
        return await performApiAndDbUpdate(apiResult) {
            _ = try await grdbManager.editAsync(territory).get() // Ignore result but handle errors
        }
    }
    
    @BackgroundActor
    func deletePhoneTerritory(territoryId: String) async -> Result<Void, Error> {
        let fetchResult = await grdbManager.fetchByIdAsync(PhoneTerritory.self, id: territoryId)
        
        guard case .success(let territory) = fetchResult, let unwrappedTerritory = territory else {
            return .failure(CustomErrors.NotFound)
        }

        let apiResult = await adminApi.deletePhoneTerritory(phoneTerritory: unwrappedTerritory)
        return await performApiAndDbUpdate(apiResult) {
            _ = try await grdbManager.deleteAsync(unwrappedTerritory).get() // Ignore result but handle errors
        }
    }
    
    // MARK: - PhoneNumber Methods
    @BackgroundActor
    func addPhoneNumber(phoneNumber: PhoneNumber) async -> Result<Void, Error> {
        let apiResult = await adminApi.addPhoneNumber(phoneNumber: phoneNumber)
        return await performApiAndDbUpdate(apiResult) {
            _ = try await grdbManager.addAsync(phoneNumber).get() // Ignore result but handle errors
        }
    }
    
    @BackgroundActor
    func updatePhoneNumber(phoneNumber: PhoneNumber) async -> Result<Void, Error> {
        let apiResult = await adminApi.updatePhoneNumber(phoneNumber: phoneNumber)
        return await performApiAndDbUpdate(apiResult) {
            _ = try await grdbManager.editAsync(phoneNumber).get() // Ignore result but handle errors
        }
    }
    
    @BackgroundActor
    func deletePhoneNumber(phoneNumberId: String) async -> Result<Void, Error> {
        let fetchResult = await grdbManager.fetchByIdAsync(PhoneNumber.self, id: phoneNumberId)
        
        guard case .success(let phoneNumber) = fetchResult, let unwrappedPhoneNumber = phoneNumber else {
            return .failure(CustomErrors.NotFound)
        }

        let apiResult = await adminApi.deletePhoneNumber(phoneNumber: unwrappedPhoneNumber)
        return await performApiAndDbUpdate(apiResult) {
            _ = try await grdbManager.deleteAsync(unwrappedPhoneNumber).get() // Ignore result but handle errors
        }
    }
    
    // MARK: - PhoneCall Methods
    @BackgroundActor
    func addPhoneCall(phoneCall: PhoneCall) async -> Result<Void, Error> {
        let apiResult = await authorizationLevelManager.existsAdminCredentials()
            ? await adminApi.addPhoneCall(phoneCall: phoneCall)
            : await userApi.addPhoneCall(phoneCall: phoneCall)

        return await performApiAndDbUpdate(apiResult) {
            _ = try await grdbManager.addAsync(phoneCall).get() // Ignore result but handle errors
        }
    }
    
    @BackgroundActor
    func updatePhoneCall(phoneCall: PhoneCall) async -> Result<Void, Error> {
        let apiResult = await authorizationLevelManager.existsAdminCredentials()
            ? await adminApi.updatePhoneCall(phoneCall: phoneCall)
            : await userApi.updatePhoneCall(phoneCall: phoneCall)

        return await performApiAndDbUpdate(apiResult) {
            _ = try await grdbManager.editAsync(phoneCall).get() // Ignore result but handle errors
        }
    }
    
    @BackgroundActor
    func deletePhoneCall(phoneCallId: String) async -> Result<Void, Error> {
        let fetchResult = await grdbManager.fetchByIdAsync(PhoneCall.self, id: phoneCallId)

        guard case .success(let phoneCall) = fetchResult, let unwrappedPhoneCall = phoneCall else {
            return .failure(CustomErrors.NotFound)
        }

        let apiResult = await adminApi.deletePhoneCall(phoneCall: unwrappedPhoneCall)
        return await performGracefulDeleteUpdate(apiResult) {
            _ = try await grdbManager.deleteAsync(unwrappedPhoneCall).get() // Ignore result but handle errors
        }
    }
    
    // MARK: - Token and TokenTerritory Methods
    @BackgroundActor
    func createToken(newTokenForm: NewTokenForm, territories: [Territory]) async -> Result<Token, Error> {
        let apiResult = await TokenService().createToken(
            name: newTokenForm.name,
            moderator: newTokenForm.moderator,
            territories: newTokenForm.territories,
            congregation: newTokenForm.congregation,
            expire: newTokenForm.expire
        )

        if let token = try? apiResult.get() {
            // Add token to database
            _ = try? await grdbManager.addAsync(token).get()
            
            // Prepare TokenTerritory entries and add them to the database
            let tokenTerritories = territories.map {
                TokenTerritory(token: token.id, territory: $0.id)
            }
            
            for tokenTerritory in tokenTerritories {
                _ = try? await grdbManager.addAsync(tokenTerritory).get()
            }

            return .success(token)
        } else {
            return .failure(NSError(domain: "Could not create token", code: 0, userInfo: nil))
        }
    }
    
    @BackgroundActor
    func editToken(token: String, territories: [Territory]) async -> Result<Void, Error> {
        let territoriesToSend = territories.map { $0.id }
        
        let apiResult = await TokenService().editToken(tokenId: token, territories: territoriesToSend.description)
        return await performApiAndDbUpdate(apiResult) {
            // Remove old token territories
            let fetchResult = await grdbManager.fetchAllAsync(TokenTerritory.self)
            if case .success(let tokenTerritories) = fetchResult {
                for oldTokenTerritory in tokenTerritories where oldTokenTerritory.token == token {
                    _ = try await grdbManager.deleteAsync(oldTokenTerritory).get()
                }
            }
            
            // Add new token territories
            for territory in territories {
                let newTokenTerritory = TokenTerritory(token: token, territory: territory.id)
                _ = try await grdbManager.addAsync(newTokenTerritory).get()
            }
        }
    }
    
    @BackgroundActor
    func deleteToken(tokenId: String) async -> Result<Void, Error> {
        let fetchResult = await grdbManager.fetchByIdAsync(Token.self, id: tokenId)
        
        guard case .success(let token) = fetchResult, let unwrappedToken = token else {
            return .failure(CustomErrors.NotFound)
        }

        let apiResult = await TokenService().deleteToken(token: unwrappedToken.id)
        return await performGracefulDeleteUpdate(apiResult) {
            _ = try await grdbManager.deleteAsync(unwrappedToken).get() // Ignore result but handle errors
        }
    }
    
    // MARK: - Recalls Methods
    @BackgroundActor
    func addRecall(user: String, house: String) async -> Result<Void, Error> {
        let recall = Recalls(id: Date.now.millisecondsSince1970, user: user, house: house)
        let apiResult = await userApi.addRecall(recall: recall)
        return await performApiAndDbUpdate(apiResult) {
            _ = try await grdbManager.addAsync(recall).get() // Ignore result but handle errors
        }
    }
    
    @BackgroundActor
    func deleteRecall(recall: Recalls) async -> Result<Void, Error> {
        let apiResult = await userApi.removeRecall(recall: recall)
        return await performGracefulDeleteUpdate(apiResult) {
            _ = try await grdbManager.deleteAsync(recall).get() // Ignore result but handle errors
        }
    }
    
    //MARK: - Token Registration
    @BackgroundActor
    func unregisterToken(myToken: String) async -> Result<Void, Error> {
        return await TokenService().unregister(token: myToken).map { _ in () }
    }

    @BackgroundActor
    func registerToken(myToken: String) async -> Result<Void, Error> {
        return await TokenService().register(token: myToken).map { _ in () }
    }
    
    @BackgroundActor
    func deleteUserFromToken(userToken: String) async -> Result<Void, Error> {
        let fetchResult = await grdbManager.fetchByIdAsync(UserToken.self, id: userToken)

        guard case .success(let userTokenEntity) = fetchResult, let unwrappedUserToken = userTokenEntity else {
            return .failure(CustomErrors.NotFound)
        }

        let apiResult = await TokenService().removeUserFromToken(token: unwrappedUserToken.token, userId: unwrappedUserToken.userId)
        return await performGracefulDeleteUpdate(apiResult) {
            _ = try await grdbManager.deleteAsync(unwrappedUserToken).get() // Ignore result but handle errors
        }
    }
    
    @BackgroundActor
    func blockUnblockUserFromToken(userToken: UserToken, blocked: Bool) async -> Result<Void, Error> {
        let exists = await grdbManager.exists(UserToken.self, matching: ["userId": userToken.userId, "token": userToken.token])
        
        guard exists else {
            return .failure(CustomErrors.NotFound)
        }

        let apiResult = await TokenService().blockUnblockUserFromToken(token: userToken.token, userId: userToken.userId, blocked: blocked)
        return await performApiAndDbUpdate(apiResult) {
            var updatedUserToken = userToken
            updatedUserToken.blocked = blocked
            _ = try await grdbManager.editAsync(updatedUserToken).get() // Ignore result but handle errors
        }
    }
    
    //MARK: - Perform API and Database Updates
    // Helper for handling API call results and performing a database action
    @BackgroundActor
    private func performApiAndDbUpdate(_ apiResult: Result<Void, Error>, dbAction: () async throws -> Void) async -> Result<Void, Error> {
        // Handle the API result
        if case .failure(let apiError) = apiResult {
            print("🚨 API Error in performApiAndDbUpdate: \(apiError.localizedDescription)")
            if let afError = apiError.asAFError {
                print("🌐 Alamofire Error Details: \(afError)")
            }
            return .failure(apiError)
        }
        
        // Attempt the database action and handle any errors
        do {
            try await dbAction()
            return .success(())
        } catch {
            print("🚨 Database Error in performApiAndDbUpdate: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    // Helper specifically for delete operations - treats "already deleted" as success
    @BackgroundActor
    private func performGracefulDeleteUpdate(_ apiResult: Result<Void, Error>, dbAction: () async throws -> Void) async -> Result<Void, Error> {
        // Check if the API failed due to item already being deleted
        let shouldProceedWithLocalDelete: Bool
        
        print("🔍 performGracefulDeleteUpdate called")
        switch apiResult {
        case .success:
            shouldProceedWithLocalDelete = true
            print("✅ API delete succeeded")
        case .failure(let apiError):
            print("🚨 API delete failed: \(apiError.localizedDescription)")
            print("🔍 Error type: \(type(of: apiError))")
            
            // Check if this is a "graceful failure" (item already deleted)
            var isGracefulFailure = false
            
            // Check for our custom errors first (from HTML detection)
            if let customError = apiError as? CustomErrors {
                switch customError {
                case .ServerBlocked:
                    print("📝 ServerBlocked error - Item likely already deleted, proceeding with local deletion")
                    isGracefulFailure = true
                case .CaptchaRequired:
                    print("📝 CaptchaRequired error - Item likely already deleted, proceeding with local deletion")
                    isGracefulFailure = true
                case .NotFound:
                    print("📝 NotFound error - Item already deleted, proceeding with local deletion")
                    isGracefulFailure = true
                default:
                    break
                }
            }
            
            if let afError = apiError.asAFError {
                // HTTP 404 (Not Found) or 500 (Server Error) often mean "already deleted"
                if let responseCode = afError.responseCode {
                    switch responseCode {
                    case 404:
                        print("📝 404 Not Found - Item likely already deleted, proceeding with local deletion")
                        isGracefulFailure = true
                    case 500:
                        print("📝 500 Server Error - Item likely already deleted, proceeding with local deletion")
                        isGracefulFailure = true
                    default:
                        break
                    }
                }
            }
            
            // Also check for specific error messages that indicate item not found
            let errorMessage = apiError.localizedDescription.lowercased()
            print("🔍 Analyzing error message: '\(errorMessage)'")
            
            if errorMessage.contains("server error ocurred") || 
               errorMessage.contains("server error occurred") ||
               errorMessage.contains("not found") ||
               errorMessage.contains("doesn't exist") ||
               errorMessage.contains("no se ha podido completar") ||
               errorMessage.contains("operación cancelada") {
                print("📝 Error message suggests item already deleted, proceeding with local deletion")
                isGracefulFailure = true
            }
            
            shouldProceedWithLocalDelete = isGracefulFailure
            
            print("🔍 Final graceful failure decision: \(isGracefulFailure)")
            
            if !isGracefulFailure {
                print("❌ API delete failed with non-graceful error, not deleting locally")
                return .failure(apiError)
            } else {
                print("✅ Treating as graceful failure, will proceed with local deletion")
            }
        }
        
        // Attempt the database action if we should proceed
        if shouldProceedWithLocalDelete {
            do {
                try await dbAction()
                print("✅ Local deletion completed successfully")
                return .success(())
            } catch {
                print("🚨 Database Error in performGracefulDeleteUpdate: \(error.localizedDescription)")
                return .failure(error)
            }
        } else {
            return .failure(NSError(domain: "DeleteError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to delete item"]))
        }
    }

    // Helper for safely fetching an entity from the database
    @BackgroundActor
    private func fetchEntity<T: FetchableRecord & MutablePersistableRecord & Sendable>(_ type: T.Type, id: String) async -> Result<T, Error> {
        guard let entity = try? await grdbManager.fetchByIdAsync(type, id: id).get() else {
            return .failure(CustomErrors.NotFound)
        }
        return .success(entity)
    }
}
