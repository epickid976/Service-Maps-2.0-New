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
    
    @Published var sortPredicate: HouseSortPredicate = .increasing {
        didSet {
            getHouses()
        }
    }
    @Published var filterPredicate: HouseFilterPredicate = .normal {
        didSet {
            getHouses()
        }
    }
    
    func deleteHouse(house: String) async -> Result<Bool, Error> {
        return await dataUploaderManager.deleteHouse(house: house)
    }
    
    func houseCellView(houseData: HouseData, mainWindowSize: CGSize) -> some View {
        SwipeView {
            NavigationLink(destination: VisitsView(house: houseData.house)) {
                HouseCell(house: houseData, mainWindowSize: mainWindowSize)
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
                    .font(.title3)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                    .padding(.leading)
                Text("Are you sure you want to delete the selected house?")
                    .font(.headline)
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
                    var data = [HouseData]()
                    
                    if self.sortPredicate == .decreasing {
                        data = houseData.sorted { $0.house.number > $1.house.number }
                    } else if self.sortPredicate == .increasing {
                        data = houseData.sorted { $0.house.number < $1.house.number }
                    }
                    
                    if self.filterPredicate == .normal {
                        if self.sortPredicate == .decreasing {
                            data = houseData.sorted { $0.house.number > $1.house.number }
                        } else if self.sortPredicate == .increasing {
                            data = houseData.sorted { $0.house.number < $1.house.number }
                        }
                    } else if self.filterPredicate == .oddEven {
                        data = sortHousesByNumber(houses: houseData, sort: self.sortPredicate)
                    }
                    
                    self.houseData = data
                }
            })
            .store(in: &cancellables)
    }
}

func sortHousesByNumber(houses: [HouseData], sort: HouseSortPredicate = .increasing) -> [HouseData] {
    var oddHouses: [HouseData] = []
    var evenHouses: [HouseData] = []

    for house in houses {
        if let number = Int(house.house.number.filter { "0"..."9" ~= $0 }) {
            if number % 2 == 0 {
                evenHouses.append(house)
            } else {
                oddHouses.append(house)
            }
        }
    }
    if sort == .increasing {
        oddHouses.sort { Int($0.house.number.filter { "0"..."9" ~= $0 }) ?? 0 < Int($1.house.number.filter { "0"..."9" ~= $0 }) ?? 0 }
        evenHouses.sort { Int($0.house.number.filter { "0"..."9" ~= $0 }) ?? 0 < Int($1.house.number.filter { "0"..."9" ~= $0 }) ?? 0 }
    } else {
        oddHouses.sort { Int($0.house.number.filter { "0"..."9" ~= $0 }) ?? 0 > Int($1.house.number.filter { "0"..."9" ~= $0 }) ?? 0 }
        evenHouses.sort { Int($0.house.number.filter { "0"..."9" ~= $0 }) ?? 0 > Int($1.house.number.filter { "0"..."9" ~= $0 }) ?? 0 }
    }
    return oddHouses + evenHouses
}


func sortOddEven(strings: [String]) -> ([String], [String]) {
    let numbers = strings.map { Int($0.filter { "0"..."9" ~= $0 }) ?? 0 }
    var oddStrings: [String] = []
    var evenStrings: [String] = []

    for (index, number) in numbers.enumerated() {
        if number % 2 == 0 {
            evenStrings.append(strings[index])
        } else {
            oddStrings.append(strings[index])
        }
    }

    return (oddStrings.sorted(), evenStrings.sorted())
}


