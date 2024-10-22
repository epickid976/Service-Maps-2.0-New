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
import MijickPopups

@MainActor
class HousesViewModel: ObservableObject {
    
    // Dependencies
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var dataUploaderManager = DataUploaderManager()
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    // Published properties for UI updates
    @Published var houseData: [HouseData]? = nil
    @Published var territoryAddress: TerritoryAddress
    @Published var currentHouse: House?
    @Published var houseToDelete: (String?, String?) = (nil, nil)
    
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    @Published var backAnimation = false
    @Published var optionsAnimation = false
    @Published var progress: CGFloat = 0.0
    @Published var presentSheet = false {
        didSet { if !presentSheet { currentHouse = nil } }
    }
    
    @Published var showAlert = false
    @Published var ifFailed = false
    @Published var loading = false
    @Published var showToast = false
    @Published var showAddedToast = false
    @Published var syncAnimation = false
    @Published var syncAnimationprogress: CGFloat = 0.0
    
    // Sorting and Filtering
    @Published var sortPredicate: HouseSortPredicate = .increasing {
        didSet { getHouses() }
    }
    
    @Published var filterPredicate: HouseFilterPredicate = .normal {
        didSet { getHouses() }
    }
    
    @Published var search: String = "" {
        didSet { getHouses() }
    }
    
    @Published var searchActive = false
    @Published var houseIdToScrollTo: String?

    // Initialize with TerritoryAddress and optional scrolling ID
    init(territoryAddress: TerritoryAddress, houseIdToScrollTo: String? = nil) {
        self.territoryAddress = territoryAddress
        getHouses(houseIdToScrollTo: houseIdToScrollTo)
    }
    
    // Delete house logic
    func deleteHouse(house: String) async -> Result<Bool, Error> {
        return await dataUploaderManager.deleteHouse(houseId: house)
    }
}

@MainActor
extension HousesViewModel {
    // Fetch and observe house data from GRDB
    func getHouses(houseIdToScrollTo: String? = nil) {
        GRDBManager.shared.getHouseData(addressId: territoryAddress.id)
            .receive(on: DispatchQueue.main)  // Ensure updates on the main thread
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("Error retrieving house data: \(error)")
                    self?.ifFailed = true
                }
            }, receiveValue: { [weak self] houseData in
                self?.handleHouseData(houseData, scrollTo: houseIdToScrollTo)
            })
            .store(in: &cancellables)
    }
    
    // Handle and process house data based on search, sort, and filter criteria
    private func handleHouseData(_ houseData: [HouseData], scrollTo houseIdToScrollTo: String?) {
        var filteredData = houseData

        if !search.isEmpty {
            filteredData = houseData.filter {
                $0.house.number.lowercased().contains(search.lowercased()) ||
                $0.visit?.notes.lowercased().contains(search.lowercased()) ?? false
            }
        }

        filteredData = sortHouses(filteredData)
        filteredData = filterHouses(filteredData)

        self.houseData = filteredData
        scrollToHouse(houseIdToScrollTo)
    }

    // Sorting houses based on predicate
    private func sortHouses(_ houses: [HouseData]) -> [HouseData] {
        switch sortPredicate {
        case .increasing:
            return houses.sorted { $0.house.number < $1.house.number }
        case .decreasing:
            return houses.sorted { $0.house.number > $1.house.number }
        }
    }

    // Filtering houses based on predicate
    private func filterHouses(_ houses: [HouseData]) -> [HouseData] {
        switch filterPredicate {
        case .normal:
            return houses
        case .oddEven:
            return sortHousesByNumber(houses: houses, sort: sortPredicate)
        }
    }

    // Handle scrolling to a specific house after data is received
    private func scrollToHouse(_ houseIdToScrollTo: String?) {
        if let houseIdToScrollTo = houseIdToScrollTo {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.houseIdToScrollTo = houseIdToScrollTo
            }
        }
    }
    
    //Sort Houses for better readability
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
}
