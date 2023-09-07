//
//  CoreDataPublisher.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/4/23.
//

import Combine
import CoreData
import Foundation

//@MainActor
class CDPublisher: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    
    private var authorizationLevelManager = AuthorizationLevelManager()

    @Published var territories = [Territory]()
    private let territoriesFetchedResultsController: NSFetchedResultsController<Territory> 
    
    @Published var territoryAddresses = [TerritoryAddress]()
    private let territoryAddressesFetchedResultsController: NSFetchedResultsController<TerritoryAddress>
    
    @Published var houses = [House]()
    private let housesFetchedResultsController: NSFetchedResultsController<House>
    
    @Published var visits = [Visit]()
    private let visitsFetchedResultsController: NSFetchedResultsController<Visit>
    
    @Published var territoryData: (moderatorData: [TerritoryData], userData: [TerritoryData]) = ([], [])
    
    
    private override init() {
        territoriesFetchedResultsController = NSFetchedResultsController(fetchRequest: Territory.allTerritories, managedObjectContext: DataController.shared.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        territoryAddressesFetchedResultsController = NSFetchedResultsController(fetchRequest: TerritoryAddress.allAddresses, managedObjectContext: DataController.shared.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        housesFetchedResultsController = NSFetchedResultsController(fetchRequest: House.allHouses, managedObjectContext: DataController.shared.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        visitsFetchedResultsController = NSFetchedResultsController(fetchRequest: Visit.allVisits, managedObjectContext: DataController.shared.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        super.init()
        territoriesFetchedResultsController.delegate = self
        territoryAddressesFetchedResultsController.delegate = self
        housesFetchedResultsController.delegate = self
        visitsFetchedResultsController.delegate = self
        
        do {
            try territoryAddressesFetchedResultsController.performFetch ()
            guard let territoryAddresses = territoryAddressesFetchedResultsController.fetchedObjects else { return }
            self.territoryAddresses = territoryAddresses
        } catch {
            print (error)
        }
        
        do {
            try housesFetchedResultsController.performFetch ()
            guard let houses = housesFetchedResultsController.fetchedObjects else { return }
            self.houses = houses
        } catch {
            print (error)
        }
        
        do {
            try visitsFetchedResultsController.performFetch ()
            guard let visits = visitsFetchedResultsController.fetchedObjects else { return }
            self.visits = visits
        } catch {
            print (error)
        }
        
        do {
            try territoriesFetchedResultsController.performFetch ()
            guard let territories = territoriesFetchedResultsController.fetchedObjects else { return }
            self.territories = territories
        } catch {
            print (error)
        }
       
        
        setupAsyncDataWithCompletion { territoryData in
            DispatchQueue.main.async {
                self.territoryData = territoryData
            }
        }
        
        
    }

    func setupAsyncDataWithCompletion(completion: @escaping ((moderatorData: [TerritoryData], userData: [TerritoryData])) -> Void) {
        Task {
            let territoryData = self.getTerritories
            await completion(territoryData())
        }
    }
    
    func getTerritories() async -> (moderatorData: [TerritoryData], userData: [TerritoryData]) {
        let territories = self.territories
        let addresses = self.territoryAddresses
        let houses = self.houses
        
        var data = [TerritoryData]()
        
        for territory in territories {
            let currentAddresses = addresses.filter { $0.territory == territory.id }
            var currentHouses = [House]()
            for address in currentAddresses {
                currentHouses += houses.filter { $0.territoryAddress == address.id }
            }
            
            var accessLevel: AccessLevel?
            accessLevel = await authorizationLevelManager.getAccessLevel(model: territory)
            
            data.append(
                TerritoryData(
                    territory: territory,
                    addresses: currentAddresses,
                    housesQuantity: currentHouses.count,
                    accessLevel: accessLevel ?? .User
                )
            )
        }
        
        let moderatorData = data.filter { $0.accessLevel == .Moderator }.sorted { $0.territory.number < $1.territory.number }
        let userData = data.filter { $0.accessLevel != .Moderator }.sorted { $0.territory.number < $1.territory.number }
        
        return (moderatorData, userData)
    }
    
    private func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) async {
        print("Hello")
        if controller === territoriesFetchedResultsController {
            if let territories = controller.fetchedObjects as? [Territory] {
                self.territories = territories
            }
        } else if controller === territoryAddressesFetchedResultsController {
            if let territoryAddresses = controller.fetchedObjects as? [TerritoryAddress] {
                self.territoryAddresses = territoryAddresses
            }
        } else if controller === housesFetchedResultsController {
            if let houses = controller.fetchedObjects as? [House] {
                self.houses = houses
            }
        } else if controller === visitsFetchedResultsController {
            if let visits = controller.fetchedObjects as? [Visit] {
                self.visits = visits
            }
        }
        
        setupAsyncDataWithCompletion { territoryData in
            DispatchQueue.main.async {
                self.territoryData = territoryData
            }
        }
    }
    
    class var shared: CDPublisher {
        struct Static {
            static let instance = CDPublisher()
        }
        
        return Static.instance
    }
}

//extension CDPublisher: NSFetchedResultsControllerDelegate {
//    private func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) async {
//        if let territories = controller.fetchedObjects as? [Territory] {
//            self.territories = territories
//        }
//        
//        if let territoryAddresses = controller.fetchedObjects as? [TerritoryAddress] {
//            self.territoryAddresses = territoryAddresses
//        }
//        
//        if let houses = controller.fetchedObjects as? [House] {
//            self.houses = houses
//        }
//        
//        if let visits = controller.fetchedObjects as? [Visit] {
//            self.visits = visits
//        }
//        
//        self.territoryData = await getTerritories()
//    }
//}


