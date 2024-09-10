//
//  DataUploaderManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/27/23.
//

import Foundation
import BackgroundTasks
import SwiftUI
import RealmSwift

class DataUploaderManager: ObservableObject {
    
    @Published private var authorizationLevelManager = AuthorizationLevelManager()
    @Published private var realmManager = RealmManager.shared
    @Published private var dataStore = StorageManager.shared
    @Published private var synchronizationManager = SynchronizationManager.shared
    var realm: Realm
    
    init() {
            realm = try! Realm()
            
            territoryEntities = realm.objects(TerritoryObject.self)
            addressesEntities = realm.objects(TerritoryAddressObject.self)
            housesEntities = realm.objects(HouseObject.self)
            visitsEntities = realm.objects(VisitObject.self)
            tokensEntities = realm.objects(TokenObject.self)
            tokenTerritoryEntities = realm.objects(TokenTerritoryObject.self)
            userTokenEntities = realm.objects(UserTokenObject.self)
    }
    
    let territoryEntities: Results<TerritoryObject>
    let addressesEntities: Results<TerritoryAddressObject>
    let housesEntities: Results<HouseObject>
    let visitsEntities: Results<VisitObject>
    let tokensEntities: Results<TokenObject>
    let tokenTerritoryEntities: Results<TokenTerritoryObject>
    let userTokenEntities: Results<UserTokenObject>
    
    private var adminApi = AdminAPI()
    private var userApi = UserAPI()
    private var tokenApi = TokenAPI()
    
    func addTerritory(territory: TerritoryObject, image: UIImage? = nil) async -> Result<Bool, Error> {
        
        var result: Result<Bool, Error>?
        
        if(image == nil) {
            do {
                try await adminApi.addTerritory(territory: convertTerritoryToTerritoryModel(model: territory))
                result = Result.success(true)
            } catch {
                result = Result.failure(error)
            }
        } else {
            //Add IMAGE Function here
            do {
                try await adminApi.addTerritory(territory: convertTerritoryToTerritoryModel(model: territory), image: image!)
                result = Result.success(true)
            } catch {
                result = Result.failure(error)
            }
        }
        
        switch result {
        case .success(true):
            return realmManager.addModel(territory)
        default:
            print("Si no se pudo no se pudo (DatauploaderManager ADD TERRITORY)")
        }
        
        return result ?? Result.failure(CustomErrors.ErrorUploading)
    }
    
    func addTerritoryAddress(territoryAddress: TerritoryAddressObject) async -> Result<Bool, Error> {
        
        
        var result: Result<Bool, Error>?
        
        do {
            try await adminApi.addTerritoryAddress(territoryAddress: convertTerritoryToTerritoryAddressModel(model: territoryAddress))
            result = Result.success(true)
        } catch {
            result = Result.failure(error)
        }
        
        switch result {
        case .success(true):
           return realmManager.addModel(territoryAddress)
        default:
            print("Si no se pudo no se pudo (DatauploaderManager ADD TERRITORYADDRESS)")
        }
        
        return result ?? Result.failure(CustomErrors.ErrorUploading)
    }
    
    func addHouse(house: HouseObject) async -> Result<Bool, Error> {
        
        
        var result: Result<Bool, Error>?
        
        do {
            try await adminApi.addHouse(house: convertHouseToHouseModel(model: house))
            result = Result.success(true)
        } catch {
            result = Result.failure(error)
        }
        
        switch result {
        case .success(true):
            return realmManager.addModel(house)
        default:
            print("Si no se pudo no se pudo (DatauploaderManager ADD HOUSE)")
        }
        
        return result ?? Result.failure(CustomErrors.ErrorUploading)
    }
   
