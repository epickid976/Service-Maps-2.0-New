//
//  AddressViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/17/24.
//

import Foundation
import SwiftUI
import SwipeActions
import Combine
import NukeUI
import ScalingHeaderScrollView
import Nuke

// MARK: - AddressViewModel

@MainActor
class AddressViewModel: ObservableObject {
    // MARK: - Dependencies
    
    @ObservedObject var dataStore = StorageManager.shared
       @ObservedObject var dataUploaderManager = DataUploaderManager()
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    // MARK: - Properties
     private var cancellables = Set<AnyCancellable>()
    
    // Published properties for UI
    @Published var addressData: [AddressData]? = nil
    @Published var currentAddress: TerritoryAddress?
    @Published var addressToDelete: (String?, String?) = (nil, nil)
    
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    @Published var territory: Territory
    @Published var search: String = "" {
        didSet { getAddresses() }
    }
    
    // UI State Management
    @Published var presentSheet = false {
        didSet { if !presentSheet { currentAddress = nil } }
    }
    @Published var progress: CGFloat = 0.0
    @Published var optionsAnimation = false
    @Published var syncAnimation = false
    @Published var syncAnimationprogress: CGFloat = 0.0
    @Published var backAnimation = false
    @Published var showAlert = false
    @Published var ifFailed = false
    @Published var loading = false
    @Published var territoryAddressIdToScrollTo: String? = nil
    @Published var isShowingSearch = false
    @Published var showImageViewer = false
    
     // MARK: - Initializers
    
    init(territory: Territory, territoryAddressIdToScrollTo: String? = nil) {
        self.territory = territory
        getAddresses(territoryAddressIdToScrollTo: territoryAddressIdToScrollTo)
    }
    
    // MARK: - Methods
    // Address deletion logic
    @BackgroundActor
    func deleteAddress(address: String) async -> Result<Void, Error> {
        return await dataUploaderManager.deleteTerritoryAddress(territoryAddressId: address)
    }
    
    

    var headerInfo: TerritoryHeaderInfo {
        TerritoryHeaderInfo(
            number: Int(territory.number),
            description: territory.description,
            imageURL: territory.getImageURL()
        )
    }
}

// MARK: - Extension Publishers
@MainActor
extension AddressViewModel {
    // Fetch and observe address data from GRDB
    func getAddresses(territoryAddressIdToScrollTo: String? = nil) {
        GRDBManager.shared.getAddressData(territoryId: territory.id)
            .receive(on: DispatchQueue.main)  // Ensure updates are received on the main thread
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("Error retrieving address data: \(error)")
                    self?.ifFailed = true
                }
            }, receiveValue: { [weak self] addressData in
                self?.handleAddressData(addressData, scrollTo: territoryAddressIdToScrollTo)
            })
            .store(in: &cancellables)
    }
    
    // Handle and process address data
    private func handleAddressData(_ addressData: [AddressData], scrollTo territoryAddressIdToScrollTo: String?) {
        if search.isEmpty {
            self.addressData = addressData.sorted { $0.address.address < $1.address.address }
            scrollToAddress(territoryAddressIdToScrollTo)
        } else {
            self.addressData = addressData.filter {
                $0.address.address.lowercased().contains(search.lowercased())
            }
        }
    }
    
    // Handle scrolling to a specific address after data is received
    private func scrollToAddress(_ territoryAddressIdToScrollTo: String?) {
        if let territoryAddressIdToScrollTo = territoryAddressIdToScrollTo {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.territoryAddressIdToScrollTo = territoryAddressIdToScrollTo
            }
        }
    }
}

struct TerritoryHeaderInfo {
    let number: Int
    let description: String
    let imageURL: String
}
