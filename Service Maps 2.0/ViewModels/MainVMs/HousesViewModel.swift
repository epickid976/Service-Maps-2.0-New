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
    @BackgroundActor
    func deleteHouse(house: String) async -> Result<Void, Error> {
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

    // Handle scrolling to a specific house after data is received
    private func scrollToHouse(_ houseIdToScrollTo: String?) {
        if let houseIdToScrollTo = houseIdToScrollTo {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.houseIdToScrollTo = houseIdToScrollTo
            }
        }
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

    // Sort houses for better readability, considering both numbers and letters
    func sortHousesByNumber(houses: [HouseData], sort: HouseSortPredicate = .increasing) -> [HouseData] {
        var oddHouses: [HouseData] = []
        var evenHouses: [HouseData] = []
        var nonNumericHouses: [HouseData] = []

        for house in houses {
            let houseNumber = house.house.number
            // Check if there's a numeric portion in the house number
            if let number = Int(houseNumber.filter { "0"..."9" ~= $0 }) {
                // Determine if the house number is odd or even based on the numeric portion
                if number % 2 == 0 {
                    evenHouses.append(house)
                } else {
                    oddHouses.append(house)
                }
            } else {
                // If no numeric portion exists (like "A" or "Y"), treat it as non-numeric
                nonNumericHouses.append(house)
            }
        }

        // Sort odd and even houses using the natural sort key
        let sortOrder: (HouseData, HouseData) -> Bool = {
            lhs, rhs in
            let lhsKey = self.naturalSortKey(lhs.house.number)
            let rhsKey = self.naturalSortKey(rhs.house.number)
            return sort == .increasing ? (lhsKey.lexicographicallyPrecedes(rhsKey, by: { self.compareLexicographically($0, $1) })) : (rhsKey.lexicographicallyPrecedes(lhsKey, by: { self.compareLexicographically($0, $1) }))
        }

        oddHouses.sort(by: sortOrder)
        evenHouses.sort(by: sortOrder)
        nonNumericHouses.sort(by: sortOrder) // Sort non-numeric houses as well

        // Return odd, even, and non-numeric houses together
        return oddHouses + evenHouses + nonNumericHouses
    }

    // Custom lexicographical comparison to handle mixed types (Int and String)
    func compareLexicographically(_ lhs: Any, _ rhs: Any) -> Bool {
        if let lhsInt = lhs as? Int, let rhsInt = rhs as? Int {
            return lhsInt < rhsInt
        }
        if let lhsString = lhs as? String, let rhsString = rhs as? String {
            return lhsString < rhsString
        }
        // Fallback to considering Ints smaller than Strings
        return lhs is Int
    }
    
    // Helper function to split a string into numeric and non-numeric parts
    func naturalSortKey(_ houseNumber: String) -> [Any] {
        let pattern = "([0-9]+)|([^0-9]+)"
        let regex = try! NSRegularExpression(pattern: pattern)
        let nsString = houseNumber as NSString
        let matches = regex.matches(in: houseNumber, range: NSRange(location: 0, length: nsString.length))
        
        return matches.map {
            let match = nsString.substring(with: $0.range)
            // Convert numeric parts to Int, leave non-numeric parts as String
            return Int(match) ?? match
        }
    }
}