    func addVisit(visit: VisitObject) async -> Result<Bool, Error> {
        
        var result: Result<Bool, Error>?
        
        do {
            if authorizationLevelManager.existsAdminCredentials() {
                try await adminApi.addVisit(visit: convertVisitToVisitModel(model: visit))
                result = Result.success(true)
            } else {
                await authorizationLevelManager.setAuthorizationTokenFor(model: visit)
                try await userApi.addVisit(visit: convertVisitToVisitModel(model: visit))
                result = Result.success(true)
            }
        } catch {
            result = Result.failure(error)
        }
        
        switch result {
        case .success(true):
            return realmManager.addModel(visit)
        default:
            print("Si no se pudo no se pudo (DatauploaderManager ADD VISIT)")
        }
        
        return result ?? Result.failure(CustomErrors.ErrorUploading)
    }
    
    func updateTerritory(territory: TerritoryObject, image: UIImage? = nil) async -> Result<Bool, Error> {
        
        
        var result: Result<Bool, Error>?
        
        
        if authorizationLevelManager.existsAdminCredentials() {
            if image == nil {
                do {
                    try await adminApi.updateTerritory(territory: convertTerritoryToTerritoryModel(model: territory))
                    result = Result.success(true)
                } catch {
                    result = Result.failure(error)
                }
            } else {
                do {
                    try await adminApi.updateTerritory(territory: convertTerritoryToTerritoryModel(model: territory), image: image!)
                    result = Result.success(true)
                } catch {
                    result = Result.failure(error)
                }
            }
        } else {
            await authorizationLevelManager.setAuthorizationTokenFor(model: territory)
            if image == nil {
                do {
                    try await userApi.updateTerritory(territory: convertTerritoryToTerritoryModel(model: territory))
                    result = Result.success(true)
                } catch {
                    result = Result.failure(error)
                }
            } else {
                do {
                    try await userApi.updateTerritory(territory: convertTerritoryToTerritoryModel(model: territory), image: image!)
                    result = Result.success(true)
                } catch {
                    result = Result.failure(error)
                }
            }
        }
        
        switch result {
        case .success(true):
            return realmManager.updateTerritory(territory: convertTerritoryToTerritoryModel(model: territory))
        default:
            print("Si no se pudo no se pudo (DatauploaderManager UPDATETERRITORY)")
        }
        
        return result ?? Result.failure(CustomErrors.ErrorUploading)
    }
    
    
    func updateTerritoryAddress(territoryAddress: TerritoryAddressObject) async -> Result<Bool, Error> {
        
        
        var result: Result<Bool, Error>?
        
        if authorizationLevelManager.existsAdminCredentials() {
            do {
                try await adminApi.updateTerritoryAddress(territoryAddress: convertTerritoryToTerritoryAddressModel(model: territoryAddress))
                result = Result.success(true)
            } catch {
                result = Result.failure(error)
            }
        } else {
            await authorizationLevelManager.setAuthorizationTokenFor(model: territoryAddress)
            do {
                try await userApi.updateTerritoryAddress(territoryAddress: convertTerritoryToTerritoryAddressModel(model: territoryAddress))
                result = Result.success(true)
            } catch {
                result = Result.failure(error)
            }
        }
        
        switch result {
        case .success(true):
            return realmManager.updateAddress(address: convertTerritoryToTerritoryAddressModel(model: territoryAddress))
        default:
            print("Si no se pudo no se pudo (DatauploaderManager UPDATETERRITORYADDRESS)")
        }
        
        return result ?? Result.failure(CustomErrors.ErrorUploading)
    }
    
    func updateHouse(house: HouseObject) async -> Result<Bool, Error> {
        
        var result: Result<Bool, Error>?
        
        if authorizationLevelManager.existsAdminCredentials() {
            do {
                try await adminApi.updateHouse(house: convertHouseToHouseModel(model: house))
                result = Result.success(true)
            } catch {
                result = Result.failure(error)
            }
        } else {
            await authorizationLevelManager.setAuthorizationTokenFor(model: house)
            do {
                try await userApi.updateHouse(house: convertHouseToHouseModel(model: house))
                result = Result.success(true)
            } catch {
                result = Result.failure(error)
            }
        }
        
        switch result {
        case .success(true):
            return realmManager.updateHouse(house: convertHouseToHouseModel(model: house))
        default:
            print("Si no se pudo no se pudo (DatauploaderManager UPDATEHOUSE)")
        }
        
        return result ?? Result.failure(CustomErrors.ErrorUploading)
    }
    
