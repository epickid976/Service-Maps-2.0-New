//
//  AddTerritoryViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/25/23.
//

import Foundation
import SwiftUI

// MARK: - AddVisitViewModel
@MainActor
class AddVisitViewModel: ObservableObject {
    
    // MARK: - Initializers
    init(house: House) {
        error = ""
        self.house = house
    }
    
    // MARK: - Dependencies
    @Published private var dataUploader = DataUploaderManager()
    
    // MARK: - Published Properties
    @Published var notes = ""
    
    @Published var selectedOption: Symbols = .none
    
    @Published var house: House
    
    @Published var error = ""
    
    @Published var loading = false
    
    // MARK: - Functions
    @BackgroundActor
    func addVisit() async -> Result<Void, Error> {
        await MainActor.run {
            withAnimation { loading = true }
        }
        let date = Date.now.millisecondsSince1970
        let visitObject = await Visit(id: "\(house.id)-\(date)", house: house.id, date: (date), symbol: selectedOption.forServer, notes: notes, user: StorageManager.shared.userEmail ?? "")
        return await dataUploader.addVisit(visit: visitObject)
    }
    
    @BackgroundActor
    func editVisit(visit: Visit) async -> Result<Void, Error> {
        await MainActor.run {
            withAnimation { loading = true }
        }
        let visitObject = await Visit(id: visit.id, house: house.id, date: visit.date, symbol: selectedOption.forServer, notes: notes, user: StorageManager.shared.userEmail ?? "")
        return await dataUploader.updateVisit(visit: visitObject)
    }
    
    func checkInfo() -> Bool {
        if notes.isEmpty && selectedOption == .none {
            error = NSLocalizedString("At least one field is required.", comment: "")
            return false
        } else if notes.isEmpty {
            notes = selectedOption.legend
            return true
        } else {
            return true
        }
    }
}
