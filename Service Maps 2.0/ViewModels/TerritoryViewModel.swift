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
    private var recentCancellables = Set<AnyCancellable>()
    
    @Published var territoryData: Optional<[TerritoryDataWithKeys]> = nil
    @Published var recentTerritoryData: Optional<[RecentTerritoryData]> = nil {
        didSet {
            print(recentTerritoryData)
        }
    }
    
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
    
    @Published var search: String = "" {
        didSet {
            getRecentTerritories()
            getTerritories()
        }
    }
    
    @Published var searchActive = false
    
    
    func deleteTerritory(territory: String) async -> Result<Bool, Error> {
        return await dataUploaderManager.deleteTerritory(territory: territory)
    }
    
    func resync() {
        synchronizationManager.startupProcess(synchronizing: true)
    }
    
    
    
    
    
    
    init() {
        getTerritories()
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
    func getTerritories() {
        RealmManager.shared.getTerritoryData()
            .receive(on: DispatchQueue.main) // Update on main thread
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Handle errors here
                    print("Error retrieving territory data: \(error)")
                }
            }, receiveValue: { territoryData in
                if self.search.isEmpty {
                    DispatchQueue.main.async {
                        self.territoryData = territoryData
                    }
                } else {
                    DispatchQueue.main.async {
                        self.territoryData = territoryData.filter { territoryData in
                            // Check for matches in key names
                            territoryData.keys.contains { key in
                                key.name.lowercased().contains(self.search.lowercased())
                            } ||
                            // Check for matches in territory number (converted to string for case-insensitive comparison)
                            territoryData.territoriesData.contains { territory in
                                String(territory.territory.number).lowercased().contains(self.search.lowercased()) ||
                                territory.territory.description.lowercased().contains(self.search.lowercased())
                            }
                        }
                    }
                }
            })
            .store(in: &cancellables)
    }
    
    func getRecentTerritories() {
        RealmManager.shared.getRecentTerritoryData()
            .receive(on: DispatchQueue.main) // Update on main thread
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Handle errors here
                    print("Error retrieving territory data: \(error)")
                }
            }, receiveValue: { territoryData in
                if self.search.isEmpty {
                    self.recentTerritoryData = territoryData.sorted(by: { $0.lastVisit.date > $1.lastVisit.date
                    })
                } else {
                    self.recentTerritoryData = territoryData.filter { territoryData in
                        // Check for matches in territory number (converted to string for case-insensitive comparison)
                            String(territoryData.territory.number).lowercased().contains(self.search.lowercased()) ||
                            territoryData.territory.description.lowercased().contains(self.search.lowercased())
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