    func updateVisit(visit: VisitObject) async -> Result<Bool, Error> {
        
        var result: Result<Bool, Error>?
        
        if authorizationLevelManager.existsAdminCredentials() {
            do {
                try await adminApi.updateVisit(visit: convertVisitToVisitModel(model: visit))
                result = Result.success(true)
            } catch {
                result = Result.failure(error)
            }
        } else {
            await authorizationLevelManager.setAuthorizationTokenFor(model: visit)
            do {
                try await userApi.updateVisit(visit: convertVisitToVisitModel(model: visit))
                result = Result.success(true)
            } catch {
                result = Result.failure(error)
            }
        }
        
        switch result {
        case .success(true):
            return realmManager.updateVisit(visit: convertVisitToVisitModel(model: visit))
        default:
            print("Si no se pudo no se pudo (DatauploaderManager UPDATEVISIT)")
        }
        
        return result ?? Result.failure(CustomErrors.ErrorUploading)
    }
    
    @MainActor
    func deleteTerritory(territory: String) async -> Result<Bool, Error> {
        do {
            let realm = try! await Realm()
            if let territoryToDelete = realm.objects(TerritoryObject.self).filter("id == %d", territory).first {
                try await adminApi.deleteTerritory(territory: convertTerritoryToTerritoryModel(model: territoryToDelete))
                return realmManager.deleteTerritory(territory: territoryToDelete)
            }
            return Result.failure(CustomErrors.NotFound)
        } catch {
            print("THIS IS THE ERROR FROM DELETE TERRITORY \(error)")
            return Result.failure(error)
        }
    }
    
    @MainActor
    func deleteTerritoryAddress(territoryAddress: String) async -> Result<Bool, Error> {
        
        do {
            let realm = try! await Realm()
            if let addressToDelete = realm.objects(TerritoryAddressObject.self).filter("id == %d", territoryAddress).first {
                try await adminApi.deleteTerritoryAddress(territoryAddress: convertTerritoryToTerritoryAddressModel(model: addressToDelete))
                return realmManager.deleteAddress(address: addressToDelete)
            }
            return Result.failure(CustomErrors.NotFound)
           //return realmManager.deleteTerritory(territory: territory)
        } catch {
            print("THIS IS THE ERROR FROM DELETE TERRITORY \(error)")
            return Result.failure(error)
        }
    }
    
    @MainActor
    func deleteHouse(house: String) async -> Result<Bool, Error> {
        
        do {
            let realm = try! await Realm()
            if let houseToDelete = realm.objects(HouseObject.self).filter("id == %d", house).first {
                try await adminApi.deleteHouse(house: convertHouseToHouseModel(model: houseToDelete))
                return realmManager.deleteHouse(house: houseToDelete)
            }
            return Result.failure(CustomErrors.NotFound)
        } catch {
            return Result.failure(error)
        }
    }
    
    @MainActor
    func deleteVisit(visit: String) async -> Result<Bool, Error> {
        
        do {
            let realm = try! await Realm()
            if let visitToDelete = realm.objects(VisitObject.self).filter("id == %d", visit).first {
                try await adminApi.deleteVisit(visit: convertVisitToVisitModel(model: visitToDelete))
                return realmManager.deleteVisit(visit: visitToDelete)
            }
            return Result.failure(CustomErrors.NotFound)
        } catch {
            return Result.failure(error)
        }
    }
    
    
    
