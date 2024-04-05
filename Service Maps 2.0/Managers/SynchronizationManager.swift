//
//  SynchronizationManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/1/23.
//

import Foundation
import CoreData
import Combine


class SynchronizationManager: ObservableObject {
    @Published private var dataController = DataController.shared
    @Published private var dataStore = StorageManager.shared
    @Published private var authorizationLevelManager = AuthorizationLevelManager()
    
    
    var viewContext = DataController.shared.container.viewContext
    
    private var authenticationManager = AuthenticationManager()
    //MARK: Arrays
    private var territories = [Territory]()
    private var houses = [House]()
    private var visits = [Visit]()
    private var tokens = [MyToken]()
    private var territoryAddresses = [TerritoryAddress]()
    private var tokenTerritories = [TokenTerritory]()
    
    @Published var startupState: StartupState = .Unknown
    
    private var loaded = false
    
    func startupProcess(synchronizing: Bool, clearSynchronizing: Bool = false) {
        allData()
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
        
        if dataStore.userEmail == nil {
            return StartupState.Welcome
        }
        
        if !authorizationLevelManager.userHasLogged() {
            return StartupState.Validate
        }
        
        if territories.isEmpty {
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
    
    func synchronize() async {
        allData()
        dataStore.synchronized = false
        
        //Server Data
        var tokensApi = [MyTokenModel]()
        var territoriesApi = [TerritoryModel]()
        var territoriesAddressesApi = [TerritoryAddressModel]()
        var housesApi = [HouseModel]()
        var visitsApi = [VisitModel]()
        var tokenTerritoriesApi = [TokenTerritoryModel]()
        
        //Database Data
        var tokensDb = [MyToken]()
        var territoriesDb = [Territory]()
        var territoriesAddressesDb = [TerritoryAddress]()
        var housesDb = [House]()
        var visitsDb = [Visit]()
        var tokenTerritoriesDb = [TokenTerritory]()
        
        //MARK: Fetching data from server
        let tokenApi = TokenAPI()
        
        //Owned tokens
        do {
            let ownedTokens = try await tokenApi.loadOwnedTokens()
            tokensApi.append(contentsOf: ownedTokens)
            let userTokens = try await tokenApi.loadUserTokens()
            tokensApi.append(contentsOf: userTokens)
            
            
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
        
        
        tokensDb.removeAll()
        territoriesDb.removeAll()
        housesDb.removeAll()
        visitsDb.removeAll()
        territoriesAddressesDb.removeAll()
        tokenTerritoriesDb.removeAll()
        
        tokensDb.append(contentsOf: tokens)
        territoriesDb.append(contentsOf: territories)
        housesDb.append(contentsOf: houses)
        visitsDb.append(contentsOf: visits)
        tokenTerritoriesDb.append(contentsOf: tokenTerritories)
        territoriesAddressesDb.append(contentsOf: territoryAddresses)
        
        do {
            try tokensDb.forEach { token in
                // Create a predicate to filter the TokenTerritory entities based on the token value
                let predicate = NSPredicate(format: "token == %@", token)
                
                let fetchRequest = NSFetchRequest<TokenTerritory>(entityName: "TokenTerritory")
                fetchRequest.predicate = predicate
                
                let territoryTokensFiltered = try viewContext.fetch(fetchRequest)
                
                
                tokenTerritoriesDb.append(contentsOf: territoryTokensFiltered)
            }
        } catch {
            self.dataStore.synchronized = true
            return
        }
        
        //Comparing and Updating, adding or deleting data in database by server data
        await comparingAndSynchronizeTokens(apiList: StructToModel().convertTokenStructsToEntities(structs: tokensApi), dbList: tokensDb)
        await comparingAndSynchronizeTokenTerritories(apiList: StructToModel().convertTokenTerritoriesStructsToEntities(structs: tokenTerritoriesApi), dbList: tokenTerritoriesDb)
        await comparingAndSynchronizeTerritories(apiList: StructToModel().convertTerritoryStructsToEntities(structs: territoriesApi), dbList: territoriesDb)
        await comparingAndSynchronizeHouses(apiList: StructToModel().convertHouseStructsToEntities(structs: housesApi), dbList: housesDb)
        await comparingAndSynchronizeVisits(apiList: StructToModel().convertVisitStructsToEntities(structs: visitsApi), dbList: visitsDb)
        await comparingAndSynchronizeTerritoryAddresses(apiList: StructToModel().convertTerritoryAddressStructsToEntities(structs: territoriesAddressesApi), dbList: territoriesAddressesDb)
        
        startupProcess(synchronizing: false)
        self.dataStore.synchronized = true
        
    }
    
    func comparingAndSynchronizeTokens(apiList: [MyToken], dbList: [MyToken]) async {
        let tokensApi = apiList
        var tokensDb = dbList
        
        for myTokenApi in tokensApi {
            // Find Token according to id
            if let myTokenDb = tokensDb.first(where: { $0.id == myTokenApi.id }) {
                // If Token does exist in the database
                if myTokenDb != myTokenApi {
                    // Check if the Token on the server has differences with the one in the database
                    // If it has differences, update it in the database
                    
                    //Update Object
                    myTokenDb.congregation = myTokenApi.congregation
                    myTokenDb.name = myTokenApi.name
                    myTokenDb.owner = myTokenApi.owner
                    myTokenDb.user = myTokenApi.user
                    myTokenDb.expires = myTokenApi.expires
                    myTokenDb.moderator = myTokenApi.moderator
                    
                    //Save
                    do {
                        
                        try viewContext.save()
                    } catch {
                        print(error.self)
                        print("Error saving Tokens Comparison 1")
                    }
                }
                // Remove Token from the database to discard what does exist on the server
                // and leave only what should be deleted
                if let index = tokensDb.firstIndex(where: { $0.id == myTokenDb.id }) {
                    tokensDb.remove(at: index)
                }
            } else {
                // If it does not exist, create it
                viewContext.insert(myTokenApi)
                
                //Save
                do {
                    
                    try viewContext.save()
                } catch {
                    print(error.self)
                    print("Error saving Comparison 2")
                }
            }
        }
        
        // Finally, remove all tokens that don't exist on the server
        for token in tokensDb {
            viewContext.delete(token)
        }
    }
    
    private func comparingAndSynchronizeTerritories(apiList: [Territory], dbList: [Territory]) async {
        let territoriesApi = apiList
        var territoriesDb = dbList
        
        // Step 1: Remove territories that exist in the database but not in the API response
        let apiTerritoryIds = Set(territoriesApi.map { $0.id })
        territoriesDb.removeAll { !apiTerritoryIds.contains($0.id) }
        
        // Step 2: Update or create territories based on the API response
        for territoryApi in territoriesApi {
            if let index = territoriesDb.firstIndex(where: { $0.id == territoryApi.id }) {
                // If Territory exists in the database, update it
                territoriesDb[index] = territoryApi
            } else {
                // If Territory does not exist in the database, create it
                territoriesDb.append(territoryApi)
            }
        }
        
        // Step 3: Save the changes to the database
        await MainActor.run {
            do {
                
                try viewContext.save()
            } catch {
                print(error.self)
                print("Error saving  Territories")
            }
        }
    }
    
    private func comparingAndSynchronizeHouses(apiList: [House], dbList: [House]) async {
        let housesApi = apiList
        var housesDb = dbList
        
        for houseApi in housesApi {
            let houseDb = housesDb.first { $0.id == houseApi.id }
            
            if let houseDb = houseDb {
                if houseApi != houseDb {
                    houseDb.number = houseApi.number
                    houseDb.territoryAddress = houseApi.territoryAddress
                    houseDb.floor = houseApi.floor
                    //Save
                    do {
                        
                        try viewContext.save()
                    } catch {
                        print(error.self)
                        print("Error saving Houses 1")
                    }
                }
                
                if let index = housesDb.firstIndex(of: houseDb) {
                    housesDb.remove(at: index)
                }
            } else {
                // If it does not exist, create it
                viewContext.insert(houseApi)
                
                //Save
                do {
                    
                    try viewContext.save()
                } catch {
                    print(error.self)
                    print("Error saving Houses 2")
                }
            }
        }
        
        for houseDb in housesDb {
            viewContext.delete(houseDb)
        }
    }
    
    private func comparingAndSynchronizeVisits(apiList: [Visit], dbList: [Visit]) async{
        let visitsApi = apiList
        var visitsDb = dbList
        
        for visitApi in visitsApi {
            let visitDb = visitsDb.first { $0.id == visitApi.id }
            
            if let visitDb = visitDb {
                if visitApi != visitDb {
                    
                    visitDb.date = visitApi.date
                    visitDb.house = visitApi.house
                    visitDb.notes = visitApi.notes
                    visitDb.symbol = visitApi.symbol
                    visitDb.user = visitApi.user
                    
                    //Save
                    do {
                        
                        try viewContext.save()
                    } catch {
                        print(error.self)
                        print("Error saving Visits 1")
                    }
                }
                
                if let index = visitsDb.firstIndex(of: visitDb) {
                    visitsDb.remove(at: index)
                }
            } else {
                // If it does not exist, create it
                viewContext.insert(visitApi)
                
                //Save
                do {
                    
                    try viewContext.save()
                } catch {
                    print(error.self)
                    print("Error saving Visits 2")
                }
            }
        }
        
        for visitDb in visitsDb {
            viewContext.delete(visitDb)
        }
    }
    
    private func comparingAndSynchronizeTokenTerritories(apiList: [TokenTerritory], dbList: [TokenTerritory]) async{
        let tokenTerritoriesApi = apiList
        var tokenTerritoriesDb = dbList
        
        for tokenTerritoryApi in tokenTerritoriesApi {
            let tokenTerritoryDb = tokenTerritoriesDb.first {
                $0.token == tokenTerritoryApi.token && $0.territory == tokenTerritoryApi.territory
            }
            
            if let tokenTerritoryDb = tokenTerritoryDb {
                if let index = tokenTerritoriesDb.firstIndex(of: tokenTerritoryDb) {
                    tokenTerritoriesDb.remove(at: index)
                }
            } else {
                // If it does not exist, create it
                viewContext.insert(tokenTerritoryApi)
                
                //Save
                do {
                    
                    try viewContext.save()
                } catch {
                    print(error.self)
                    print("Error saving Token territories")
                }
            }
        }
        
        for tokenTerritoryDb in tokenTerritoriesDb {
            viewContext.delete(tokenTerritoryDb)
        }
    }
    
    private func comparingAndSynchronizeTerritoryAddresses(apiList: [TerritoryAddress], dbList: [TerritoryAddress]) async{
        let territoryAddressesApi = apiList
        var territoryAddressesDb = dbList
        
        for territoryAddressApi in territoryAddressesApi {
            let territoryAddressDb = territoryAddressesDb.first {
                $0.territory == territoryAddressApi.territory && $0.address == territoryAddressApi.address
            }
            
            if let territoryAddressDb = territoryAddressDb {
                if let index = territoryAddressesDb.firstIndex(of: territoryAddressDb) {
                    territoryAddressesDb.remove(at: index)
                }
            } else {
                // If it does not exist, create it
                viewContext.insert(territoryAddressApi)
                
                //Save
                do {
                    
                    try viewContext.save()
                } catch {
                    print(error.self)
                    print("Error saving Addresses")
                }
            }
        }
        
        for tokenTerritoryDb in territoryAddressesDb {
            viewContext.delete(tokenTerritoryDb)
        }
    }
    
    func allData() {
        territories = DataController.shared.getTerritories()
        houses = DataController.shared.getHouses()
        visits = DataController.shared.getVisits()
        tokens = DataController.shared.getMyTokens()
        territoryAddresses = DataController.shared.getTerritoryAddresses()
        tokenTerritories = DataController.shared.getTokenTerritories()
    }
    
    class var shared: SynchronizationManager {
        struct Static {
            static let instance = SynchronizationManager()
        }
        
        return Static.instance
    }
}
