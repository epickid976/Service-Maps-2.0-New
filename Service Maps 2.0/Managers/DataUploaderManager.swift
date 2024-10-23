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


class DataUploaderManager: ObservableObject {
    
    @Published private var authorizationLevelManager = AuthorizationLevelManager()
    @Published private var dataStore = StorageManager.shared
    @Published private var synchronizationManager = SynchronizationManager.shared
    
    private var adminApi = AdminService()
    private var userApi = UserService()
    private var tokenApi = TokenService()
    
    @ObservedObject private var grdbManager = GRDBManager.shared
    
    // MARK: - Territory Methods
    @BackgroundActor
    func addTerritory(territory: Territory, image: UIImage? = nil) async -> Result<Void, Error> {
        let result = image == nil ? await adminApi.addTerritory(territory: territory)
        : await adminApi.addTerritory(territory: territory, image: image!)
        
        switch result {
        case .success:
            return await grdbManager.addAsync(territory).map { _ in () }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func updateTerritory(territory: Territory, image: UIImage? = nil) async -> Result<Void, Error> {
        let result = image != nil ? await adminApi.updateTerritory(territory: territory, image: image!) : await adminApi.updateTerritory(territory: territory)
        
        switch result {
        case .success:
            return await grdbManager.editAsync(territory).map { _ in () }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func deleteTerritory(territoryId: String) async -> Result<Void, Error> {
        let result = await grdbManager.fetchByIdAsync(Territory.self, id: territoryId)
        
        switch result {
        case .success(let territory):
            guard let territory = territory else {
                return .failure(CustomErrors.NotFound)
            }
            
            let apiResult = await adminApi.deleteTerritory(territory: territory)
            
            switch apiResult {
            case .success:
                let dbResult = await grdbManager.deleteAsync(territory).map { _ in () }
                return dbResult
            case .failure(let error):
                return .failure(error)
            }
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - TerritoryAddress Methods
    @BackgroundActor
    func addTerritoryAddress(territoryAddress: TerritoryAddress) async -> Result<Void, Error> {
        let result = await adminApi.addTerritoryAddress(territoryAddress: territoryAddress)
        
        switch result {
        case .success:
            return await grdbManager.addAsync(territoryAddress).map { _ in () }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func deleteTerritoryAddress(territoryAddressId: String) async -> Result<Void, Error> {
        let result = await grdbManager.fetchByIdAsync(TerritoryAddress.self, id: territoryAddressId)
        
        switch result {
        case .success(let territoryAddress):
            guard let territoryAddress = territoryAddress else {
                return .failure(CustomErrors.NotFound)
            }
            
            let apiResult = await adminApi.deleteTerritoryAddress(territoryAddress: territoryAddress)
            
            switch apiResult {
            case .success:
                let dbResult = await grdbManager.deleteAsync(territoryAddress).map { _ in () }
                return dbResult
            case .failure(let error):
                return .failure(error)
            }
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func updateTerritoryAddress(territoryAddress: TerritoryAddress) async -> Result<Void, Error> {
        let result = await adminApi.updateTerritoryAddress(territoryAddress: territoryAddress)
        
        switch result {
        case .success:
            return await grdbManager.editAsync(territoryAddress).map { _ in () }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - House Methods
    @BackgroundActor
    func addHouse(house: House) async -> Result<Void, Error> {
        let result = await adminApi.addHouse(house: house)
        
        switch result {
        case .success:
            return await grdbManager.addAsync(house).map { _ in () }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func deleteHouse(houseId: String) async -> Result<Void, Error> {
        let result = await grdbManager.fetchByIdAsync(House.self, id: houseId)
        
        switch result {
        case .success(let house):
            guard let house = house else {
                return .failure(CustomErrors.NotFound)
            }
            
            let apiResult = await adminApi.deleteHouse(house: house)
            
            switch apiResult {
            case .success:
                let dbResult = await grdbManager.deleteAsync(house).map { _ in () }
                return dbResult
            case .failure(let error):
                return .failure(error)
            }
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Visit Methods
    @BackgroundActor
    func addVisit(visit: Visit) async -> Result<Void, Error> {
        let result: Result<Void, Error>
        
        if await authorizationLevelManager.existsAdminCredentials() {
            result = await adminApi.addVisit(visit: visit)
        } else {
            // Simply await the function if it returns Void
            await authorizationLevelManager.setAuthorizationTokenFor(model: visit)
            result = await userApi.addVisit(visit: visit)
        }
        
        switch result {
        case .success:
            return await grdbManager.addAsync(visit).map { _ in () }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func updateVisit(visit: Visit) async -> Result<Void, Error> {
        let result: Result<Void, Error>
        
        if await authorizationLevelManager.existsAdminCredentials() {
            result = await adminApi.updateVisit(visit: visit)
        } else {
            // Same as before, await this if it's Void
            await authorizationLevelManager.setAuthorizationTokenFor(model: visit)
            result = await userApi.updateVisit(visit: visit)
        }
        
        switch result {
        case .success:
            return await grdbManager.editAsync(visit).map { _ in () }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func deleteVisit(visitId: String) async -> Result<Void, Error> {
        let result = await grdbManager.fetchByIdAsync(Visit.self, id: visitId)
        
        switch result {
        case .success(let visit):
            guard let visit = visit else {
                return .failure(CustomErrors.NotFound)
            }
            let apiResult = await adminApi.deleteVisit(visit: visit)
            
            switch apiResult {
            case .success:
                return await grdbManager.deleteAsync(visit).map { _ in () }
            case .failure(let error):
                return .failure(error)
            }
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - PhoneTerritory Methods
    @BackgroundActor
    func addPhoneTerritory(territory: PhoneTerritory, image: UIImage? = nil) async -> Result<Void, Error> {
        let result: Result<Void, Error>
        if let image = image {
            result = await adminApi.addPhoneTerritory(phoneTerritory: territory, image: image)
        } else {
            result = await adminApi.addPhoneTerritory(phoneTerritory: territory)
        }
        
        switch result {
        case .success:
            return await grdbManager.addAsync(territory).map { _ in () }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func updatePhoneTerritory(territory: PhoneTerritory, image: UIImage? = nil) async -> Result<Void, Error> {
        let result: Result<Void, Error>
        if await authorizationLevelManager.existsAdminCredentials() {
            result = image == nil ?
            await adminApi.updatePhoneTerritory(phoneTerritory: territory) :
            await adminApi.updatePhoneTerritory(phoneTerritory: territory, image: image!)
        } else {
            return .failure(CustomErrors.ErrorUploading)
        }
        
        switch result {
        case .success:
            return await grdbManager.editAsync(territory).map { _ in () }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func deletePhoneTerritory(territoryId: String) async -> Result<Void, Error> {
        let result = await grdbManager.fetchByIdAsync(PhoneTerritory.self, id: territoryId)
        
        switch result {
        case .success(let territory):
            guard let territory = territory else {
                return .failure(CustomErrors.NotFound)
            }
            let apiResult = await adminApi.deletePhoneTerritory(phoneTerritory: territory)
            switch apiResult {
            case .success:
                return await grdbManager.deleteAsync(territory).map { _ in () }
            case .failure(let error):
                return .failure(error)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - PhoneNumber Methods
    @BackgroundActor
    func addPhoneNumber(phoneNumber: PhoneNumber) async -> Result<Void, Error> {
        let result = await adminApi.addPhoneNumber(phoneNumber: phoneNumber)
        switch result {
        case .success:
            return await grdbManager.addAsync(phoneNumber).map { _ in () }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func updatePhoneNumber(phoneNumber: PhoneNumber) async -> Result<Void, Error> {
        let result = await adminApi.updatePhoneNumber(phoneNumber: phoneNumber)
        switch result {
        case .success:
            return await grdbManager.editAsync(phoneNumber).map { _ in () }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func deletePhoneNumber(phoneNumberId: String) async -> Result<Void, Error> {
        let result = await grdbManager.fetchByIdAsync(PhoneNumber.self, id: phoneNumberId)
        
        switch result {
        case .success(let phoneNumber):
            guard let phoneNumber = phoneNumber else {
                return .failure(CustomErrors.NotFound)
            }
            let apiResult = await adminApi.deletePhoneNumber(phoneNumber: phoneNumber)
            switch apiResult {
            case .success:
                return await grdbManager.deleteAsync(phoneNumber).map { _ in () }
            case .failure(let error):
                return .failure(error)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - PhoneCall Methods
    @BackgroundActor
    func addPhoneCall(phoneCall: PhoneCall) async -> Result<Void, Error> {
        let result = if await authorizationLevelManager.existsAdminCredentials() {
            await adminApi.addPhoneCall(phoneCall: phoneCall)
        } else {
            await userApi.addPhoneCall(phoneCall: phoneCall)
        }
        
        switch result {
        case .success:
            return await grdbManager.addAsync(phoneCall).map { _ in () }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func updatePhoneCall(phoneCall: PhoneCall) async -> Result<Void, Error> {
        let result = if await authorizationLevelManager.existsAdminCredentials() {
            await adminApi.updatePhoneCall(phoneCall: phoneCall)
        } else {
            await userApi.updatePhoneCall(phoneCall: phoneCall)
        }
        
        switch result {
        case .success:
            return await grdbManager.editAsync(phoneCall).map { _ in () }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func deletePhoneCall(phoneCallId: String) async -> Result<Void, Error> {
        let result = await grdbManager.fetchByIdAsync(PhoneCall.self, id: phoneCallId)
        
        switch result {
        case .success(let phoneCall):
            guard let phoneCall = phoneCall else {
                return .failure(CustomErrors.NotFound)
            }
            let apiResult = await adminApi.deletePhoneCall(phoneCall: phoneCall)
            switch apiResult {
            case .success:
                return await grdbManager.deleteAsync(phoneCall).map { _ in () }
            case .failure(let error):
                return .failure(error)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Token and TokenTerritory Methods
    @BackgroundActor
    func createToken(newTokenForm: NewTokenForm, territories: [Territory]) async -> Result<Token, Error> {
        let token = await tokenApi.createToken(name: newTokenForm.name, moderator: newTokenForm.moderator, territories: newTokenForm.territories, congregation: newTokenForm.congregation, expire: newTokenForm.expire)
        
        var tokenTerritories = [TokenTerritory]()
        if let tokenUnwrapped = try? token.get() {
            _ = await grdbManager.addAsync(tokenUnwrapped)
            
            for territory in territories {
                let newTokenTerritory = TokenTerritory(token: tokenUnwrapped.id, territory: territory.id)
                tokenTerritories.append(newTokenTerritory)
            }
            
            for tokenTerritory in tokenTerritories {
                _ = await grdbManager.addAsync(tokenTerritory)
            }
            
            return .success(tokenUnwrapped)
        } else {
            return .failure(NSError(domain: "Could not create token", code: 0, userInfo: nil))
        }
    }
    
    @BackgroundActor
    func editToken(token: String, territories: [Territory]) async -> Result<Void, Error> {
        let territoriesToSend = territories.map { $0.id }
        
        let result = await tokenApi.editToken(tokenId: token, territories: territoriesToSend.description)
        
        switch result {
        case .success:
            let fetchResult = await grdbManager.fetchAllAsync(TokenTerritory.self)
            
            switch fetchResult {
            case .success(let tokenTerritories):
                for oldTokenTerritory in tokenTerritories where oldTokenTerritory.token == token {
                    _ = await grdbManager.deleteAsync(oldTokenTerritory)
                }
                for territory in territories {
                    let newTokenTerritory = TokenTerritory(token: token, territory: territory.id)
                    _ = await grdbManager.addAsync(newTokenTerritory)
                }
                return .success(())
            case .failure(let fetchError):
                return .failure(fetchError)
            }
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func deleteToken(tokenId: String) async -> Result<Void, Error> {
        let result = await grdbManager.fetchByIdAsync(Token.self, id: tokenId)
        
        switch result {
        case .success(let token):
            guard let token = token else {
                return .failure(CustomErrors.NotFound)
            }
            let apiResult = await tokenApi.deleteToken(token: token.id)
            
            switch apiResult {
            case .success:
                return await grdbManager.deleteAsync(token).map { _ in () }
            case .failure(let error):
                return .failure(error)
            }
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Recalls Methods
    @BackgroundActor
    func addRecall(user: String, house: String) async -> Result<Void, Error> {
        let recall = Recalls(id: Date.now.millisecondsSince1970, user: user, house: house)
        
        let result = await userApi.addRecall(recall: recall)
        
        switch result {
        case .success:
            return await grdbManager.addAsync(recall).map { _ in () }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func deleteRecall(recall: Recalls) async -> Result<Void, Error> {
        let result = await userApi.removeRecall(recall: recall)
        
        switch result {
        case .success:
            return await grdbManager.deleteAsync(recall).map { _ in () }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func unregisterToken(myToken: String) async -> Result<Void, Error> {
        let result = await tokenApi.unregister(token: myToken)
        
        return result.map { _ in () }
    }
    
    @BackgroundActor
    func registerToken(myToken: String) async -> Result<Void, Error> {
        let result = await tokenApi.register(token: myToken)
        
        return result.map { _ in () }
    }
    
    @BackgroundActor
    func deleteUserFromToken(userToken: String) async -> Result<Void, Error> {
        let result = await grdbManager.fetchByIdAsync(UserToken.self, id: userToken)
        
        switch result {
        case .success(let userTokenEntity):
            guard let userTokenEntity = userTokenEntity else {
                return .failure(CustomErrors.NotFound)
            }
            let apiResult = await tokenApi.removeUserFromToken(token: userTokenEntity.token, userId: userTokenEntity.userId)
            
            switch apiResult {
            case .success:
                return await grdbManager.deleteAsync(userTokenEntity).map { _ in () }
            case .failure(let error):
                return .failure(error)
            }
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    @BackgroundActor
    func blockUnblockUserFromToken(userToken: String, blocked: Bool) async -> Result<Void, Error> {
        let result = await grdbManager.fetchByIdAsync(UserToken.self, id: userToken)
        
        switch result {
        case .success(let userTokenEntity):
            guard let userTokenEntity = userTokenEntity else {
                return .failure(CustomErrors.NotFound)
            }
            let apiResult = await tokenApi.blockUnblockUserFromToken(token: userTokenEntity.token, userId: userTokenEntity.userId, blocked: blocked)
            
            switch apiResult {
            case .success:
                let updatedUserToken = UserToken(
                    token: userTokenEntity.token,
                    userId: userTokenEntity.userId,
                    name: userTokenEntity.name,
                    blocked: blocked
                )
                return await grdbManager.editAsync(updatedUserToken).map { _ in () }
            case .failure(let error):
                return .failure(error)
            }
            
        case .failure(let error):
            return .failure(error)
        }
    }
}
