//
//  Persistence.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/27/23.
//

import CoreData

struct DataController {
    static let shared = DataController()
    
    static var preview: DataController = {
        let result = DataController(inMemory: true)
        let viewContext = result.container.viewContext
        for index in 0..<10 {
            let newTerritory = Territory(context: viewContext)
            newTerritory.id = UUID().uuidString
            newTerritory.territoryDescription = "1850 W 56 St Hialeah FL 33012 United States"
            newTerritory.congregation = "1260"
            newTerritory.number = Int32(index)
            
            let newHouse = House(context: viewContext)
            newHouse.id = UUID().uuidString
            newHouse.number = "101"
            
            let newVisit = Visit(context: viewContext)
            newVisit.id = UUID().uuidString
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Service_Maps")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Show some error here
            }
        }
    }
    
    func getTerritories() -> [Territory] {
        let territoriesRequest = NSFetchRequest<NSManagedObject>(entityName: "Territory")
        var territories = try! DataController.shared.container.viewContext.fetch(territoriesRequest) as! [Territory]
        
        return territories
    }
    
    func getHouses() -> [House] {
        let housesRequest = NSFetchRequest<NSManagedObject>(entityName: "House")
        var houses = try! DataController.shared.container.viewContext.fetch(housesRequest) as! [House]
        
        return houses
    }
    
    func getVisits() -> [Visit] {
        let visitsRequest = NSFetchRequest<NSManagedObject>(entityName: "Visit")
        var visits = try! DataController.shared.container.viewContext.fetch(visitsRequest) as! [Visit]
        
        return visits
    }
    
    func getMyTokens() -> [MyToken] {
        let tokensRequest = NSFetchRequest<NSManagedObject>(entityName: "MyToken")
        var tokens = try! DataController.shared.container.viewContext.fetch(tokensRequest) as! [MyToken]
        
        return tokens
    }
    
    func getTerritoryAddresses() -> [TerritoryAddress] {
        let territoryAddressRequest = NSFetchRequest<NSManagedObject>(entityName: "TerritoryAddress")
        var territoryAddresses = try! DataController.shared.container.viewContext.fetch(territoryAddressRequest) as! [TerritoryAddress]
        
        return territoryAddresses
    }
    
    func getTokenTerritories() -> [TokenTerritory] {
        let tokenTerritoryRequest = NSFetchRequest<NSManagedObject>(entityName: "TokenTerritory")
        var tokenTerritory = try! DataController.shared.container.viewContext.fetch(tokenTerritoryRequest) as! [TokenTerritory]
        
        return tokenTerritory
    }
    
    
    
}
