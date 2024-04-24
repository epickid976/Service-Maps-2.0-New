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
    init(address: TerritoryAddressModel) {
        error = ""
        self.address = address
    }
    
    @Published private var dataUploader = DataUploaderManager()
    
    @Published var address: TerritoryAddressModel
    
    @Published var error = ""
    @Published var number = ""
    
    @Published var loading = false
    
    func addHouse() async -> Result<Bool, Error> {
        withAnimation {
            loading = true
        }
        let houseObject = HouseObject()
        houseObject.number = number
        houseObject.territory_address = address.id
        houseObject.floor = nil
        return await dataUploader.addHouse(house: houseObject)
    }
    
    func editHouse(house: HouseModel) async -> Result<Bool, Error> {
        withAnimation {
            loading = true
        }
        let houseObject = HouseObject()
        houseObject.id = house.id
        houseObject.number = number
        houseObject.territory_address = address.id
        houseObject.floor = nil
        return await dataUploader.updateHouse(house: houseObject)
    }
    
    func checkInfo() -> Bool {
        if number == "" {
            error = "Number is required."
            return false
        } else {
            return true
        }
    }
}
