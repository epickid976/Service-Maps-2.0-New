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
    @Published var forceRefresh = false
    // Cancellables for managing Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    private var recentCancellables = Set<AnyCancellable>()
    
    // Published variables to update the UI
    @Published var territoryData: [TerritoryDataWithKeys]? = nil
    @Published var recentTerritoryData: [RecentTerritoryData]? = nil
    @Published var currentTerritory: Territory?
    
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    
    // State variables for UI
    @Published var presentSheet = false {
        didSet {
            if !presentSheet {
                currentTerritory = nil
            }
        }
    }
    
    @Published var progress: CGFloat = 0.0
    @Published var optionsAnimation = false
    @Published var syncAnimation = false
    @Published var syncAnimationprogress: CGFloat = 0.0
    @Published var restartAnimation = false
    @Published var animationProgress: Bool = false
    
    @Published var search: String = "" {
        didSet {
            getTerritories()
            getRecentTerritories()
        }
    }
    
    @Published var territoryToDelete: (String? , String?) = (nil,nil)
    
    @Published var searchActive = false
    @Published var showAlert = false
    @Published var ifFailed = false
    @Published var loading = false
    @Published var showToast = false
    @Published var showAddedToast = false
    @Published var territoryIdToScrollTo: String?
    @Published var backAnimation = false
    
    
    init(territoryIdToScrollTo: String? = nil) {
        getTerritories(territoryIdToScrollTo: territoryIdToScrollTo)
        getRecentTerritories()
    }
    
    func deleteTerritory(territory: String) async -> Result<Bool, Error> {
        return await dataUploaderManager.deleteTerritory(territoryId: territory)
    }
    
    func processData(dataWithKeys: TerritoryDataWithKeys) -> String {
        dataWithKeys.keys.sorted { $0.name < $1.name }
            .map { $0.name }
            .joined(separator: ", ")
    }
    
    func getLastTime() -> Date? {
        return dataStore.lastTime
    }
}

@MainActor
extension TerritoryViewModel {
    // Fetching Territory data from GRDB using Combine
    func getTerritories(territoryIdToScrollTo: String? = nil) {
        
        GRDBManager.shared.getTerritoryData()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    print("Error retrieving territory data: \(error)")
                    self.ifFailed = true
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] territoryData in
                let sortedTerritoryData = territoryData.sorted {
                    ($0.keys.first?.name ?? "") < ($1.keys.first?.name ?? "")
                }
                if self?.territoryData == nil {
                    DispatchQueue.main.async {
                        withAnimation {
                            self?.territoryData = sortedTerritoryData
                        }
                    }
                } else {
                    // If territoryData is already set, simply update it with sorted data
                    DispatchQueue.main.async {
                        withAnimation {
                            self?.territoryData? = sortedTerritoryData
                        }
                    }
                }
                
                if let territoryIdToScrollTo = territoryIdToScrollTo {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self?.territoryIdToScrollTo = territoryIdToScrollTo
                    }
                }
            })
            .store(in: &cancellables)
    }
    
    // Fetching Recent Territory data from GRDB using Combine
    func getRecentTerritories() {
        GRDBManager.shared.getRecentTerritoryData()  // Calls the GRDB function to get recent territories
            .receive(on: DispatchQueue.main)  // Ensure the result is received on the main thread
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    print("Error retrieving recent territory data: \(error)")
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] recentTerritories in
                if self?.search.isEmpty == true {
                    self?.recentTerritoryData = recentTerritories.sorted { $0.lastVisit.date > $1.lastVisit.date }
                } else {
                    self?.recentTerritoryData = recentTerritories.filter { territoryData in
                        String(territoryData.territory.number).lowercased().contains(self?.search.lowercased() ?? "") ||
                        territoryData.territory.description.lowercased().contains(self?.search.lowercased() ?? "")
                    }
                }
            })
            .store(in: &cancellables)
    }
}
