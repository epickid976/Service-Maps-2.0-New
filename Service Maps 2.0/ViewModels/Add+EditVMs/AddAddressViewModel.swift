//
//  AddAddressViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/19/24.
//

import Foundation

@MainActor
class AddAddressViewModel: ObservableObject {
    
    init(territory: Territory) {
        error = ""
        self.territory = territory
    }
    
    @Published private var dataUploader = DataUploaderManager()
    
    @Published var territory: Territory
    
    @Published var error = ""
    @Published var addressText = ""
    
    @Published var loading = false
    
    
    func addAddress() async -> Result<Void, Error> {
        loading = true
        let addressObject = TerritoryAddress(id: territory.id + String(Date().timeIntervalSince1970 * 1000), territory: territory.id, address: addressText)
        return await dataUploader.addTerritoryAddress(territoryAddress: addressObject)
    }
    
    func editAddress(address: TerritoryAddress) async -> Result<Void, Error> {
        loading = true
        let addressObject = TerritoryAddress(id: address.id, territory: territory.id, address: addressText)
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