    func createToken(newTokenForm: NewTokenForm, territories: [TerritoryObject]) async -> Result<TokenObject, Error> {
        do {
            let token = try await tokenApi.createToken(name: newTokenForm.name, moderator: newTokenForm.moderator, territories: newTokenForm.territories, congregation: newTokenForm.congregation, expire: newTokenForm.expire)
            
            var tokenTerritories = [TokenTerritoryObject]()
            
            let tokenObject = TokenObject().createTokenObject(from: token)
            
            _ = realmManager.addModel(tokenObject)
            
            for territory in territories {
                let newTokenTerritory = TokenTerritoryObject()
                newTokenTerritory.token = tokenObject.id
                newTokenTerritory.territory = territory.id
                tokenTerritories.append(newTokenTerritory)
            }
            
            tokenTerritories.forEach { tokenTerritory in
                _ = realmManager.addModel(tokenTerritory)
            }
            
            return Result.success(tokenObject)
            
        } catch {
            return Result.failure(error)
        }
    }
    
    @MainActor
    func editToken(token: String, territories: [TerritoryObject]) async -> Result<Bool, Error> {
        do {
            var territoriesToSend = [String]()
            territories.forEach { territory in
                territoriesToSend.append(territory.id)
            }
            
            try await tokenApi.editToken(tokenId: token, territories: territoriesToSend.description)
            
            var tokenTerritories = [TokenTerritoryObject]()
            
            tokenTerritoryEntities.forEach { oldTokenTerritory in
                if token == oldTokenTerritory.token {
                    _ = realmManager.deleteTokenTerritory(tokenTerritory: oldTokenTerritory)
                }
            }
            
            territories.forEach { territory in
                let newTokenTerritory = TokenTerritoryObject()
                newTokenTerritory.token = token
                newTokenTerritory.territory = territory.id
                tokenTerritories.append(newTokenTerritory)
            }
            
            tokenTerritories.forEach { tokenTerritory in
                _ = realmManager.addModel(tokenTerritory)
            }
            
            return Result.success(true)
        } catch {
            return Result.failure(error)
        }
    }
    
    @MainActor
    func deleteToken(myToken: String) async -> Result<Bool, Error> {
        do {
            let realm = try! await Realm()
            if let keyToDelete = realm.objects(TokenObject.self).filter("id == %d", myToken).first {
                try await tokenApi.deleteToken(token: keyToDelete.id)
                    tokenTerritoryEntities.forEach { tokenTerritory in
                        if keyToDelete.id == tokenTerritory.token {
                            _ = realmManager.deleteTokenTerritory(tokenTerritory: tokenTerritory)
                        }
                    }
                _ = realmManager.deleteToken(token: keyToDelete)
                return Result.success(true)
            }
            return Result.failure(CustomErrors.NotFound)
        } catch {
            return Result.failure(error)
        }
    }
    
    @MainActor
    func unregisterToken(myToken: String) async -> Result<Bool, Error> {
        do {
           try await tokenApi.unregister(token: myToken)
            return Result.success(true)
        } catch {
            return Result.failure(error)
        }
    }
    
    @MainActor
    func registerToken(myToken: String) async -> Result<Bool, Error> {
        do {
            try await tokenApi.register(token: myToken)
            return Result.success(true)
        } catch {
            return Result.failure(error)
        }
    }
    
    func addPendingChange(pendingChange: PendingChange) async {
        dataStore.pendingChanges.append(pendingChange)
        //Schedule background task
        //ReuploaderWorker.shared.scheduleReupload(minutes: 15.0)
    }
    
    func getAllPendingChanges() async -> [PendingChange] {
        return dataStore.pendingChanges
    }
    
    func addPhoneTerritory(territory: PhoneTerritoryObject, image: UIImage? = nil) async -> Result<Bool, Error> {
        var result: Result<Bool, Error>?
        
        if(image == nil) {
            do {
                try await adminApi.addPhoneTerritory(territory: convertPhoneTerritoryModelToPhoneTerritoryModel(model: territory))
                result = Result.success(true)
            } catch {
                result = Result.failure(error)
            }
        } else {
            //Add IMAGE Function here
            do {
                try await adminApi.addPhoneTerritory(territory: convertPhoneTerritoryModelToPhoneTerritoryModel(model: territory), image: image!)
                result = Result.success(true)
            } catch {
                result = Result.failure(error)
            }
        }
        
        switch result {
        case .success(true):
            return realmManager.addModel(territory)
        default:
            print("Si no se pudo no se pudo (DatauploaderManager ADD TERRITORY)")
        }
        
        return result ?? Result.failure(CustomErrors.ErrorUploading)
    }
    
