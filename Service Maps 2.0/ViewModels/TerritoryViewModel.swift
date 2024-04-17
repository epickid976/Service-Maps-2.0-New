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
    private var cancellables = Set<AnyCancellable>()
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    private var authorizationLevelManager = AuthorizationLevelManager()
    
    @ObservedObject var databaseManager = RealmManager.shared
    
    @Published var territoryData: (moderatorData: [TerritoryData], userData: [TerritoryData]) = ([],[]) {
        didSet {
            print(territoryData)
        }
    }
    
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    // Boolean state variable to track the sorting order
    @Published var currentTerritory: TerritoryObject?
    @Published var presentSheet = false {
        didSet {
            if presentSheet == false {
                currentTerritory = nil
            }
        }
    }
    
    @Published var progress: CGFloat = 0.0
    @Published var optionsAnimation = false
    
    
    func deleteTerritory(territory: TerritoryObject) {
        
    }
    
    @ViewBuilder
    func territoryCell(territoryData: TerritoryData) -> some View {
        SwipeView {
            NavigationLink(destination: TerritoryAddressView(territory: territoryData.territory)) {
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
    
    
    init() {
      getTerritories()
    }
}

@MainActor
extension TerritoryViewModel {
    func getTerritories() {
        RealmManager.shared.getTerritoryData()
        .receive(on: DispatchQueue.main) // Update on main thread
        .sink(receiveCompletion: { completion in
          if case .failure(let error) = completion {
            // Handle errors here
            print("Error retrieving territory data: \(error)")
          }
        }, receiveValue: { territoryData in
          self.territoryData = (moderatorData: territoryData.filter { $0.accessLevel == .Moderator }.sorted { $0.territory.number < $1.territory.number },
                                userData: territoryData.filter { $0.accessLevel != .Moderator }.sorted { $0.territory.number < $1.territory.number })
        })
        .store(in: &cancellables)
    }

}


