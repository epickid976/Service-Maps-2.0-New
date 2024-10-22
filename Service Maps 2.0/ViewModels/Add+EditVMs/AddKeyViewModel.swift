//
//  AddKeyViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/23/24.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AddKeyViewModel: ObservableObject {
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var dataUploaderManager = DataUploaderManager()
    
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    
    private var cancellables = Set<AnyCancellable>()
    
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
    @Published var keyData: KeyData?
    @Published var name = ""
    @Published var servant = false
    
    @Published private var dataUploader = DataUploaderManager()
    
    @Published var error = ""
    
    @Published var loading = false
    
    @Published var territoryData: Optional<[TerritoryDataWithKeys]> = nil
    
    @Published var selectedTerritories = [TerritoryData]()
    @Published var syncAnimation = false
    @Published var syncAnimationprogress: CGFloat = 0.0
    
    @Published var progress: CGFloat = 0.0
    @Published var optionsAnimation = false
    
    
    
    @ViewBuilder
    func showSelectableTerritoriesList(dataWithKeys: TerritoryDataWithKeys, mainWindowSize: CGSize) -> some View {
        LazyVStack {
            if !dataWithKeys.keys.isEmpty {
                Text(self.processData(dataWithKeys: dataWithKeys))
                    .font(.title2)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                    .padding(5)
                    .padding(.horizontal, 10)
            } else {
                Spacer()
                    .frame(height: 20)
            }
        }
        
        ForEach(dataWithKeys.territoriesData, id: \.territory.id) { territoryData in
            self.SelectableTerritoryItem(territoryData: territoryData, mainWindowSize: mainWindowSize).id(territoryData.territory.id)
        }
    }
    
    @ViewBuilder
    func SelectableTerritoryItem(territoryData: TerritoryData, mainWindowSize: CGSize) -> some View {
        Button(action: {
            self.toggleSelection(for: territoryData)
        }) {
            HStack {
                Image(systemName: isSelected(territoryData: territoryData) ? "checkmark.circle.fill" : "circle")
                    .optionalViewModifier { content in
                        if #available(iOS 17, *) {
                            content
                                .symbolEffect(.bounce, options: .speed(3.0), value: self.isSelected(territoryData: territoryData))
                                .animation(.bouncy, value: self.isSelected(territoryData: territoryData))
                        } else {
                            content
                                .animation(.bouncy, value: self.isSelected(territoryData: territoryData))
                        }
                    }

                CellView(territory: territoryData.territory, houseQuantity: territoryData.housesQuantity, width: 0.8, mainWindowSize: mainWindowSize)
                    .padding(2)
            }
            .padding(.horizontal, 10)
        }.id(territoryData.territory.id)
        .buttonStyle(PlainButtonStyle()) // Maintains original appearance
    }
                       
    private func isSelected(territoryData: TerritoryData) -> Bool {
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
    
    func addToken() async -> Result<Bool, Error> {
        withAnimation {
            loading = true
        }
        
        // Create token object
        let tokenObject = Token(id: "", name: name, owner: "", congregation: dataStore.congregationName ?? "", moderator: servant)
        
        // Collect territories and avoid duplicates using a Set
        var territoriesSet = Set<String>()
        var territoryObjectsSet = Set<Territory>()
        
        // Populate the territories from selectedTerritories
        selectedTerritories.forEach { territory in
            territoriesSet.insert(territory.territory.id)  // Use Set to avoid duplicates
            territoryObjectsSet.insert(territory.territory)
        }
        if let keyData = keyData {
            // Editing existing token
            return await dataUploader.editToken(token: keyData.key.id, territories: Array(territoryObjectsSet)) // Convert set back to array
        } else {
            // Creating a new token
            let newTokenForm = NewTokenForm(
                name: tokenObject.name,
                moderator: tokenObject.moderator,
                territories: Array(territoriesSet).description,  // Convert set to array and description
                congregation: AuthorizationProvider.shared.congregationId ?? 0,
                expire: tokenObject.expire
            )
            
            switch await dataUploader.createToken(newTokenForm: newTokenForm, territories: Array(territoryObjectsSet)) {
            case .success(_):
                return Result.success(true)
            case .failure(let error):
                return Result.failure(error)
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

@MainActor
extension AddKeyViewModel {
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




