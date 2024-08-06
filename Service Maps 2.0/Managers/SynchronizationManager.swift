//
//  SynchronizationManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/1/23.
//

import Foundation
import Combine
import RealmSwift

class SynchronizationManager: ObservableObject {
    @Published private var realmManager = RealmManager.shared
    @Published private var dataStore = StorageManager.shared
    @Published private var authorizationLevelManager = AuthorizationLevelManager()
    
    private var authenticationManager = AuthenticationManager()
    
    @Published var startupState: StartupState = .Unknown
    
    private var loaded = false
    private var timer: Timer?
    
    @Published var back_from_verification = false
    
    func startSyncAndHaptics() {
        HapticManager.shared.trigger(.lightImpact)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, !self.dataStore.synchronized else {
                self?.timer?.invalidate()
                return
            }
            HapticManager.shared.trigger(.lightImpact)
        }
    }
    
    func startupProcess(synchronizing: Bool, clearSynchronizing: Bool = false) {
        //allData()
        if clearSynchronizing {
            loaded = false
            dataStore.synchronized = false
        }
        Task {
            if synchronizing {
                await synchronize()
            }
        }
        
        Task {
            DispatchQueue.main.async {
                let newStartupState = self.loadStartupState()
                self.startupState = newStartupState
            }
            
            if startupState == .Ready || startupState == .Empty {
                if let verifiedCredentials = await verifyCredentials() {
                    DispatchQueue.main.async {
                        self.startupState = verifiedCredentials
                    }
                }
            }
        }
    }
    
    private func loadStartupState() -> StartupState {
        let realmDatabase = try! Realm()
        let territoryEntities = realmDatabase.objects(TerritoryObject.self)
        let phoneTerritoriesEntities = realmDatabase.objects(PhoneTerritoryObject.self)
        
        if dataStore.userEmail == nil || back_from_verification {
            return StartupState.Welcome
        }
        
        if !authorizationLevelManager.userHasLogged() {
            return StartupState.Validate
        }
        
        if territoryEntities.isEmpty {
            if dataStore.synchronized || loaded {
                if authorizationLevelManager.existsAdminCredentials() {
                    return .Ready
                } else {
                    if phoneTerritoriesEntities.isEmpty {
                        return .Empty
                    } else {
                        return .Ready
                    }
                }
            }
            
            loaded = true
            return .Loading
            
        }
        
        return .Ready
    }
    
    private func verifyCredentials() async -> StartupState? {
        if await authorizationLevelManager.userNeedLogin() {
            return StartupState.Welcome
        }
        
        if await authorizationLevelManager.adminNeedLogin() {
            return StartupState.AdminLogin
        }
        
        if !authorizationLevelManager.existsAdminCredentials() {
            if await authorizationLevelManager.phoneNeedLogin() {
                return .PhoneLogin
            }
            
        }
        
        return nil
    }
    
    @MainActor
    func synchronize() async {
        //databaseManager.refreshAll()
        dataStore.synchronized = false
        startSyncAndHaptics()
        guard let realmDatabase = try? await Realm() else {
            print("REALM FAILED")
            return
        }
        
        let territoryEntities = realmDatabase.objects(TerritoryObject.self)
        let addressesEntities = realmDatabase.objects(TerritoryAddressObject.self)
        let housesEntities = realmDatabase.objects(HouseObject.self)
        let visitsEntities = realmDatabase.objects(VisitObject.self)
        let tokensEntities = realmDatabase.objects(TokenObject.self)
        let tokenTerritoryEntities = realmDatabase.objects(TokenTerritoryObject.self)
        let phoneTerritoriesEntities = realmDatabase.objects(PhoneTerritoryObject.self)
        let phoneNumberEntities = realmDatabase.objects(PhoneNumberObject.self)
        let phoneCallEntities = realmDatabase.objects(PhoneCallObject.self)
        let userTokenEntities = realmDatabase.objects(UserTokenObject.self)
        
        //Server Data
        var tokensApi = [MyTokenModel]()
        var territoriesApi = [TerritoryModel]()
        var territoriesAddressesApi = [TerritoryAddressModel]()
        var housesApi = [HouseModel]()
        var visitsApi = [VisitModel]()
        var tokenTerritoriesApi = [TokenTerritoryModel]()
        var phoneTerritoriesApi = [PhoneTerritoryModel]()
        var phoneNumbersApi = [PhoneNumberModel]()
        var phoneCallsApi = [PhoneCallModel]()
        var userTokensApi = [UserTokenModel]()
        
        //Database Data
        var tokensDb = [TokenObject]()
        var territoriesDb = [TerritoryObject]()
        var territoriesAddressesDb = [TerritoryAddressObject]()
        var housesDb = [HouseObject]()
        var visitsDb = [VisitObject]()
        var tokenTerritoriesDb = [TokenTerritoryObject]()
        var phoneTerritoriesDb = [PhoneTerritoryObject]()
        var phoneNumbersDb = [PhoneNumberObject]()
        var phoneCallsDb = [PhoneCallObject]()
        var userTokensDb = [UserTokenObject]()
        
        //MARK: Fetching data from server
        let tokenApi = TokenAPI()
        
        //Owned tokens
        do {
            let ownedTokens = try await tokenApi.loadOwnedTokens()
            tokensApi.append(contentsOf: ownedTokens)
            let userTokens = try await tokenApi.loadUserTokens()
            
            for token in userTokens {
                if !tokensApi.contains(token) {
                    tokensApi.append(token)
                }
            }
            
            for token in tokensApi {
                do {
                    let response = try await tokenApi.usersOfToken(token: token.id)
                    for user in response {
                        userTokensApi.append(UserTokenModel(id: UUID().uuidString, token: token.id, userId: String(user.id), name: user.name, blocked: user.blocked))
                    }
                } catch {
                    print("not authorized")
                }
            }
            
            
            if authorizationLevelManager.existsAdminCredentials() {
                let response = try await AdminAPI().allData()
                territoriesApi = response.territories
                housesApi = response.houses
                visitsApi = response.visits
                territoriesAddressesApi = response.addresses
            } else {
                let response = try await UserAPI().loadTerritories()
                territoriesApi = response.territories
                housesApi = response.houses
                visitsApi = response.visits
                territoriesAddressesApi = response.addresses
            }
            
            for token in tokensApi {
                let response = try await tokenApi.getTerritoriesOfToken(token: token.id)
                tokenTerritoriesApi.append(contentsOf: response)
            }
            
            let allPhoneResponse: AllPhoneDataResponse
            
            if authorizationLevelManager.existsAdminCredentials() {
                let result = await AdminAPI().allPhoneData()
                switch result {
                case .success(let response):
                    allPhoneResponse = response
                    phoneTerritoriesApi.append(contentsOf: allPhoneResponse.territories)
                    phoneCallsApi.append(contentsOf: allPhoneResponse.calls)
                    phoneNumbersApi.append(contentsOf: allPhoneResponse.numbers)
                case .failure(let error):
                    print(error)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.dataStore.synchronized = true
                    }
                }
                
            } else {
                let result = await UserAPI().allPhoneData()
                switch result {
                case .success(let response):
                    allPhoneResponse = response
                    phoneTerritoriesApi.append(contentsOf: allPhoneResponse.territories)
                    phoneCallsApi.append(contentsOf: allPhoneResponse.calls)
                    phoneNumbersApi.append(contentsOf: allPhoneResponse.numbers)
                case .failure(_):
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.dataStore.synchronized = true
                    }
                }
                
            }
            
        } catch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.dataStore.synchronized = true
            }
            return
        }
        
        tokensDb =  Array(tokensEntities)
        territoriesDb =  Array(territoryEntities)
        housesDb =  Array(housesEntities)
        visitsDb =  Array(visitsEntities)
        territoriesAddressesDb =  Array(addressesEntities)
        tokenTerritoriesDb = Array(tokenTerritoryEntities)
        phoneTerritoriesDb = Array(phoneTerritoriesEntities)
        phoneCallsDb = Array(phoneCallEntities)
        phoneNumbersDb = Array(phoneNumberEntities)
        userTokensDb = Array(userTokenEntities)
        
        //Comparing and Updating, adding or deleting data in database by server data
        await comparingAndSynchronizeTokens(apiList: tokensApi, dbList: tokensDb)
