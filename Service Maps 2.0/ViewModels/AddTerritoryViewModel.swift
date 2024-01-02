//
//  AddTerritoryViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/20/23.
//

import Foundation
import SwiftUI

@MainActor
class AddTerritoryViewModel: ObservableObject {
    
    @Published var number: Int? = nil
    
    var binding: Binding<String> {
            .init(get: {
                if let number = self.number {
                    "\(number)"
                } else {
                    ""
                }
            }, set: {
                self.number = Int($0) ?? nil
            })
        }
    
    @Published var description = ""
    @Published var previewImage: UIImage? = nil
    @Published var imageToSend: UIImage? = nil
    
    func addTerritory() {
        let newTerritory = Territory(context: DataController.shared.container.viewContext)
        newTerritory.id = UUID().uuidString
        newTerritory.territoryDescription = "1850 W 56 St Hialeah FL 33012 United States (The Middle Building)"
        newTerritory.congregation = "1260"
        newTerritory.number = Int32(1)
        
        let newTerritoryAddress = TerritoryAddress(context: DataController.shared.container.viewContext)
        newTerritoryAddress.territory = newTerritory.id
        newTerritoryAddress.id = UUID().uuidString
        newTerritoryAddress.address = "1850 W 56 St Hialeah FL 33012 United States"
        
        
        let otherTerritoryAddress = TerritoryAddress(context: DataController.shared.container.viewContext)
        otherTerritoryAddress.territory = newTerritory.id
        otherTerritoryAddress.id = UUID().uuidString
        otherTerritoryAddress.address = "1890 W 56 St Hialeah FL 33012 United States"
    
        
        do {
            try DataController.shared.container.viewContext.save()
        } catch {
            print("ERROR Saving CONTEXT")
            // Show some error here
        }
    }
}
