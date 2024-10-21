//
//  AddHouseViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/4/24.
//

import Foundation
import SwiftUI

@MainActor
class AddHouseViewModel: ObservableObject {
    init(address: TerritoryAddress) {
        error = ""
        self.address = address
    }
    
    @Published private var dataUploader = DataUploaderManager()
    
    @Published var address: TerritoryAddress
    
    @Published var error = ""
    @Published var number = ""
    
    @Published var loading = false
    
    func addHouse() async -> Result<Bool, Error> {
        withAnimation {
            loading = true
        }
        let houseObject = House(id: "\(address.address)-\(number)", territory_address: address.id, number: number)
        return await dataUploader.addHouse(house: houseObject)
    }
    
    func editHouse(house: House) async -> Result<Bool, Error> {
        withAnimation {
            loading = true
        }
        let houseObject = House(id: house.id, territory_address: address.id, number: number)
        return await dataUploader.updateHouse(house: houseObject)
    }
    
    func checkInfo() -> Bool {
        if number == "" {
            error = NSLocalizedString("Number is required.", comment: "")
            return false
        } else {
            return true
        }
    }
}
