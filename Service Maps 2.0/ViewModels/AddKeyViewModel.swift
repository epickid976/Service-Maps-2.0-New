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
    
    init() {
        error = ""
        getTerritories()
    }
    
    @Published var name = ""
    @Published var servant = false
    
    @Published private var dataUploader = DataUploaderManager()
    
    @Published var error = ""
    
    @Published var loading = false
    
    @Published var territoryData: Optional<[TerritoryDataWithKeys]> = nil
    
    @Published var selectedTerritories = [TerritoryData]() {
        didSet {
            print(selectedTerritories)
        }
    }
    @Published var syncAnimation = false
    @Published var syncAnimationprogress: CGFloat = 0.0
    
    @Published var progress: CGFloat = 0.0
    @Published var optionsAnimation = false
    
    
    
    @ViewBuilder
    func showSelectableTerritoriesList(dataWithKeys: TerritoryDataWithKeys) -> some View {
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
            self.SelectableTerritoryItem(territoryData: territoryData)
        }
    }
    
    @ViewBuilder
    func SelectableTerritoryItem(territoryData: TerritoryData) -> some View {
        
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
                .onTapGesture {
                    if self.selectedTerritories.contains(territoryData) {
                        if let index = self.selectedTerritories.firstIndex(of: territoryData) {
                            self.selectedTerritories.remove(at: index)
                        }
                    } else {
                        self.selectedTerritories.append(territoryData)
                    }
                }
            CellView(territory: territoryData.territory, houseQuantity: territoryData.housesQuantity, width: 0.8)
                .padding(2)
                .onTapGesture {
                    if self.selectedTerritories.contains(territoryData) {
                        if let index = self.selectedTerritories.firstIndex(of: territoryData) {
                            self.selectedTerritories.remove(at: index)
                        }
                    } else {
                        self.selectedTerritories.append(territoryData)
                    }
                }
        }
        .padding(.horizontal, 10)
        
    }
    func addToken() async -> Result<Bool, Error> {
        withAnimation {
            loading = true
        }
        let tokenObject = TokenObject()
        tokenObject.congregation = dataStore.congregationName ?? ""
        tokenObject.moderator = servant
        tokenObject.name = name
        tokenObject.user = nil
        tokenObject.expire = nil
        tokenObject.id = ""
        tokenObject.owner = ""
        
        var territories = [String]()
        var territoryObjects = [TerritoryModel]()
        
        selectedTerritories.forEach { territory in
            territories.append(territory.territory.id)
            territoryObjects.append(territory.territory)
        }
        
        switch await dataUploader.createToken(newTokenForm: NewTokenForm(name: tokenObject.name, moderator: tokenObject.moderator, territories: territories.description, congregation: AuthorizationProvider.shared.congregationId ?? 0, expire: tokenObject.expire), territories: StructToModel().convertTerritoryStructsToEntities(structs: territoryObjects)) {
        case .success(let token):
            return Result.success(true)
        case .failure(let error):
            return Result.failure(error)
        }
    }
    
    func checkInfo() -> Bool {
        if name == "" || selectedTerritories.isEmpty {
            error = "Please fill out all the required fields."
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
        RealmManager.shared.getTerritoryData()
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
}




