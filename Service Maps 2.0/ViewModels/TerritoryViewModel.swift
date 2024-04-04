//
//  TerritoryViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/14/23.
//

import Foundation
import SwiftUI
import CoreData
import SwipeActions
import Combine

@MainActor
class TerritoryViewModel: ObservableObject {
    @StateObject var synchronizationManager = SynchronizationManager.shared
    
    private var authorizationLevelManager = AuthorizationLevelManager()
    private var territories: FetchedResultList<Territory>
    private var territoryAddresses: FetchedResultList<TerritoryAddress>
    private var houses: FetchedResultList<House>
    
    @Published var territoryData: (moderatorData: [TerritoryData], userData: [TerritoryData]) = ([],[])
    
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    @Published var isAscending = true {
        didSet {
            
        }
    }// Boolean state variable to track the sorting order
    @Published var currentTerritory: Territory?
    @Published var presentSheet = false {
        didSet {
            if presentSheet == false {
                currentTerritory = nil
            }
        }
    }
    
    var sortDescriptors: [NSSortDescriptor] {
        // Compute the sort descriptors based on the current sorting order
        return [NSSortDescriptor(keyPath: \Territory.number, ascending: isAscending)]
    }
    
    
    
    func deleteTerritory(territory: Territory) {
        DataController.shared.container.viewContext.delete(territory)
        
        do {
            try DataController.shared.container.viewContext.save()
        } catch {
            print("ERROR SAVING VIEW CONTEXT DELETION")
        }
    }
    
    @ViewBuilder
    func territoryCell(territoryData: TerritoryData) -> some View {
        SwipeView {
            NavigationLink(destination: self.chooseDestination(territoryAddresses: territoryData.addresses, territory: territoryData.territory)) {
                CellView(territory: territoryData.territory, houseQuantity: territoryData.housesQuantity)
                    .padding(.bottom, 2)
            }
        } trailingActions: { context in
            if territoryData.accessLevel == .Admin {
                SwipeAction(
                    systemImage: "trash",
                    backgroundColor: .red
                ) {
                    
                    self.deleteTerritory(territory: territoryData.territory)
                    
                }
                .font(.title.weight(.semibold))
                .foregroundColor(.white)
                
                if territoryData.accessLevel == .Moderator || territoryData.accessLevel == .Admin {
                    SwipeAction(
                        systemImage: "pencil",
                        backgroundColor: Color.teal
                    ) {
                        context.state.wrappedValue = .closed
                        self.currentTerritory = territoryData.territory
                        self.presentSheet = true
                    }
                    .allowSwipeToTrigger()
                    .font(.title.weight(.semibold))
                    .foregroundColor(.white)
                }
            }
        }
        .swipeActionCornerRadius(16)
        .swipeSpacing(5)
        .swipeOffsetCloseAnimation(stiffness: 1000, damping: 70)
        .swipeOffsetExpandAnimation(stiffness: 1000, damping: 70)
        .swipeOffsetTriggerAnimation(stiffness: 1000, damping: 70)
        .swipeMinimumDistance(territoryData.accessLevel != .User ? 50:1000)
    }
    
    @ViewBuilder
    func chooseDestination(territoryAddresses: [TerritoryAddress], territory: Territory) -> some View {
        let viewFunc = territoryAddresses.count > 1
        
        if viewFunc {
            TerritoryAddressView(territory: territory)
        } else {
            HousesView(territory: territory)
        }
    }
    
    //@ViewBuilder
     func createFab() -> some View {
            return Button(action: {
                self.presentSheet.toggle()
            }, label: {
                Image(systemName: "plus")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40, alignment: .center)
            })
            .padding(8)
            .background(Color.blue.gradient)
            .cornerRadius(100)
            .padding(8)
            .shadow(radius: 3,
                    x: 3,
                    y: 3)
            .transition(.scale)
        }
    
    init(context: NSManagedObjectContext = DataController.shared.container.viewContext) {
        territories = FetchedResultList(context: context, sortDescriptors: [
            NSSortDescriptor(keyPath: \Territory.number, ascending: true)
          ])
        
        territoryAddresses = FetchedResultList(context: context, sortDescriptors: [
            NSSortDescriptor(keyPath: \TerritoryAddress.id, ascending: true)
          ])
        
        houses = FetchedResultList(context: context, sortDescriptors: [
            NSSortDescriptor(keyPath: \House.id, ascending: true)
          ])
        
        territories.willChange = { [weak self] in self?.objectWillChange.send() }
        territoryAddresses.willChange = { [weak self] in self?.objectWillChange.send() }
        houses.willChange = { [weak self] in self?.objectWillChange.send() }
        
        territories.didChange = {
            Task {
                await self.getTerritories()
            }
        }
        
        territoryAddresses.didChange = {
            Task {
                await self.getTerritories()
            }
        }
        
        houses.didChange = {
            Task {
                await self.getTerritories()
            }
        }
        
        Task.detached {
            await self.getTerritories()
        }
    }
}

extension TerritoryViewModel {
    
    
    var territoriesList: [Territory] {
        territories.items
    }
    
    var territoryAddressesList: [TerritoryAddress] {
        territoryAddresses.items
    }
    
    var housesList: [House] {
        houses.items
    }
}

extension TerritoryViewModel {
    func getTerritories() async {
        let territories = self.territoriesList
        let addresses = self.territoryAddressesList
        let houses = self.housesList

        var data = [String: TerritoryData]() // Use a dictionary to store the TerritoryData objects

        for territory in territories {
            let currentAddresses = addresses.filter { $0.territory == territory.id }
            var currentHouses = [House]()
            for address in currentAddresses {
                currentHouses += houses.filter { $0.territoryAddress == address.id }
            }
            
            var accessLevel: AccessLevel?
            accessLevel = await authorizationLevelManager.getAccessLevel(model: territory)
            
            let territoryData = TerritoryData(
                territory: territory,
                addresses: currentAddresses,
                housesQuantity: currentHouses.count,
                accessLevel: accessLevel ?? .User
            )
            
            data[territory.id ?? ""] = territoryData // Store the TerritoryData object in the dictionary using territory.id as the key
        }

        let moderatorData = data.values.filter { $0.accessLevel == .Moderator }.sorted { $0.territory.number < $1.territory.number }
        let userData = data.values.filter { $0.accessLevel != .Moderator }.sorted { $0.territory.number < $1.territory.number }

        territoryData = (moderatorData, userData)
        
    }
}
