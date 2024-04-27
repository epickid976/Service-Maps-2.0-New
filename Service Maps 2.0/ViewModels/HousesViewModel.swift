//
//  HousesViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/5/23.
//

import Foundation
import SwiftUI
import CoreData
import NukeUI
import Combine
import SwipeActions

@MainActor
class HousesViewModel: ObservableObject {
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var dataUploaderManager = DataUploaderManager()
    
    private var cancellables = Set<AnyCancellable>()
    //@ObservedObject var databaseManager = RealmManager.shared
    @Published var houseData: Optional<[HouseData]> = nil
    
    init(territoryAddress: TerritoryAddressModel) {
        self.territoryAddress = territoryAddress
        
        getHouses()
        //houses = databaseManager.housesFlow
    }
    
    @Published var backAnimation = false
    @Published var optionsAnimation = false
    @Published var progress: CGFloat = 0.0
    @Published var territoryAddress: TerritoryAddressModel
    
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    @Published var currentHouse: HouseModel?
    @Published var presentSheet = false {
        didSet {
            if presentSheet == false {
                currentHouse = nil
            }
        }
    }
    
    @Published var houseToDelete: (String?, String?)
    
    @Published var showAlert = false
    @Published var ifFailed = false
    @Published var loading = false
    
    @Published var showToast = false
    @Published var showAddedToast = false
    
    @Published var syncAnimation = false
    @Published var syncAnimationprogress: CGFloat = 0.0
    
    func deleteHouse(house: String) async -> Result<Bool, Error> {
        return await dataUploaderManager.deleteHouse(house: house)
    }
    
    func houseCellView(houseData: HouseData) -> some View {
        SwipeView {
            NavigationLink(destination: VisitsView(house: houseData.house)) {
                HouseCell(house: houseData)
                    .padding(.bottom, 2)
            }
        } trailingActions: { context in
            if houseData.accessLevel == .Admin {
                SwipeAction(
                    systemImage: "trash",
                    backgroundColor: .red
                ) {
                    DispatchQueue.main.async {
                        self.houseToDelete = (houseData.house.id, houseData.house.number)
                        self.showAlert = true
                    }
                }
                .font(.title.weight(.semibold))
                .foregroundColor(.white)
                
                
            }
            
            //                if houseData.accessLevel == .Moderator || houseData.accessLevel == .Admin {
            //                    SwipeAction(
            //                        systemImage: "pencil",
            //                        backgroundColor: Color.teal
            //                    ) {
            //                        context.state.wrappedValue = .closed
            //                        self.currentHouse = houseData.house
            //                        self.presentSheet = true
            //                    }
            //                    .allowSwipeToTrigger()
            //                    .font(.title.weight(.semibold))
            //                    .foregroundColor(.white)
            //                }
        }
        .swipeActionCornerRadius(16)
        .swipeSpacing(5)
        .swipeOffsetCloseAnimation(stiffness: 500, damping: 100)
        .swipeOffsetExpandAnimation(stiffness: 500, damping: 100)
        .swipeOffsetTriggerAnimation(stiffness: 500, damping: 100)
        .swipeMinimumDistance(houseData.accessLevel != .User ? 25:1000)
        
    }
    
    @ViewBuilder
    func alert() -> some View {
        ZStack {
            VStack {
                Text("Delete House \(houseToDelete.1 ?? "0")")
                    .font(.title)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                    .padding(.leading)
                Text("Are you sure you want to delete the selected house?")
                    .font(.title3)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                    .padding(.leading)
                if ifFailed {
                    Text("Error deleting house, please try again later")
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                //.vSpacing(.bottom)
                
                HStack {
                    if !loading {
                        CustomBackButton() {
                            withAnimation {
                                self.showAlert = false
                                self.houseToDelete = (nil,nil)
                            }
                        }
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: loading, title: "Delete", color: .red) {
                        withAnimation {
                            self.loading = true
                        }
                        Task {
                            if self.houseToDelete.0 != nil && self.houseToDelete.1 != nil {
                                switch await self.deleteHouse(house: self.houseToDelete.0 ?? "") {
                                case .success(_):
                                    withAnimation {
                                        self.synchronizationManager.startupProcess(synchronizing: true)
                                        self.getHouses()
                                        self.loading = false
                                        self.showAlert = false
                                        self.ifFailed = false
                                        self.houseToDelete = (nil,nil)
                                        self.showToast = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                            self.showToast = false
                                        }
                                    }
                                case .failure(_):
                                    withAnimation {
                                        self.loading = false
                                        self.ifFailed = true
                                    }
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
extension HousesViewModel {
    func getHouses() {
        RealmManager.shared.getHouseData(addressId: territoryAddress.id)
            .receive(on: DispatchQueue.main) // Update on main thread
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Handle errors here
                    print("Error retrieving territory data: \(error)")
                }
            }, receiveValue: { houseData in
                DispatchQueue.main.async {
                    self.houseData = houseData
                }
            })
            .store(in: &cancellables)
    }
}
