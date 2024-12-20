//
//  AddKeyViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/23/24.
//

import Foundation
import SwiftUI
import Combine

// MARK: - AddKeyViewModel

@MainActor
class AddKeyViewModel: ObservableObject {
    
    // MARK: - Dependencies
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var dataUploaderManager = DataUploaderManager()
    @Published private var dataUploader = DataUploaderManager()
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    
    // MARK: - Initializers
    
    init(keyData: KeyData?) {
            self.keyData = keyData
            if let keyData = keyData {
                getTerritories(withTerritories: keyData.territories)
                servant = keyData.key.moderator
                name = keyData.key.name
            }
            error = ""
            getTerritories()
        }
    
    // MARK: - Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    
    @Published var keyData: KeyData?
    @Published var name = ""
    @Published var servant = false
    
    @Published var error = ""
    
    @Published var loading = false
    
    @Published var territoryData: Optional<[TerritoryDataWithKeys]> = nil
    
    @Published var selectedTerritories = [TerritoryData]()
    @Published var syncAnimation = false
    @Published var syncAnimationprogress: CGFloat = 0.0
    
    @Published var progress: CGFloat = 0.0
    @Published var optionsAnimation = false
    
    // MARK: - UI Helper Methods
                       
    func isSelected(territoryData: TerritoryData) -> Bool {
        return selectedTerritories.contains(territoryData)
    }

    func toggleSelection(for territoryData: TerritoryData) {
        HapticManager.shared.trigger(.selectionChanged)
        if let index = self.selectedTerritories.firstIndex(of: territoryData) {
            self.selectedTerritories.remove(at: index)
        } else {
            // Avoid adding duplicates
            if !self.selectedTerritories.contains(territoryData) {
                self.selectedTerritories.append(territoryData)
            }
        }
        // Force view update by reassigning the array
        self.selectedTerritories = self.selectedTerritories
    }
    
    // MARK: - Methods
    @BackgroundActor
    func addToken() async -> Result<Void, Error> {
        await MainActor.run {
            withAnimation {
                loading = true
            }
        }
        
        // Create token object
        let tokenObject = await Token(id: "", name: name, owner: "", congregation: dataStore.congregationName ?? "", moderator: servant)
        
        // Collect territories and avoid duplicates using a Set
        var territoriesSet = [String]()
        var territoryObjectsSet = Set<Territory>()
        
        // Populate the territories from selectedTerritories
        await selectedTerritories.forEach { territory in
            territoriesSet.append(territory.territory.id)  // Use Set to avoid duplicates
            territoryObjectsSet.insert(territory.territory)
        }

        // Handle editing token
        if let keyData = await keyData {
            return await dataUploader.editToken(token: keyData.key.id, territories: Array(territoryObjectsSet)) // Convert set back to array
        } else {
            // Creating a new token
            // Pass territories as a plain array of strings
            let territoriesToSend = territoryObjectsSet.map { $0.id }
            let newTokenForm = await NewTokenForm(
                name: tokenObject.name,
                moderator: tokenObject.moderator,
                territories: territoriesToSend.description,  // Pass array directly, no .description
                congregation: AuthorizationProvider.shared.congregationId ?? 0,
                expire: tokenObject.expire
            )
            
            // Call the API to create a new token
            switch await dataUploader.createToken(newTokenForm: newTokenForm, territories: Array(territoryObjectsSet)) {
            case .success(_):
                return .success(())
            case .failure(let error):
                return .failure(error)
            }
        }
    }
    
    func checkInfo() -> Bool {
        if name == "" || selectedTerritories.isEmpty {
            error = NSLocalizedString("Please fill out all the required fields.", comment: "")
            return false
        } else {
            return true
        }
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
    
}

// MARK: - Extension Publishers
@MainActor
extension AddKeyViewModel {
    
    // MARK: - Fetch Territories
    
    func getTerritories() {
        GRDBManager.shared.getTerritoryData()
            .receive(on: DispatchQueue.main) // Update on main thread
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Handle errors here
                    print("Error retrieving territory data: \(error)")
                }
            }, receiveValue: { territoryData in
                self.territoryData = territoryData.sorted {
                    ($0.keys.first?.name ?? "") < ($1.keys.first?.name ?? "")
                }
            })
            .store(in: &cancellables)
    }
    
    func getTerritories(withTerritories selectedTerritories: [Territory]) {
        GRDBManager.shared.getTerritoryData()
            .receive(on: DispatchQueue.main)
            .map { territoryDataWithKeys -> [TerritoryDataWithKeys] in
                // Filter the territories based on selected Territory objects
                return territoryDataWithKeys.map { dataWithKeys in
                    var filteredDataWithKeys = dataWithKeys
                    filteredDataWithKeys.territoriesData = dataWithKeys.territoriesData.filter { territoryData in
                        // Avoid re-adding duplicates
                        !self.selectedTerritories.contains(territoryData) && selectedTerritories.contains(territoryData.territory)
                    }
                    return filteredDataWithKeys
                }.filter { !$0.territoriesData.isEmpty }
            }
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Error retrieving territory data: \(error)")
                }
            }, receiveValue: { filteredTerritoryData in
                let sortedTerritoryData = filteredTerritoryData.sorted {
                    ($0.keys.first?.name ?? "") < ($1.keys.first?.name ?? "")
                }
                self.territoryData = sortedTerritoryData
                // Ensure selectedTerritories does not contain duplicates
                let newSelected = filteredTerritoryData.flatMap { $0.territoriesData }.filter { !self.selectedTerritories.contains($0) }
                self.selectedTerritories.append(contentsOf: newSelected)
            })
            .store(in: &cancellables)
    }
}




