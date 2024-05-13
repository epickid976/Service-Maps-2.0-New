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
    
    init() {
        getTeritories()
    }
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var dataUploaderManager = DataUploaderManager()
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var phoneData: Optional<[PhoneData]> = nil
    
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
        return await dataUploaderManager.deleteTerritory(phoneTerritory: territory)
    }
    
    @Published var search: String = "" {
        didSet {
            getTeritories()
        }
    }
    
    @Published var searchActive = false
  
}

@MainActor
extension PhoneScreenViewModel {
    func getTeritories() {
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
}
