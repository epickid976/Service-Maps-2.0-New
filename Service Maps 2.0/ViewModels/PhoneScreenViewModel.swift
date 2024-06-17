//
//  PhoneScreenViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/30/24.
//

import Foundation
import SwiftUI
import Nuke
import AlertKit
import Combine
import SwipeActions

@MainActor
class PhoneScreenViewModel: ObservableObject {
    
    init(phoneTerritoryToScrollTo: String? = nil) {
        getTeritories(phoneTerritoryToScrollTo: phoneTerritoryToScrollTo)
        getRecentTerritoryData()
    }
    
    @Published var phoneTerritoryToScrollTo: String? = nil 
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var dataUploaderManager = DataUploaderManager()
    
    private var cancellables = Set<AnyCancellable>()
    private var recentCancellables = Set<AnyCancellable>()
    
    @Published var phoneData: Optional<[PhoneData]> = nil
    @Published var recentPhoneData: Optional<[RecentPhoneData]> = nil
    
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    // Boolean state variable to track the sorting order
    @Published var currentTerritory: PhoneTerritoryModel?
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
    @Published var animationProgress: Bool = false
    
    @Published var showAlert = false
    @Published var ifFailed = false
    @Published var loading = false
    @Published var territoryToDelete: (String?,String?)
    
    @Published var showToast = false
    @Published var showAddedToast = false
    
    func deleteTerritory(territory: String) async -> Result<Bool, Error> {
        return await dataUploaderManager.deleteTerritory(phoneTerritory: territory)
    }
    
    @Published var search: String = "" {
        didSet {
            getTeritories()
            getRecentTerritoryData()
        }
    }
    
    @Published var searchActive = false
  
    @Published var backAnimation = false
}

@MainActor
extension PhoneScreenViewModel {
    func getTeritories(phoneTerritoryToScrollTo: String? = nil) {
        RealmManager.shared.getPhoneData()
            .receive(on: DispatchQueue.main) // Update on main thread
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Handle errors here
                    print("Error retrieving territory data: \(error)")
                }
            }, receiveValue: { phoneData in
                if self.search.isEmpty {
                    DispatchQueue.main.async {
                        self.phoneData = phoneData
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if let phoneTerritoryToScrollTo = phoneTerritoryToScrollTo {
                                self.phoneTerritoryToScrollTo = phoneTerritoryToScrollTo
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.phoneData = phoneData.filter { phoneData in
                            // Check for matches in key names
                            String(phoneData.territory.number).lowercased().contains(self.search.lowercased()) ||
                            phoneData.territory.description.lowercased().contains(self.search.lowercased())
                        }
                    }
                }
            })
            .store(in: &cancellables)
    }
    
    func getRecentTerritoryData() {
        RealmManager.shared.getRecentPhoneTerritoryData()
            .receive(on: DispatchQueue.main) // Update on main thread
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Handle errors here
                    print("Error retrieving territory data: \(error)")
                }
            }, receiveValue: { recentPhoneData in
                
                if self.search.isEmpty {
                    DispatchQueue.main.async {
                        self.recentPhoneData = recentPhoneData.sorted(by: { $0.lastCall.date > $1.lastCall.date
                        })
                    }
                } else {
                    DispatchQueue.main.async {
                        self.recentPhoneData = recentPhoneData.filter { territoryData in
                            // Check for matches in territory number (converted to string for case-insensitive comparison)
                            String(territoryData.territory.number).lowercased().contains(self.search.lowercased()) ||
                            territoryData.territory.description.lowercased().contains(self.search.lowercased())
                        }.sorted(by: { $0.lastCall.date > $1.lastCall.date
                        })
                    }
                }
            })
            .store(in: &recentCancellables)
    }
}
