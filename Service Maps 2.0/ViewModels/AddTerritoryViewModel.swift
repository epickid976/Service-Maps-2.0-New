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
    @Published var previewImage: String? = nil
    @Published var imageToSend: UIImage? = nil
    
    func addTerritory() {
        let newTerritory = Territory(context: DataController.shared.container.viewContext)
        newTerritory.id = UUID().uuidString
        newTerritory.territoryDescription = "1850 W 56 St Hialeah FL 33012 United States (The Middle Building)"
        newTerritory.congregation = "1260"
        newTerritory.number = Int32(1)

        DataController.shared.save()
    }
}
