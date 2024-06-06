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
        let phoneTerritoriesEntities = realmDatabase.objects(PhoneTerritoryObject.self)
        
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
            return StartupState.Login
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
                        userTokensApi.append(UserTokenModel(id: UUID().uuidString, token: token.id, userId: String(user.id), name: user.name))
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
        await comparingAndSynchronizeTokenTerritories(apiList: tokenTerritoriesApi, dbList: tokenTerritoriesDb)
        await comparingAndSynchronizeTerritories(apiList: territoriesApi, dbList: territoriesDb)
        await comparingAndSynchronizeTerritoryAddresses(apiList: territoriesAddressesApi, dbList: territoriesAddressesDb)
        await comparingAndSynchronizeHouses(apiList: housesApi, dbList: housesDb)
        await comparingAndSynchronizeVisits(apiList: visitsApi, dbList: visitsDb)
        await comparingAndSynchronizePhoneTerritories(apiList: phoneTerritoriesApi, dbList: phoneTerritoriesDb)
        await comparingAndSynchronizePhoneNumbers(apiList: phoneNumbersApi, dbList: phoneNumbersDb)
        await comparingAndSynchronizePhoneCalls(apiList: phoneCallsApi, dbList: phoneCallsDb)
        await comparingAndSynchronizeUserTokens(apiList: userTokensApi, dbList: userTokensDb)
        
        
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
                    case .failure(let error):
                        print("There was an error adding Token \(error)")
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
                case .failure(let error):
                    print("There was an error adding Visit \(error)")
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
                case .failure(let error):
                    print("There was an error adding TokenTerritory \(error)")
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
                case .failure(let error):
                    print("There was an error adding Address \(error)")
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
    
    @MainActor
    private func comparingAndSynchronizePhoneTerritories(apiList: [PhoneTerritoryModel], dbList: [PhoneTerritoryObject]) async{
        let territoriesApi = apiList
        var territoriesDb = dbList
        
        for territoryApi in territoriesApi {
            let territoryDb = territoriesDb.first { $0.id == territoryApi.id }
            
            if territoryDb != nil {
                if (territoryDb! == territoryApi) == false {
                    switch  realmManager.updatePhoneTerritory(phoneTerritory: territoryApi){
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
                switch  realmManager.addModel(PhoneTerritoryObject ().createTerritoryObject(from: territoryApi)) {
                case .success(let success):
                    print("Success Adding Visit \(success)")
                case .failure(let error):
                    print("There was an error adding Visit \(error)")
                }
            }
        }
        
        for territoryDb in territoriesDb {
            switch  realmManager.deletePhoneTerritory(phoneTerritory: territoryDb) {
            case .success(let success):
                print("Success Deleting Visit \(success)")
            case .failure(let error):
                print("There was an error deleting Visit \(error)")
            }
        }
    }
    
    @MainActor
    private func comparingAndSynchronizePhoneNumbers(apiList: [PhoneNumberModel], dbList: [PhoneNumberObject]) async{
        let numbersApi = apiList
        var numbersDb = dbList
        
        for numberApi in numbersApi {
            let numberDb = numbersDb.first { $0.id == numberApi.id }
            
            if numberDb != nil {
                if (numberDb! == numberApi) == false {
                    switch  realmManager.updatePhoneNumber(phoneNumber: numberApi){
                    case .success(let success):
                        print(success)
                    case .failure(let error):
                        //check what to do here becasuse I don't know. ELIER what should I do here??
                        print("I Don't know what to do if couldn't update \(error)") //<--
                    }
                }
                
                if let index = numbersDb.firstIndex(of: numberDb!) {
                    numbersDb.remove(at: index)
                }
            } else {
                switch  realmManager.addModel(PhoneNumberObject().createTerritoryObject(from: numberApi)) {
                case .success(let success):
                    print("Success Adding Visit \(success)")
                case .failure(let error):
                    print("There was an error adding Visit \(error)")
                }
            }
        }
        
        for numberDb in numbersDb {
            switch  realmManager.deletePhoneNumber(phoneNumber: numberDb) {
            case .success(let success):
                print("Success Deleting Visit \(success)")
            case .failure(let error):
                print("There was an error deleting Visit \(error)")
            }
        }
    }
    
    @MainActor
    private func comparingAndSynchronizePhoneCalls(apiList: [PhoneCallModel], dbList: [PhoneCallObject]) async{
        let callsApi = apiList
        var callsDb = dbList
        
        for callApi in callsApi {
            let callDb = callsDb.first { $0.id == callApi.id }
            
            if callDb != nil {
                if (callDb! == callApi) == false {
                    switch  realmManager.updatePhoneCall(phoneCall: callApi){
                    case .success(let success):
                        print(success)
                    case .failure(let error):
                        //check what to do here becasuse I don't know. ELIER what should I do here??
                        print("I Don't know what to do if couldn't update \(error)") //<--
                    }
                }
                
                if let index = callsDb.firstIndex(of: callDb!) {
                    callsDb.remove(at: index)
                }
            } else {
                switch  realmManager.addModel(PhoneCallObject().createTerritoryObject(from: callApi)) {
                case .success(let success):
                    print("Success Adding Visit \(success)")
                case .failure(let error):
                    print("There was an error adding Visit \(error)")
                }
            }
        }
        
        for callDb in callsDb {
            switch  realmManager.deletePhoneCall(phoneCall: callDb) {
            case .success(let success):
                print("Success Deleting Visit \(success)")
            case .failure(let error):
                print("There was an error deleting Visit \(error)")
            }
        }
    }
    
    @MainActor
    private func comparingAndSynchronizeUserTokens(apiList: [UserTokenModel], dbList: [UserTokenObject]) async{
        let userTokensApi = apiList
        var userTokensDb = dbList
        
        for userTokenApi in userTokensApi {
            let userTokenDb = userTokensDb.first { $0.id == userTokenApi.id }
            
            if userTokenDb != nil {
                if (userTokenDb! == userTokenApi) == false {
                    switch  realmManager.updateUserToken(userToken: userTokenApi){
                    case .success(let success):
                        print(success)
                    case .failure(let error):
                        //check what to do here becasuse I don't know. ELIER what should I do here??
                        print("I Don't know what to do if couldn't update \(error)") //<--
                    }
                }
                
                if let index = userTokensDb.firstIndex(of: userTokenDb!) {
                    userTokensDb.remove(at: index)
                }
            } else {
                switch  realmManager.addModel(UserTokenObject().createUserTokenObject(from: userTokenApi)) {
                case .success(let success):
                    print("Success Adding Visit \(success)")
                case .failure(let error):
                    print("There was an error adding Visit \(error)")
                }
            }
        }
        
        for userTokenDb in userTokensDb {
            switch  realmManager.deleteUserToken(userToken: userTokenDb) {
            case .success(let success):
                print("Success Deleting Visit \(success)")
            case .failure(let error):
                print("There was an error deleting Visit \(error)")
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
