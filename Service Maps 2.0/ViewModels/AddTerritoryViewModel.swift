//
//  AddTerritoryViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/20/23.
//

import Foundation
import SwiftUI
import CoreData

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
       
    }
}