    func updatePhoneTerritory(territory: PhoneTerritoryObject, image: UIImage? = nil) async -> Result<Bool, Error> {
        
        
        var result: Result<Bool, Error>?
        
        
        if authorizationLevelManager.existsAdminCredentials() {
            if image == nil {
                do {
                    try await adminApi.updatePhoneTerritory(territory: convertPhoneTerritoryModelToPhoneTerritoryModel(model: territory))
                    result = Result.success(true)
                } catch {
                    result = Result.failure(error)
                }
            } else {
                do {
                    try await adminApi.updatePhoneTerritory(territory: convertPhoneTerritoryModelToPhoneTerritoryModel(model: territory), image: image!)
                    result = Result.success(true)
                } catch {
                    result = Result.failure(error)
                }
            }
        }
        
        switch result {
        case .success(true):
            return realmManager.updatePhoneTerritory(phoneTerritory: convertPhoneTerritoryModelToPhoneTerritoryModel(model: territory))
        default:
            print("Si no se pudo no se pudo (DatauploaderManager UPDATETERRITORY)")
        }
        
        return result ?? Result.failure(CustomErrors.ErrorUploading)
    }
    
    @MainActor
    func deleteTerritory(phoneTerritory: String) async -> Result<Bool, Error> {
        
        do {
            let realm = try! await Realm()
            if let territoryToDelete = realm.objects(PhoneTerritoryObject.self).filter("id == %d", phoneTerritory).first {
                try await adminApi.deletePhoneTerritory(territory: convertPhoneTerritoryModelToPhoneTerritoryModel(model: territoryToDelete))
                return realmManager.deletePhoneTerritory(phoneTerritory: territoryToDelete)
            }
            
            return Result.failure(CustomErrors.NotFound)
           //return realmManager.deleteTerritory(territory: territory)
        } catch {
            print("THIS IS THE ERROR FROM DELETE TERRITORY \(error)")
            return Result.failure(error)
        }
    }
    
    @MainActor
    func deleteNumber(number: String) async -> Result<Bool, Error> {
        
        do {
            let realm = try! await Realm()
            if let numberToDelete = realm.objects(PhoneNumberObject.self).filter("id == %d", number).first {
                try await adminApi.deletePhoneNumber(number: convertPhoneNumberModelToPhoneNumberModel(model: numberToDelete))
                return realmManager.deletePhoneNumber(phoneNumber: numberToDelete)
            }
            
            return Result.failure(CustomErrors.NotFound)
           //return realmManager.deleteTerritory(territory: territory)
        } catch {
            print("THIS IS THE ERROR FROM DELETE TERRITORY \(error)")
            return Result.failure(error)
        }
    }
    
    func addNumber(number: PhoneNumberObject) async -> Result<Bool, Error> {
        
        
        var result: Result<Bool, Error>?
        
        do {
            try await adminApi.addPhoneNumber(number: convertPhoneNumberModelToPhoneNumberModel(model: number))
            result = Result.success(true)
        } catch {
            result = Result.failure(error)
        }
        
        switch result {
        case .success(true):
            return realmManager.addModel(number)
        default:
            print("Si no se pudo no se pudo (DatauploaderManager ADD HOUSE)")
        }
        
        return result ?? Result.failure(CustomErrors.ErrorUploading)
    }
    
    func addCall(call: PhoneCallObject) async -> Result<Bool, Error> {
        do {
            if authorizationLevelManager.existsAdminCredentials() {
                try await adminApi.addCall(call: convertPhoneCallModelToPhoneCallModel(model: call))
            } else {
                try await userApi.addCall(call: convertPhoneCallModelToPhoneCallModel(model: call))
            }
            return realmManager.addModel(call)
        } catch {
            print(error)
            return .failure(error)
        }
    }
    
