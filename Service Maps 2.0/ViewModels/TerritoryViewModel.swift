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
    
    @Published var cdPublisher = CDPublisher.shared
    
    @Published var territories = CDPublisher.shared.territories
    @Published var territoryData: (moderatorData: [TerritoryData], userData: [TerritoryData]) = CDPublisher.shared.territoryData
    
    var cancellable: AnyCancellable?

        init() {
            cancellable = cdPublisher.objectWillChange
                .sink { _ in
                    self.objectWillChange.send()
                }
        }
    
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    @Published var isAscending = true // Boolean state variable to track the sorting order
    @Published var currentTerritory: Territory?
    @Published var presentSheet = false
    
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
                    
                    if let index = self.territoryData.moderatorData.firstIndex(where: { $0 == territoryData}) {
                        self.territoryData.moderatorData.remove(at: index )
                    } else {
                        print("ERROR INDEX")
                    }
                    
                    if let index = self.territoryData.userData.firstIndex(where: { $0 == territoryData }) {
                        self.territoryData.userData.remove(at: index)
                    } else {
                        print("ERROR INDEX")
                    }
                    
                    
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
        .swipeOffsetCloseAnimation(stiffness: 160, damping: 70)
        .swipeOffsetExpandAnimation(stiffness: 160, damping: 70)
        .swipeOffsetTriggerAnimation(stiffness: 160, damping: 70)
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
    
}


