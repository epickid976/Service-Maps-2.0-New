//
//  AddAddressViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/19/24.
//

import Foundation

@MainActor
class AddAddressViewModel: ObservableObject {
    
    init(territory: TerritoryModel) {
        error = ""
        self.territory = territory
    }
    
    @Published private var dataUploader = DataUploaderManager()
    
    @Published var territory: TerritoryModel
    
    @Published var error = ""
    @Published var addressText = ""
    
    @Published var loading = false
    
    
    func addAddress() async -> Result<Bool, Error> {
        loading = true
        let addressObject = TerritoryAddressObject()
        addressObject.id = territory.id + String(Date().timeIntervalSince1970 * 1000)
        addressObject.address = addressText
        addressObject.territory = territory.id
        addressObject.floors = nil
        return await dataUploader.addTerritoryAddress(territoryAddress: addressObject)
    }
    
    func editAddress(address: TerritoryAddressModel) async -> Result<Bool, Error> {
        loading = true
        let addressObject = TerritoryAddressObject()
        addressObject.id = address.id
        addressObject.address = addressText
        addressObject.territory = territory.id
        addressObject.floors = nil
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
