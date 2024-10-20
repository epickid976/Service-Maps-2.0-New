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
                Image(systemName: selectedTerritories.contains(territoryData) ? "checkmark.circle.fill" : "circle")
                    .optionalViewModifier { content in
                        if #available(iOS 17, *) {
                            content
                                .symbolEffect(.bounce, options: .speed(3.0), value: self.selectedTerritories.contains(territoryData))
                                .animation(.bouncy, value: self.selectedTerritories.contains(territoryData))
                        } else {
                            content
                                .animation(.bouncy, value: self.selectedTerritories.contains(territoryData))
                        }
                    }

                CellView(territory: territoryData.territory, houseQuantity: territoryData.housesQuantity, width: 0.8, mainWindowSize: mainWindowSize)
                    .padding(2)
            }
            .padding(.horizontal, 10)
        }
        .buttonStyle(PlainButtonStyle()) // Maintains original appearance
    }

    func toggleSelection(for territoryData: TerritoryData) {
        HapticManager.shared.trigger(.selectionChanged)
        if self.selectedTerritories.contains(territoryData) {
            if let index = self.selectedTerritories.firstIndex(of: territoryData) {
                self.selectedTerritories.remove(at: index)
                // Force view update by reassigning the array
                self.selectedTerritories = self.selectedTerritories
            }
        } else {
            self.selectedTerritories.append(territoryData)
            // Force view update by reassigning the array
            self.selectedTerritories = self.selectedTerritories
        }
    }
    
    func addToken() async -> Result<Bool, Error> {
        withAnimation {
            loading = true
        }
        let tokenObject = Token(id: "", name: name, owner: "", congregation: dataStore.congregationName ?? "", moderator: servant)
        
        var territories = [String]()
        var territoryObjects = [Territory]()
        
        selectedTerritories.forEach { territory in
            territories.append(territory.territory.id)
            territoryObjects.append(territory.territory)
        }
        if keyData != nil {
            return await dataUploader.editToken(token: keyData!.key.id, territories:  territoryObjects)
        } else {
            switch await dataUploader.createToken(newTokenForm: NewTokenForm(name: tokenObject.name, moderator: tokenObject.moderator, territories: territories.description, congregation: AuthorizationProvider.shared.congregationId ?? 0, expire: tokenObject.expire), territories: territoryObjects) {
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
                self.territoryData = territoryData
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
                            selectedTerritories.contains(territoryData.territory) // Compare Territory objects
                        }
                        return filteredDataWithKeys
                    }.filter { !$0.territoriesData.isEmpty }
                }
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Error retrieving territory data: \(error)")
                    }
                }, receiveValue: { filteredTerritoryData in
                    self.territoryData = filteredTerritoryData
                    self.selectedTerritories = filteredTerritoryData.flatMap { $0.territoriesData }
                })
                .store(in: &cancellables)
        }
}




