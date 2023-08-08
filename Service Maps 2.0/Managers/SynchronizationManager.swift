//
//  SynchronizationManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/1/23.
//

import Foundation
import CoreData
import SwiftUI

class SynchronizationManager: ObservableObject {
    
    private var authorizationProvider = AuthorizationProvider()
    private var dataController = DataController.shared
    
    //MARK: Fetch Requests
    let territoriesRequest = NSFetchRequest<NSManagedObject>(entityName: "Territory")
    let housesRequest = NSFetchRequest<NSManagedObject>(entityName: "House")
    let visitsRequest = NSFetchRequest<NSManagedObject>(entityName: "Visit")
    let tokensRequest = NSFetchRequest<NSManagedObject>(entityName: "MyToken")
    
    //MARK: Arrays
    private var territories = [Territory]()
    private var houses = [House]()
    private var visits = [Visit]()
    private var tokens = [MyToken]()
    
    //MORE KEYS
    @AppStorage("userEmailKey") var userEmail
    
    init() {
        territories = try! dataController.container.viewContext.fetch(territoriesRequest) as! [Territory]
        houses = try! dataController.container.viewContext.fetch(housesRequest) as! [House]
        visits = try! dataController.container.viewContext.fetch(visitsRequest) as! [Visit]
        tokens = try! dataController.container.viewContext.fetch(tokensRequest) as! [MyToken]
        
        //MARK: DEBUG
        //print("These territories are from synchronization manager \(territories)")
    }
    
    private func loadStartupState() -> StartupState {
        
    }
    
    private func verifyCredentials() async -> StartupState? {
        if await userNeedLogin() {
            return StartupState.Login
        }
        
        if await adminNeedLogin() {
            return StartupState.AdminLogin
        }
        
        return nil
    }
    
    func synchronize() async throws {
        
        //Server Data
        var tokensApi = [MyTokenModel]()
        var territoriesApi = [TerritoryModel]()
        var housesApi = [HouseModel]()
        var visitsApi = [VisitModel]()
        var tokenTerritoriesApi = [TokenTerritoryModel]()
        
        //Database Data
        var tokensDb = [MyToken]()
        var territoriesDb = [Territory]()
        var housesDb = [House]()
        var visitsDb = [Visit]()
        var tokenTerritoriesDb = [TokenTerritory]()
        
        //MARK: Fetching data from server
        var tokenApi = TokenAPI()
        
        //Owned tokens
        do {
            let ownedTokens = try await tokenApi.loadOwnedTokens()
            tokensApi.append(contentsOf: ownedTokens)
        } catch {
            return
        }
        
        //User Tokens
        do {
            let userTokens = try await tokenApi.loadUserTokens()
            tokensApi.append(contentsOf: userTokens)
        } catch {
            return
        }
        
        var alldata: AllDataResponse?

        if getAccessLevel() == AccessLevel.Admin {
            do {
                let response = try await AdminAPI().allData()
                territoriesApi = response.territories
                housesApi = response.houses
                visitsApi = response.visits
                alldata = response // Assign the response to alldata
            } catch {
                return
            }
        } else {
            do {
                let response = try await UserAPI().loadTerritories()
                territoriesApi = response.territories
                housesApi = response.houses
                visitsApi = response.visits
                alldata = response // Assign the response to alldata
            } catch {
                return
            }
        }
        
        tokensDb.append(contentsOf: tokens)
        territoriesDb.append(contentsOf: territories)
        housesDb.append(contentsOf: houses)
        visitsDb.append(contentsOf: visits)
        
        
        
        
        try tokensDb.forEach { token in
            // Create a predicate to filter the TokenTerritory entities based on the token value
            let predicate = NSPredicate(format: "token == %@", token)
            
            let fetchRequest = NSFetchRequest<TokenTerritory>(entityName: "TokenTerritory")
            fetchRequest.predicate = predicate
            
            let territoryTokensFiltered = try dataController.container.viewContext.fetch(fetchRequest)
            
            
            tokenTerritoriesDb.append(contentsOf: territoryTokensFiltered)
        }
        
        //Comparing and Updating, adding or deleting data in database by server data
        await comparingAndSynchronizeTokens(apiList: StructToModel().convertTokenStructsToEntities(structs: tokensApi), dbList: tokensDb)
        await comparingAndSynchronizeTokenTerritories(apiList: StructToModel().convertTokenTerritoriesStructsToEntities(structs: tokenTerritoriesApi), dbList: tokenTerritoriesDb)
        await comparingAndSynchronizeTerritories(apiList: StructToModel().convertTerritoryStructsToEntities(structs: territoriesApi), dbList: territoriesDb)
        await comparingAndSynchronizeHouses(apiList: StructToModel().convertHouseStructsToEntities(structs: housesApi), dbList: housesDb)
        await comparingAndSynchronizeVisits(apiList: StructToModel().convertVisitStructsToEntities(structs: visitsApi), dbList: visitsDb)
        
        
    }
    
    
    private func userNeedLogin() async -> Bool {
        do {
            _ = try await AuthenticationAPI().user()
        } catch {
            if let error = error.asAFError {
                if error.responseCode == 401 {
                    authorizationProvider.authorizationToken = nil
                    return true
                }
            }
        }
        return authorizationProvider.authorizationToken != nil
    }
    
