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
    
    func addHouse(number: Int) {
        
    }
}
