//
//  AddHouseViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/4/24.
//

import Foundation
import SwiftUI

// MARK: - AddHouseViewModel

@MainActor
class AddHouseViewModel: ObservableObject {
    
    // MARK: - Initializers
    
    init(address: TerritoryAddress) {
        error = ""
        self.address = address
    }
    
    // MARK: - Dependencies
    @Published private var dataUploader = DataUploaderManager()
    
    // MARK: - Properties
    @Published var address: TerritoryAddress
    
    @Published var error = ""
    @Published var number = ""
    
    @Published var loading = false
    
    // MARK: - Functions
    @BackgroundActor
    func addHouse() async -> Result<Void, Error> {
        await MainActor.run {
            withAnimation {
                loading = true
            }
        }
        let houseObject = await House(id: "\(address.address)-\(number)", territory_address: address.id, number: number)
        return await dataUploader.addHouse(house: houseObject)
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
