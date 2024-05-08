//
//  TerritoryViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/14/23.
//

import Foundation
import SwiftUI
import SwipeActions
import Combine
import Lottie
import UIKit
import PopupView

@MainActor
class TerritoryViewModel: ObservableObject {
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var dataUploaderManager = DataUploaderManager()
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var territoryData: Optional<[TerritoryDataWithKeys]> = nil
    
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    // Boolean state variable to track the sorting order
    @Published var currentTerritory: TerritoryModel?
    @Published var presentSheet = false {
        didSet {
            if presentSheet == false {
                currentTerritory = nil
            }
        }
    }
    
    @Published var progress: CGFloat = 0.0
    @Published var optionsAnimation = false
    @Published var syncAnimation = false
    @Published var syncAnimationprogress: CGFloat = 0.0
    
    @Published var restartAnimation = false
    @Published var animationProgress: Bool = false {
        didSet {
            print(animationProgress)
        }
    }
    
    @Published var showAlert = false
    @Published var ifFailed = false
    @Published var loading = false
    @Published var territoryToDelete: (String?,String?)
    
    @Published var showToast = false
    @Published var showAddedToast = false
    
    
    func deleteTerritory(territory: String) async -> Result<Bool, Error> {
        return await dataUploaderManager.deleteTerritory(territory: territory)
    }
    
    func resync() {
        synchronizationManager.startupProcess(synchronizing: true)
    }
    
    
    
    @ViewBuilder
    func territoryCell(dataWithKeys: TerritoryDataWithKeys) -> some View {
        
        LazyVStack {
            if !dataWithKeys.keys.isEmpty {
                Text(self.processData(dataWithKeys: dataWithKeys))
                    .font(.title2)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                    .padding(5)
                    .padding(.horizontal, 10)
            } else {
                Spacer()
                    .frame(height: 20)
            }
        }
        // Loop through territoryData here (replace with your TerritoryItemView implementation)
        LazyVStack {
            ForEach(dataWithKeys.territoriesData, id: \.territory.id) { territoryData in
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
                            DispatchQueue.main.async {
                                self.territoryToDelete = (territoryData.territory.id, String(territoryData.territory.number))
                                self.showAlert = true
                            }
                        }
                        .font(.title.weight(.semibold))
                        .foregroundColor(.white)
                        
                        
                    }
                    
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
                .swipeActionCornerRadius(16)
                .swipeSpacing(5)
                .swipeOffsetCloseAnimation(stiffness: 500, damping: 100)
                .swipeOffsetExpandAnimation(stiffness: 500, damping: 100)
                .swipeOffsetTriggerAnimation(stiffness: 500, damping: 100)
                .swipeMinimumDistance(territoryData.accessLevel != .User ? 25:1000)
            }
        }.padding(.horizontal, 15)
        
    }
    
    
    init() {
        getTerritories()
    }
    
    
    func processData(dataWithKeys: TerritoryDataWithKeys) -> String {
        var name = ""
        if !dataWithKeys.keys.isEmpty {
            let data = dataWithKeys.keys.sorted { $0.name < $1.name}
            for key in data {
                if name.isEmpty {
                    name = key.name
                } else {
                    name += ", " + key.name
                }
            }
            return name
        }
        return name
    }
    
    func getLastTime() -> Date? { return dataStore.lastTime }
    
    @ViewBuilder
    func alert() -> some View {
        ZStack {
            VStack {
                Text("Delete Territory \(territoryToDelete.1 ?? "0")")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                    .padding(.leading)
                Text("Are you sure you want to delete the selected territory?")
                    .font(.headline)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                    .padding(.leading)
                if ifFailed {
                    Text("Error deleting territory, please try again later")
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                //.vSpacing(.bottom)
                
                HStack {
                    if !loading {
                        CustomBackButton() {
                            withAnimation {
                                self.showAlert = false
                                self.territoryToDelete = (nil,nil)
                            }
                        }
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: loading, title: "Delete", color: .red) {
                        withAnimation {
                            self.loading = true
                        }
                        Task {
                            if self.territoryToDelete.0 != nil && self.territoryToDelete.1 != nil {
                                switch await self.deleteTerritory(territory: self.territoryToDelete.0 ?? "") {
                                case .success(_):
                                    withAnimation {
                                        withAnimation {
                                            self.loading = false
                                        }
                                        self.showAlert = false
                                        self.territoryToDelete = (nil,nil)
                                        self.showToast = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                            self.showToast = false
                                        }
                                    }
                                case .failure(_):
                                    withAnimation {
                                        self.loading = false
                                    }
                                    self.ifFailed = true
                                }
                            }
                        }
                        
                    }
                }
                .padding([.horizontal, .bottom])
                //.vSpacing(.bottom)
                
            }
            .ignoresSafeArea(.keyboard)
            
        }.ignoresSafeArea(.keyboard)
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
                DispatchQueue.main.async {
                    self.territoryData = territoryData
                }
            })
            .store(in: &cancellables)
    }
}


//struct TerritoryGroupView: View {
//
//  let dataWithKeys: TerritoryDataWithKeys // Replace with your data model
//
//  
//}
