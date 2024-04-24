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
        
        if dataStore.userEmail == nil {
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
                    return .Empty
                }
            }
            
            loaded = true
            return .Loading
            
        }
        
        return .Ready
    }
    
    private func verifyCredentials() async -> StartupState? {
        if await authorizationLevelManager.userNeedLogin() {
            return StartupState.Login
        }
        
        if await authorizationLevelManager.adminNeedLogin() {
            return StartupState.AdminLogin
        }
        
        return nil
    }
    
    @MainActor
    func synchronize() async {
        //databaseManager.refreshAll()
        dataStore.synchronized = false
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
        //Server Data
        var tokensApi = [MyTokenModel]()
        var territoriesApi = [TerritoryModel]()
        var territoriesAddressesApi = [TerritoryAddressModel]()
        var housesApi = [HouseModel]()
        var visitsApi = [VisitModel]()
        var tokenTerritoriesApi = [TokenTerritoryModel]()
        
        //Database Data
        var tokensDb = [TokenObject]()
        var territoriesDb = [TerritoryObject]()
        var territoriesAddressesDb = [TerritoryAddressObject]()
        var housesDb = [HouseObject]()
        var visitsDb = [VisitObject]()
        var tokenTerritoriesDb = [TokenTerritoryObject]()
        
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
        
        //Comparing and Updating, adding or deleting data in database by server data
        await comparingAndSynchronizeTokens(apiList: tokensApi, dbList: tokensDb)
        await comparingAndSynchronizeTokenTerritories(apiList: tokenTerritoriesApi, dbList: tokenTerritoriesDb)
        await comparingAndSynchronizeTerritories(apiList: territoriesApi, dbList: territoriesDb)
        await comparingAndSynchronizeTerritoryAddresses(apiList: territoriesAddressesApi, dbList: territoriesAddressesDb)
        await comparingAndSynchronizeHouses(apiList: housesApi, dbList: housesDb)
        await comparingAndSynchronizeVisits(apiList: visitsApi, dbList: visitsDb)
        
        
        
        startupProcess(synchronizing: false)
        DispatchQueue.main.async {
            self.dataStore.lastTime = Date.now
            self.dataStore.synchronized = true
        }
    }
    
    @MainActor
    func comparingAndSynchronizeTokens(apiList: [MyTokenModel], dbList: [TokenObject]) async {
        let tokensApi = apiList
        var tokensDb = dbList
        
        for myTokenApi in tokensApi {
            // Find Token according to id
            let myTokenDb = tokensDb.first { $0.id == myTokenApi.id }
            
            if myTokenDb != nil {
                if (myTokenDb! == myTokenApi) == false {
                    
                    //Save the changes
                    switch  realmManager.updateToken(token: myTokenApi) {
                    case .success(let success):
                        print(success)
                    case .failure(let error):
                        //check what to do here becasuse I don't know. ELIER what should I do here??
                        print("I Don't know what to do if couldn't update \(error)") //<--
                    }
                }
                if let index = tokensDb.firstIndex(of: myTokenDb!) {
                    tokensDb.remove(at: index)
                }
            } else {
                // If it does not exist (if it is Nil), create it
                do {
                    switch  realmManager.addModel(TokenObject().createTokenObject(from: myTokenApi)) {
                    case .success(let success):
                        print("Success Adding Token \(success)")
                        return
                    case .failure(let error):
                        print("There was an error adding Token \(error)")
                        return
                    }
                }
            }
        }
        
        // Finally, remove all tokens that don't exist on the server
        for token in tokensDb {
            switch  realmManager.deleteToken(token: token) {
            case .success(let success):
                print("Success Deleting Token \(success)")
            case .failure(let error):
                print("There was an error deleting Token \(error)")
            }
        }
    }
    
    @MainActor
    private func comparingAndSynchronizeTerritories(apiList: [TerritoryModel], dbList: [TerritoryObject]) async {
        let territoriesApi = apiList
        var territoriesDb = dbList
        
        for territoryApi in territoriesApi {
            //Find territory according to id
            let territoryDb = territoriesDb.first { $0.id == territoryApi.id }
            
            //Check if territoryDb is Nil/ if it was found
            if territoryDb != nil {
                if (territoryDb! == territoryApi) == false {
                    //If not the same, UPDATE it
                    
                    //Save the changes
                    switch  realmManager.updateTerritory(territory: territoryApi){
                    case .success(let success):
                        print(success)
                    case .failure(let error):
                        //check what to do here becasuse I don't know. ELIER what should I do here??
                        print("I Don't know what to do if couldn't update \(error)") //<--
                    }
                }
                if let index = territoriesDb.firstIndex(of: territoryDb!) {
                    territoriesDb.remove(at: index)
                }
            } else {
                // If it does not exist (if it is Nil), create it
                switch  realmManager.addModel(TerritoryObject().createTerritoryObject(from: territoryApi)) {
                case .success(let success):
                    print("Success Adding Territory \(success)")
                    
                case .failure(let error):
                    print("There was an error adding Territory \(error)")
                    
                }
            }
            
        }
        
        // Finally, remove all Territories that don't exist on the server
        for territory in territoriesDb {
            switch  realmManager.deleteTerritory(territory: territory) {
            case .success(let success):
                print("Success Deleting Territory \(success)")
            case .failure(let error):
                print("There was an error deleting Territory \(error)")
            }
        }
    }
    
    @MainActor
    private func comparingAndSynchronizeHouses(apiList: [HouseModel], dbList: [HouseObject]) async {
        let housesApi = apiList
        var housesDb = dbList
        
        for houseApi in housesApi {
            let houseDb = housesDb.first { $0.id == houseApi.id }
            
            if houseDb != nil {
                if (houseDb! == houseApi) == false {
                    //Save
                    switch  realmManager.updateHouse(house: houseApi) {
                    case .success(let success):
                        print(success)
                    case .failure(let error):
                        print("I Don't know what to do if couldn't update \(error)")
                    }
                }
                
                if let index = housesDb.firstIndex(of: houseDb!) {
                    housesDb.remove(at: index)
                }
            } else {
                // If it does not exist, create it
                switch  realmManager.addModel(HouseObject().createHouseObject(from: houseApi)) {
                case .success(let success):
                    print("Success Adding House \(success)")
                case .failure(let error):
                    print("There was an error adding house \(error)")
                }
            }
        }
        
        for houseDb in housesDb {
            switch  realmManager.deleteHouse(house: houseDb) {
            case .success(let success):
                print("Success Deleting House \(success)")
            case .failure(let error):
                print("There was an error deleting house \(error)")
            }
        }
    }
    
    @MainActor
    private func comparingAndSynchronizeVisits(apiList: [VisitModel], dbList: [VisitObject]) async{
        let visitsApi = apiList
        var visitsDb = dbList
        
        for visitApi in visitsApi {
            let visitDb = visitsDb.first { $0.id == visitApi.id }
            
            if visitDb != nil {
                if (visitDb! == visitApi) == false {
                    switch  realmManager.updateVisit(visit: visitApi){
                    case .success(let success):
                        print(success)
                    case .failure(let error):
                        //check what to do here becasuse I don't know. ELIER what should I do here??
                        print("I Don't know what to do if couldn't update \(error)") //<--
                    }
                }
                
                if let index = visitsDb.firstIndex(of: visitDb!) {
                    visitsDb.remove(at: index)
                }
            } else {
                switch  realmManager.addModel(VisitObject().createVisitObject(from: visitApi)) {
                case .success(let success):
                    print("Success Adding Visit \(success)")
                    return
                case .failure(let error):
                    print("There was an error adding Visit \(error)")
                    return
                }
            }
        }
        
        for visitDb in visitsDb {
            switch  realmManager.deleteVisit(visit: visitDb) {
            case .success(let success):
                print("Success Deleting Visit \(success)")
            case .failure(let error):
                print("There was an error deleting Visit \(error)")
            }
        }
    }
    
    @MainActor
    private func comparingAndSynchronizeTokenTerritories(apiList: [TokenTerritoryModel], dbList: [TokenTerritoryObject]) async{
        let tokenTerritoriesApi = apiList
        var tokenTerritoriesDb = dbList
        
        for tokenTerritoryApi in tokenTerritoriesApi {
            let tokenTerritoryDb = tokenTerritoriesDb.first { $0.token == tokenTerritoryApi.token && $0.territory == tokenTerritoryApi.territory }
            
            if tokenTerritoryDb != nil {
                if (tokenTerritoryDb! == tokenTerritoryApi) == false {
                    //Save the changes
                    switch  realmManager.updateTokenTerritory(tokenTerritory: tokenTerritoryApi){
                    case .success(let success):
                        print(success)
                    case .failure(let error):
                        //check what to do here becasuse I don't know. ELIER what should I do here??
                        print("I Don't know what to do if couldn't update \(error)") //<--
                    }
                }
                
                if let index = tokenTerritoriesDb.firstIndex(of: tokenTerritoryDb!) {
                    tokenTerritoriesDb.remove(at: index)
                }
            } else {
                switch  realmManager.addModel(TokenTerritoryObject().createTokenTerritoryObject(from: tokenTerritoryApi)) {
                case .success(let success):
                    print("Success Adding TokenTerritory \(success)")
                    return
                case .failure(let error):
                    print("There was an error adding TokenTerritory \(error)")
                    return
                }
            }
            
        }
        
        for tokenTerritory in tokenTerritoriesDb {
            switch  realmManager.deleteTokenTerritory(tokenTerritory: tokenTerritory) {
            case .success(let success):
                print("Success Deleting TokenTerritory \(success)")
            case .failure(let error):
                print("There was an error deleting TokenTerritory \(error)")
            }
        }
    }
    
    @MainActor
    private func comparingAndSynchronizeTerritoryAddresses(apiList: [TerritoryAddressModel], dbList: [TerritoryAddressObject]) async{
        let territoryAddressesApi = apiList
        var territoryAddressesDb = dbList
        
        for territoryAddressApi in territoryAddressesApi {
            let territoryAddressDb = territoryAddressesDb.first { $0.id == territoryAddressApi.id }
            
            if territoryAddressDb != nil {
                if (territoryAddressDb! == territoryAddressApi) == false {
                    //Save the changes
                    switch  realmManager.updateAddress(address: territoryAddressApi){
                    case .success(let success):
                        print(success)
                    case .failure(let error):
                        //check what to do here becasuse I don't know. ELIER what should I do here??
                        print("I Don't know what to do if couldn't update \(error)") //<--
                    }
                }
                
                if let index = territoryAddressesDb.firstIndex(of: territoryAddressDb!) {
                    territoryAddressesDb.remove(at: index)
                }
            } else {
                switch  realmManager.addModel(TerritoryAddressObject().createTerritoryAddressObject(from: territoryAddressApi)) {
                case .success(let success):
                    print("Success Adding Address \(success)")
                    return
                case .failure(let error):
                    print("There was an error adding Address \(error)")
                    return
                }
            }
        }
        
        
        for territoryAddress in territoryAddressesDb {
            switch  realmManager.deleteAddress(address: territoryAddress) {
            case .success(let success):
                print("Success Deleting TerritoryAddress \(success)")
            case .failure(let error):
                print("There was an error deleting TerritoryAddress \(error)")
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
