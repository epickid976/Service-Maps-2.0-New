//
//  AddTerritoryViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/25/23.
//

import Foundation
import SwiftUI

@MainActor
class AddVisitViewModel: ObservableObject {
    
    init(house: HouseModel) {
        error = ""
        self.house = house
    }
    
    @Published var notes = ""
    
    @Published var selectedOption: Symbols = .none
    
    @Published private var dataUploader = DataUploaderManager()
    
    @Published var house: HouseModel
    
    @Published var error = ""
    
    @Published var loading = false
    
    @MainActor
    func addVisit() async -> Result<Bool, Error> {
        withAnimation {
            loading = true
        }
        let visitObject = VisitObject()
        visitObject.id = "\(house.id)-\(Date.now.millisecondsSince1970)"
        visitObject.house = house.id
        visitObject.date = (Date.now.millisecondsSince1970)
        visitObject.notes = notes
        visitObject.user = StorageManager.shared.userName ?? ""
        visitObject.symbol = selectedOption.forServer
        return await dataUploader.addVisit(visit: visitObject)
    }
    
    func editVisit(visit: VisitModel) async -> Result<Bool, Error> {
        withAnimation {
            loading = true
        }
        let visitObject = VisitObject()
        visitObject.id = visit.id
        visitObject.house = house.id
        visitObject.date = visit.date
        visitObject.notes = notes
        visitObject.symbol = selectedOption.forServer
        visitObject.user = StorageManager.shared.userName ?? ""
        return await dataUploader.updateVisit(visit: visitObject)
    }
    
    func checkInfo() -> Bool {
        if selectedOption == .none{
            error = "Notes and Symbol are required."
            return false
        } else {
            return true
        }
    }
}