    private func adminNeedLogin() async -> Bool {
        if isAdmin() {
            do {
                _ = try await CongregationAPI().signIn(congregationId: authorizationProvider.congregationId!, congregationPass: authorizationProvider.congregationPass!)
            } catch {
                if let error = error.asAFError {
                    if error.responseCode == 401 {
                        authorizationProvider.authorizationToken = nil
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private func getAccessLevel() -> AccessLevel {
        if authorizationProvider.congregationId != nil && authorizationProvider.congregationPass != nil {
            return AccessLevel.Admin
        } else {
            for token in tokens {
                if token.moderator {
                    return AccessLevel.Moderator
                }
            }
            if !tokens.isEmpty {
                return AccessLevel.User
            } else {
                return AccessLevel.None
            }
        }
    }
    
    func comparingAndSynchronizeTokens(apiList: [MyToken], dbList: [MyToken]) async {
        var tokensApi = apiList
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
                    dataController.save()
                }
                // Remove Token from the database to discard what does exist on the server
                // and leave only what should be deleted
                if let index = tokensDb.firstIndex(where: { $0.id == myTokenDb.id }) {
                    tokensDb.remove(at: index)
                }
            } else {
                // If it does not exist, create it
                dataController.container.viewContext.insert(myTokenApi)
                
                //Save
                dataController.save()
            }
        }
        
        // Finally, remove all tokens that don't exist on the server
        for token in tokensDb {
            dataController.container.viewContext.delete(token)
        }
    }
    
    private func comparingAndSynchronizeTerritories(apiList: [Territory], dbList: [Territory]) async {
        var territoriesApi = apiList
        var territoriesDb = dbList
        
        for territoryApi in territoriesApi {
            // Find Territory according to id
            if let territoryDb = territoriesDb.first(where: { $0.id == territoryApi.id }) {
                // If Territory does exist in the database
                if territoryApi != territoryDb {
                    // If it has differences, update in the database
                    
                    territoryDb.address = territoryApi.address
                    territoryDb.congregation = territoryApi.congregation
                    territoryDb.image = territoryApi.image
                    territoryDb.section = territoryApi.section
                    territoryDb.floors = territoryApi.floors
                    territoryDb.number = territoryApi.number
                    
                    //Save
                    dataController.save()
                }
                
                // Remove Territory from the database to discard what exists on the server
                // and leave only what should be deleted
                if let index = territoriesDb.firstIndex(of: territoryDb) {
                    territoriesDb.remove(at: index)
                }
            } else {
                // If it does not exist, create it
                dataController.container.viewContext.insert(territoryApi)
                
                //Save
                dataController.save()
            }
        }
        
        // Finally, remove all territories that don't exist on the server
        for territory in territoriesDb {
            dataController.container.viewContext.delete(territory)
        }
    }
    
    private func comparingAndSynchronizeHouses(apiList: [House], dbList: [House]) async {
        var housesApi = apiList
        var housesDb = dbList
        
        for houseApi in housesApi {
            let houseDb = housesDb.first { $0.id == houseApi.id }
            
            if let houseDb = houseDb {
                if houseApi != houseDb {
                    houseDb.number = houseApi.number
                    houseDb.territory = houseApi.territory
                    houseDb.floor = houseApi.floor
                    
                    //Save
                    dataController.save()
                }
                
                if let index = housesDb.firstIndex(of: houseDb) {
                    housesDb.remove(at: index)
                }
            } else {
                // If it does not exist, create it
                dataController.container.viewContext.insert(houseApi)
                
                //Save
                dataController.save()
            }
        }
        
        for houseDb in housesDb {
            dataController.container.viewContext.delete(houseDb)
        }
    }
    
    private func comparingAndSynchronizeVisits(apiList: [Visit], dbList: [Visit]) async{
        var visitsApi = apiList
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
                    dataController.save()
                }
                
                if let index = visitsDb.firstIndex(of: visitDb) {
                    visitsDb.remove(at: index)
                }
            } else {
                // If it does not exist, create it
                dataController.container.viewContext.insert(visitApi)
                
                //Save
                dataController.save()
            }
        }
        
        for visitDb in visitsDb {
            dataController.container.viewContext.delete(visitDb)
        }
    }
    
    private func comparingAndSynchronizeTokenTerritories(apiList: [TokenTerritory], dbList: [TokenTerritory]) async{
        var tokenTerritoriesApi = apiList
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
                dataController.container.viewContext.insert(tokenTerritoryApi)
                
                //Save
                dataController.save()
            }
        }
        
        for tokenTerritoryDb in tokenTerritoriesDb {
            dataController.container.viewContext.delete(tokenTerritoryDb)
        }
    }
    
    private func isAdmin() -> Bool {
        return authorizationProvider.congregationId != nil && authorizationProvider.congregationPass != nil
    }
}
