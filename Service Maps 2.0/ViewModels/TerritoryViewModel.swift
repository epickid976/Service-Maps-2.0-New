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

@MainActor
class TerritoryViewModel: ObservableObject {
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var dataUploaderManager = DataUploaderManager()
    
    @Published private var cancellables = Set<AnyCancellable>()
    @Published private var recentCancellables = Set<AnyCancellable>()
    
    @Published var territoryData: Optional<[TerritoryDataWithKeys]> = nil {
        didSet {
            print(territoryData)
        }
    }
    @Published var recentTerritoryData: Optional<[RecentTerritoryData]> = nil
    
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    // Boolean state variable to track the sorting order
    @Published var currentTerritory: TerritoryModel?
    @Published var presentSheet = false {
        didSet {
            print("Present Sheet = \(presentSheet)")
            if presentSheet == false {
                currentTerritory = nil
            }
        }
    }
    
    @Published var progress: CGFloat = 0.0
    @Published var optionsAnimation = false
    @Published var syncAnimation = false
    @Published var syncAnimationprogress: CGFloat = 0.0
    @Published var backAnimation = false
    
    
    @Published var restartAnimation = false
    @Published var animationProgress: Bool = false
    
    @Published var showAlert = false
    @Published var ifFailed = false
    @Published var loading = false
    @Published var territoryToDelete: (String?,String?)
    
    @Published var showToast = false
    @Published var showAddedToast = false
    
    @Published var search: String = "" {
        didSet {
            getTerritories()
            getRecentTerritories()
        }
    }
    
    @Published var searchActive = false
    
    
    func deleteTerritory(territory: String) async -> Result<Bool, Error> {
        return await dataUploaderManager.deleteTerritory(territory: territory)
    }
    
    func resync() {
        synchronizationManager.startupProcess(synchronizing: true)
    }
    
    
    
    @Published var territoryIdToScrollTo: String?
    
    
    init(territoryIdToScrollTo: String? = nil) {
        getTerritories(territoryIdToScrollTo: territoryIdToScrollTo)
        getRecentTerritories()
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
    
   
    
}

@MainActor
extension TerritoryViewModel {
    func getTerritories(territoryIdToScrollTo: String? = nil) {
        RealmManager.shared.getTerritoryData()
            .subscribe(on: DispatchQueue.main)
            .receive(on: DispatchQueue.main) // Update on main thread
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Handle errors here
                    print("Error retrieving territory data: \(error)")
                }
            }, receiveValue: { territoryData in
                print("Sinked territory data: \(territoryData)")
                DispatchQueue.main.async {
                    self.territoryData = territoryData
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let territoryIdToScrollTo = territoryIdToScrollTo {
                        self.territoryIdToScrollTo = territoryIdToScrollTo
                    }
                }
            })
            .store(in: &cancellables)
    }
}

@MainActor
extension TerritoryViewModel {
    func getRecentTerritories() {
        RealmManager.shared.getRecentTerritoryData()
            .subscribe(on: DispatchQueue.main)
            .receive(on: DispatchQueue.main) // Update on main thread)
            
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Handle errors here
                    print("Error retrieving territory data: \(error)")
                }
            }, receiveValue: { territoryData in
                if self.search.isEmpty {
                    DispatchQueue.main.async {
                        self.recentTerritoryData = territoryData.sorted(by: { $0.lastVisit.date > $1.lastVisit.date
                        })
                    }
                } else {
                    DispatchQueue.main.async {
                        self.recentTerritoryData = territoryData.filter { territoryData in
                            // Check for matches in territory number (converted to string for case-insensitive comparison)
                            String(territoryData.territory.number).lowercased().contains(self.search.lowercased()) ||
                            territoryData.territory.description.lowercased().contains(self.search.lowercased())
                        }
                    }
                }
            })
            .store(in: &recentCancellables)
    }
}


//struct TerritoryGroupView: View {
//
//  let dataWithKeys: TerritoryDataWithKeys // Replace with your data model
//
//  
//}