    @MainActor
    func deleteCall(call: String) async -> Result<Bool, Error> {
        do {
            let realm = try await Realm()
            guard let callToDelete = realm.objects(PhoneCallObject.self).filter("id == %d", call).first else {
                return .failure(CustomErrors.NotFound)
            }
            
            try await adminApi.deleteCall(call: convertPhoneCallModelToPhoneCallModel(model: callToDelete))
            return realmManager.deletePhoneCall(phoneCall: callToDelete)
                .map { _ in true }
        } catch {
            print("Error deleting call: \(error)")
            return .failure(error)
        }
    }
    
    func updateNumber(number: PhoneNumberObject) async -> Result<Bool, Error> {
        
        
        var result: Result<Bool, Error>?
        
        do {
            try await adminApi.updatePhoneNumber(number: convertPhoneNumberModelToPhoneNumberModel(model: number))
            result = Result.success(true)
        } catch {
            result = Result.failure(error)
        }
        
        switch result {
        case .success(true):
            return realmManager.updatePhoneNumber(phoneNumber: convertPhoneNumberModelToPhoneNumberModel(model: number))
        default:
            print("Si no se pudo no se pudo (DatauploaderManager ADD HOUSE)")
            return result ?? Result.failure(CustomErrors.ErrorUploading)
        }
        
        
    }
    @MainActor
    func updateCall(call: PhoneCallObject) async -> Result<Bool, Error> {
        
        do {
            if authorizationLevelManager.existsAdminCredentials() {
                try await adminApi.updateCall(call: convertPhoneCallModelToPhoneCallModel(model: call))
            } else {
                try await userApi.updateCall(call: convertPhoneCallModelToPhoneCallModel(model: call))
            }
            return realmManager.updatePhoneCall(phoneCall: convertPhoneCallModelToPhoneCallModel(model: call))
                .map { _ in true }
        } catch {
            print(error)
            return .failure(error)
        }
    }

    
    @MainActor
    func deleteUserFromToken(userToken: String) async -> Result<Bool, Error> {
        do {
            let realm = try! await Realm()
            if let userToDelete = realm.objects(UserTokenObject.self).filter("id == %d", userToken).first {
                try await tokenApi.removeUserFromToken(token: userToDelete.token, userId: userToDelete.userId)
                return realmManager.deleteUserToken(userToken: userToDelete)
            }
            
            return Result.failure(CustomErrors.NotFound)
        } catch {
            return Result.failure(error)
        }
    }
    
    
    
    @MainActor
    func blockUnblockUserFromToken(userToken: String, blocked: Bool) async -> Result<Bool, Error> {
        do {
            let realm = try! await Realm()
            if let userToken = realm.objects(UserTokenObject.self).filter("userId == %d", userToken).first {
                try await tokenApi.blockUnblockUserFromToken(token: userToken.token, userId: userToken.userId, blocked: blocked)
                return realmManager.updateUserToken(userToken: UserTokenModel(id: userToken.id, token: userToken.token, userId: userToken.userId, name: userToken.name, blocked: blocked))
            }
            
            
            return Result.failure(CustomErrors.NotFound)
        } catch {
            print("Error from blockUnblockUserFromToken \(error)")
            return Result.failure(error)
        }
    }
    
    @MainActor
    func addRecall(user: String, house: String) async -> Result<Bool, Error> {
        do {
            let recall = Recall(id: Date.now.millisecondsSince1970, user: user, house: house, created_at: "", updated_at: "")
            try await userApi.addRecall(recall: recall)
            
            
            
            return await realmManager.addModelAsync(RecallObject().createRecallObject(from: recall))
        } catch {
            return Result.failure(error)
        }
    }
    
    @MainActor
    func deleteRecall(recall: Recall) async -> Result<Bool, Error> {
        do {
            try await userApi.removeRecall(recall: recall)
           
            return realmManager.deleteRecall(house: recall.house)
        } catch {
            return Result.failure(error)
        }
    }
}
