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
import MijickPopupView

@MainActor
class HousesViewModel: ObservableObject {
    
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var dataUploaderManager = DataUploaderManager()
    
    private var cancellables = Set<AnyCancellable>()
    //@ObservedObject var databaseManager = RealmManager.shared
    @Published var houseData: Optional<[HouseData]> = nil {
        didSet {
            print(houseData)
        }
    }
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    init(territoryAddress: TerritoryAddressModel, houseIdToScrollTo: String? = nil) {
        self.territoryAddress = territoryAddress
        
        getHouses(houseIdToScrollTo: houseIdToScrollTo)
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
    
    @Published var search: String = "" {
        didSet {
            getHouses()
        }
    }
    
    @Published var searchActive = false
    
    func deleteHouse(house: String) async -> Result<Bool, Error> {
        return await dataUploaderManager.deleteHouse(house: house)
    }
    
    @Published var houseIdToScrollTo: String? = nil
}

@MainActor
extension HousesViewModel {
    func getHouses(houseIdToScrollTo: String? = nil) {
        RealmManager.shared.getHouseData(addressId: territoryAddress.id)
            .subscribe(on: DispatchQueue.main)
            .receive(on: DispatchQueue.main) // Update on main thread
            .sink(receiveCompletion: { completion in
                
                if case .failure(let error) = completion {
                    // Handle errors here
                    print("Error retrieving territory data: \(error)")
                }
            }, receiveValue: { houseData in
                DispatchQueue.main.async {
                    var data = [HouseData]()
                    
                    
                    
                    if !self.search.isEmpty {
                        data =  houseData.filter { houseData in
                            houseData.house.number.lowercased().contains(self.search.lowercased()) ||
                            houseData.visit?.notes.lowercased().contains(self.search.lowercased()) ?? false
                            }
                    } else {
                        data = houseData
                    }
                    
                    if self.sortPredicate == .decreasing {
                        data = data.sorted { $0.house.number > $1.house.number }
                    } else if self.sortPredicate == .increasing {
                        data = data.sorted { $0.house.number < $1.house.number }
                    }
                    
                    if self.filterPredicate == .normal {
                        if self.sortPredicate == .decreasing {
                            data = data.sorted { $0.house.number > $1.house.number }
                        } else if self.sortPredicate == .increasing {
                            data = data.sorted { $0.house.number < $1.house.number }
                        }
                    } else if self.filterPredicate == .oddEven {
                        data = sortHousesByNumber(houses: data, sort: self.sortPredicate)
                    }
                    
                    self.houseData = data
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let houseIdToScrollTo = houseIdToScrollTo {
                            self.houseIdToScrollTo = houseIdToScrollTo
                        }
                    }
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


