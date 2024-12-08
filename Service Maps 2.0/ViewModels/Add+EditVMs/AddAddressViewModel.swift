//
//  AddAddressViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/19/24.
//

import Foundation

// MARK: - Add Address ViewModel
@MainActor
class AddAddressViewModel: ObservableObject {
    
    // MARK: - Initializers
    init(territory: Territory) {
        error = ""
        self.territory = territory
    }
    
    // MARK: - Dependencies
    @Published private var dataUploader = DataUploaderManager()
    
    // MARK: - Properties
    @Published var territory: Territory
    
    @Published var error = ""
    @Published var addressText = ""
    
    @Published var loading = false
    
    // MARK: - Functions
    @BackgroundActor
    func addAddress() async -> Result<Void, Error> {
        await MainActor.run {
            loading = true
        }
        let addressObject = await TerritoryAddress(id: territory.id + String(Date().timeIntervalSince1970 * 1000), territory: territory.id, address: addressText)
        return await dataUploader.addTerritoryAddress(territoryAddress: addressObject)
    }
    
    @BackgroundActor
    func editAddress(address: TerritoryAddress) async -> Result<Void, Error> {
        await MainActor.run {
            loading = true
        }
        let addressObject = await TerritoryAddress(id: address.id, territory: territory.id, address: addressText)
        return await dataUploader.updateTerritoryAddress(territoryAddress: addressObject)
    }
    
    func checkInfo() -> Bool {
        if addressText == "" {
            error = NSLocalizedString("Address is required.", comment: "")
            return false
        } else {
            return true
        }
    }
}