//        await comparingAndSynchronizeTokenTerritories(apiList: tokenTerritoriesApi, dbList: tokenTerritoriesDb)
//        await comparingAndSynchronizeTerritories(apiList: territoriesApi, dbList: territoriesDb)
//        await comparingAndSynchronizeTerritoryAddresses(apiList: territoriesAddressesApi, dbList: territoriesAddressesDb)
//        await comparingAndSynchronizeHouses(apiList: housesApi, dbList: housesDb)
//        await comparingAndSynchronizeVisits(apiList: visitsApi, dbList: visitsDb)
//        await comparingAndSynchronizePhoneTerritories(apiList: phoneTerritoriesApi, dbList: phoneTerritoriesDb)
//        await comparingAndSynchronizePhoneNumbers(apiList: phoneNumbersApi, dbList: phoneNumbersDb)
//        await comparingAndSynchronizePhoneCalls(apiList: phoneCallsApi, dbList: phoneCallsDb)
//        await comparingAndSynchronizeUserTokens(apiList: userTokensApi, dbList: userTokensDb)
//        
        
        startupProcess(synchronizing: false)
        DispatchQueue.main.async {
            self.dataStore.lastTime = Date.now
            self.dataStore.synchronized = true
        }
    }
    
    @MainActor
    func comparingAndSynchronizeTokens(apiList: [MyTokenModel], dbList: [TokenObject]) async {
        let tokensApi = Set(apiList.map { $0.id })
        var tokensDb = Set(dbList.map { $0.id })
        
        var updates: [MyTokenModel] = []
        var additions: [MyTokenModel] = []
        
        // Collect updates and additions
        for myTokenApi in apiList {
            if let myTokenDb = dbList.first(where: { $0.id == myTokenApi.id }) {
                if (myTokenDb == myTokenApi) == false {
                    updates.append(myTokenApi)
                }
                tokensDb.remove(myTokenDb.id)
            } else {
                additions.append(myTokenApi)
            }
        }
        
        // Perform updates
        for myTokenApi in updates {
            switch realmManager.updateToken(token: myTokenApi) {
            case .success(let success):
                print(success)
            case .failure(let error):
                print("I Don't know what to do if couldn't update \(error)")
            }
        }
        
        // Perform additions
        for myTokenApi in additions {
            switch realmManager.addModel(TokenObject().createTokenObject(from: myTokenApi)) {
            case .success(let success):
                print("Success Adding Token \(success)")
            case .failure(let error):
                print("There was an error adding Token \(error)")
            }
        }
        
        // Perform deletions
        for tokenId in tokensDb {
            if let token = dbList.first(where: { $0.id == tokenId }) {
                switch realmManager.deleteToken(token: token) {
                case .success(let success):
                    print("Success Deleting Token \(success)")
                case .failure(let error):
                    print("There was an error deleting Token \(error)")
                }
            }
        }
    }
    
    @MainActor
    private func comparingAndSynchronizeTerritories(apiList: [TerritoryModel], dbList: [TerritoryObject]) async {
        let territoriesApi = Set(apiList.map { $0.id })
        var territoriesDb = Set(dbList.map { $0.id })
        
        var updates: [TerritoryModel] = []
        var additions: [TerritoryModel] = []
        
        // Collect updates and additions
        for territoryApi in apiList {
            if let territoryDb = dbList.first(where: { $0.id == territoryApi.id }) {
                if (territoryDb == territoryApi) == false {
                    updates.append(territoryApi)
                }
                territoriesDb.remove(territoryDb.id)
            } else {
                additions.append(territoryApi)
            }
        }
        
        // Perform updates
        for territoryApi in updates {
            switch realmManager.updateTerritory(territory: territoryApi) {
            case .success(let success):
                print(success)
            case .failure(let error):
                print("I Don't know what to do if couldn't update \(error)")
            }
        }
        
        // Perform additions
        for territoryApi in additions {
            switch realmManager.addModel(TerritoryObject().createTerritoryObject(from: territoryApi)) {
            case .success(let success):
                print("Success Adding Territory \(success)")
            case .failure(let error):
                print("There was an error adding Territory \(error)")
            }
        }
        
        // Perform deletions
        for territoryId in territoriesDb {
            if let territory = dbList.first(where: { $0.id == territoryId }) {
                switch realmManager.deleteTerritory(territory: territory) {
                case .success(let success):
                    print("Success Deleting Territory \(success)")
                case .failure(let error):
                    print("There was an error deleting Territory \(error)")
                }
            }
        }
    }
    
    @MainActor
    private func comparingAndSynchronizeHouses(apiList: [HouseModel], dbList: [HouseObject]) async {
        let housesApi = Set(apiList.map { $0.id })
        var housesDb = Set(dbList.map { $0.id })
        
        var updates: [HouseModel] = []
        var additions: [HouseModel] = []
        
        // Collect updates and additions
        for houseApi in apiList {
            if let houseDb = dbList.first(where: { $0.id == houseApi.id }) {
                if (houseDb == houseApi) == false {
                    updates.append(houseApi)
                }
                housesDb.remove(houseDb.id)
            } else {
                additions.append(houseApi)
            }
        }
        
        // Perform updates
        for houseApi in updates {
            switch realmManager.updateHouse(house: houseApi) {
            case .success(let success):
                print(success)
            case .failure(let error):
                print("I Don't know what to do if couldn't update \(error)")
            }
        }
        
        // Perform additions
        for houseApi in additions {
            switch realmManager.addModel(HouseObject().createHouseObject(from: houseApi)) {
            case .success(let success):
                print("Success Adding House \(success)")
            case .failure(let error):
                print("There was an error adding house \(error)")
            }
        }
        
        // Perform deletions
        for houseId in housesDb {
            if let house = dbList.first(where: { $0.id == houseId }) {
                switch realmManager.deleteHouse(house: house) {
                case .success(let success):
                    print("Success Deleting House \(success)")
                case .failure(let error):
                    print("There was an error deleting house \(error)")
                }
            }
        }
    }
    
    @MainActor
    private func comparingAndSynchronizeVisits(apiList: [VisitModel], dbList: [VisitObject]) async {
        let visitsApi = Set(apiList.map { $0.id })
        var visitsDb = Set(dbList.map { $0.id })
        
        var updates: [VisitModel] = []
        var additions: [VisitModel] = []
        
        // Collect updates and additions
        for visitApi in apiList {
            if let visitDb = dbList.first(where: { $0.id == visitApi.id }) {
                if (visitDb == visitApi) == false {
                    updates.append(visitApi)
                }
                visitsDb.remove(visitDb.id)
            } else {
                additions.append(visitApi)
            }
        }
        
        // Perform updates
        for visitApi in updates {
            switch realmManager.updateVisit(visit: visitApi) {
            case .success(let success):
                print(success)
            case .failure(let error):
                print("I Don't know what to do if couldn't update \(error)")
            }
        }
        
        // Perform additions
        for visitApi in additions {
            switch realmManager.addModel(VisitObject().createVisitObject(from: visitApi)) {
            case .success(let success):
                print("Success Adding Visit \(success)")
            case .failure(let error):
                print("There was an error adding Visit \(error)")
            }
        }
        
        // Perform deletions
        for visitId in visitsDb {
            if let visit = dbList.first(where: { $0.id == visitId }) {
                switch realmManager.deleteVisit(visit: visit) {
                case .success(let success):
                    print("Success Deleting Visit \(success)")
                case .failure(let error):
                    print("There was an error deleting Visit \(error)")
                }
            }
        }
    }
    
    @MainActor
    private func comparingAndSynchronizeTokenTerritories(apiList: [TokenTerritoryModel], dbList: [TokenTerritoryObject]) async {
        struct TokenTerritoryKey: Hashable {
            let token: String
            let territory: String
        }
        
        let tokenTerritoriesApi = Set(apiList.map { TokenTerritoryKey(token: $0.token, territory: $0.territory) })
        var tokenTerritoriesDb = Set(dbList.map { TokenTerritoryKey(token: $0.token, territory: $0.territory) })
        
        var updates: [TokenTerritoryModel] = []
        var additions: [TokenTerritoryModel] = []
        
        // Collect updates and additions
        for tokenTerritoryApi in apiList {
            let key = TokenTerritoryKey(token: tokenTerritoryApi.token, territory: tokenTerritoryApi.territory)
            
            if let tokenTerritoryDb = dbList.first(where: { $0.token == tokenTerritoryApi.token && $0.territory == tokenTerritoryApi.territory }) {
                if (tokenTerritoryDb == tokenTerritoryApi) == false {
                    updates.append(tokenTerritoryApi)
                }
                tokenTerritoriesDb.remove(key)
            } else {
                additions.append(tokenTerritoryApi)
            }
        }
        
        // Perform updates
        for tokenTerritoryApi in updates {
            switch realmManager.updateTokenTerritory(tokenTerritory: tokenTerritoryApi) {
            case .success(let success):
                print(success)
            case .failure(let error):
                print("I Don't know what to do if couldn't update \(error)")
            }
        }
        
        // Perform additions
        for tokenTerritoryApi in additions {
            switch realmManager.addModel(TokenTerritoryObject().createTokenTerritoryObject(from: tokenTerritoryApi)) {
            case .success(let success):
                print("Success Adding TokenTerritory \(success)")
            case .failure(let error):
                print("There was an error adding TokenTerritory \(error)")
            }
        }
        
        // Perform deletions
        for tokenTerritoryKey in tokenTerritoriesDb {
            if let tokenTerritory = dbList.first(where: { $0.token == tokenTerritoryKey.token && $0.territory == tokenTerritoryKey.territory }) {
                switch realmManager.deleteTokenTerritory(tokenTerritory: tokenTerritory) {
                case .success(let success):
                    print("Success Deleting TokenTerritory \(success)")
                case .failure(let error):
                    print("There was an error deleting TokenTerritory \(error)")
                }
            }
        }
    }
    
    @MainActor
    private func comparingAndSynchronizeTerritoryAddresses(apiList: [TerritoryAddressModel], dbList: [TerritoryAddressObject]) async {
        let territoryAddressesApi = Set(apiList.map { $0.id })
        var territoryAddressesDb = Set(dbList.map { $0.id })
        
        var updates: [TerritoryAddressModel] = []
        var additions: [TerritoryAddressModel] = []
        
        // Collect updates and additions
        for territoryAddressApi in apiList {
            if let territoryAddressDb = dbList.first(where: { $0.id == territoryAddressApi.id }) {
                if (territoryAddressDb == territoryAddressApi) == false {
                    updates.append(territoryAddressApi)
                }
                territoryAddressesDb.remove(territoryAddressDb.id)
            } else {
                additions.append(territoryAddressApi)
            }
        }
        
        // Perform updates
        for territoryAddressApi in updates {
            switch realmManager.updateAddress(address: territoryAddressApi) {
            case .success(let success):
                print(success)
            case .failure(let error):
                print("I Don't know what to do if couldn't update \(error)")
            }
        }
        
        // Perform additions
        for territoryAddressApi in additions {
            switch realmManager.addModel(TerritoryAddressObject().createTerritoryAddressObject(from: territoryAddressApi)) {
            case .success(let success):
                print("Success Adding Address \(success)")
            case .failure(let error):
                print("There was an error adding Address \(error)")
            }
        }
        
        // Perform deletions
        for territoryAddressId in territoryAddressesDb {
            if let territoryAddress = dbList.first(where: { $0.id == territoryAddressId }) {
                switch realmManager.deleteAddress(address: territoryAddress) {
                case .success(let success):
                    print("Success Deleting TerritoryAddress \(success)")
                case .failure(let error):
                    print("There was an error deleting TerritoryAddress \(error)")
                }
            }
        }
    }
    
    @MainActor
    private func comparingAndSynchronizePhoneTerritories(apiList: [PhoneTerritoryModel], dbList: [PhoneTerritoryObject]) async {
        let territoriesApi = Set(apiList.map { $0.id })
        var territoriesDb = Set(dbList.map { $0.id })
        
        var updates: [PhoneTerritoryModel] = []
        var additions: [PhoneTerritoryModel] = []
        
        // Collect updates and additions
        for territoryApi in apiList {
            if let territoryDb = dbList.first(where: { $0.id == territoryApi.id }) {
                if (territoryDb == territoryApi) == false {
                    updates.append(territoryApi)
                }
                territoriesDb.remove(territoryDb.id)
            } else {
                additions.append(territoryApi)
            }
        }
        
        // Perform updates
        for territoryApi in updates {
            switch realmManager.updatePhoneTerritory(phoneTerritory: territoryApi) {
            case .success(let success):
                print(success)
            case .failure(let error):
                print("I Don't know what to do if couldn't update \(error)")
            }
        }
        
        // Perform additions
        for territoryApi in additions {
            switch realmManager.addModel(PhoneTerritoryObject().createTerritoryObject(from: territoryApi)) {
            case .success(let success):
                print("Success Adding PhoneTerritory \(success)")
            case .failure(let error):
                print("There was an error adding PhoneTerritory \(error)")
            }
        }
        
        // Perform deletions
        for territoryId in territoriesDb {
            if let territory = dbList.first(where: { $0.id == territoryId }) {
                switch realmManager.deletePhoneTerritory(phoneTerritory: territory) {
                case .success(let success):
                    print("Success Deleting PhoneTerritory \(success)")
                case .failure(let error):
                    print("There was an error deleting PhoneTerritory \(error)")
                }
            }
        }
    }
    
    @MainActor
    private func comparingAndSynchronizePhoneNumbers(apiList: [PhoneNumberModel], dbList: [PhoneNumberObject]) async {
        let numbersApi = Set(apiList.map { $0.id })
        var numbersDb = Set(dbList.map { $0.id })
        
        var updates: [PhoneNumberModel] = []
        var additions: [PhoneNumberModel] = []
        
        // Collect updates and additions
        for numberApi in apiList {
            if let numberDb = dbList.first(where: { $0.id == numberApi.id }) {
                if (numberDb == numberApi) == false {
                    updates.append(numberApi)
                }
                numbersDb.remove(numberDb.id)
            } else {
                additions.append(numberApi)
            }
        }
        
        // Perform updates
        for numberApi in updates {
            switch realmManager.updatePhoneNumber(phoneNumber: numberApi) {
            case .success(let success):
                print(success)
            case .failure(let error):
                print("I Don't know what to do if couldn't update \(error)")
            }
        }
        
        // Perform additions
        for numberApi in additions {
            switch realmManager.addModel(PhoneNumberObject().createTerritoryObject(from: numberApi)) {
            case .success(let success):
                print("Success Adding PhoneNumber \(success)")
            case .failure(let error):
                print("There was an error adding PhoneNumber \(error)")
            }
        }
        
        // Perform deletions
        for numberId in numbersDb {
            if let number = dbList.first(where: { $0.id == numberId }) {
                switch realmManager.deletePhoneNumber(phoneNumber: number) {
                case .success(let success):
                    print("Success Deleting PhoneNumber \(success)")
                case .failure(let error):
                    print("There was an error deleting PhoneNumber \(error)")
                }
            }
        }
    }
    
    @MainActor
    private func comparingAndSynchronizePhoneCalls(apiList: [PhoneCallModel], dbList: [PhoneCallObject]) async {
        let callsApi = Set(apiList.map { $0.id })
        var callsDb = Set(dbList.map { $0.id })
        
        var updates: [PhoneCallModel] = []
        var additions: [PhoneCallModel] = []
        
        // Collect updates and additions
        for callApi in apiList {
            if let callDb = dbList.first(where: { $0.id == callApi.id }) {
                if (callDb == callApi) == false {
                    updates.append(callApi)
                }
                callsDb.remove(callDb.id)
            } else {
                additions.append(callApi)
            }
        }
        
        // Perform updates
        for callApi in updates {
            switch realmManager.updatePhoneCall(phoneCall: callApi) {
            case .success(let success):
                print(success)
            case .failure(let error):
                print("I Don't know what to do if couldn't update \(error)")
            }
        }
        
        // Perform additions
        for callApi in additions {
            switch realmManager.addModel(PhoneCallObject().createTerritoryObject(from: callApi)) {
            case .success(let success):
                print("Success Adding PhoneCall \(success)")
            case .failure(let error):
                print("There was an error adding PhoneCall \(error)")
            }
        }
        
        // Perform deletions
        for callId in callsDb {
            if let call = dbList.first(where: { $0.id == callId }) {
                switch realmManager.deletePhoneCall(phoneCall: call) {
                case .success(let success):
                    print("Success Deleting PhoneCall \(success)")
                case .failure(let error):
                    print("There was an error deleting PhoneCall \(error)")
                }
            }
        }
    }
    
    @MainActor
    private func comparingAndSynchronizeUserTokens(apiList: [UserTokenModel], dbList: [UserTokenObject]) async {
        let userTokensApi = Set(apiList.map { $0.id })
        var userTokensDb = Set(dbList.map { $0.id })
        
        var updates: [UserTokenModel] = []
        var additions: [UserTokenModel] = []
        
        // Collect updates and additions
        for userTokenApi in apiList {
            if let userTokenDb = dbList.first(where: { $0.id == userTokenApi.id }) {
                if (userTokenDb == userTokenApi) == false {
                    updates.append(userTokenApi)
                }
                userTokensDb.remove(userTokenDb.id)
            } else {
                additions.append(userTokenApi)
            }
        }
        
        // Perform updates
        for userTokenApi in updates {
            switch realmManager.updateUserToken(userToken: userTokenApi) {
            case .success(let success):
                print(success)
            case .failure(let error):
                print("I Don't know what to do if couldn't update \(error)")
            }
        }
        
        // Perform additions
        for userTokenApi in additions {
            switch realmManager.addModel(UserTokenObject().createUserTokenObject(from: userTokenApi)) {
            case .success(let success):
                print("Success Adding UserToken \(success)")
            case .failure(let error):
                print("There was an error adding UserToken \(error)")
            }
        }
        
        // Perform deletions
        for userTokenId in userTokensDb {
            if let userToken = dbList.first(where: { $0.id == userTokenId }) {
                switch realmManager.deleteUserToken(userToken: userToken) {
                case .success(let success):
                    print("Success Deleting UserToken \(success)")
                case .failure(let error):
                    print("There was an error deleting UserToken \(error)")
                }
            }
        }
    }
    
    class var shared: SynchronizationManager {
        struct Static {
            static let instance = SynchronizationManager()
        }
        
        return Static.instance
    }
}
