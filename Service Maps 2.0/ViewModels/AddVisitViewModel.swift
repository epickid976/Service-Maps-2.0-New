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
    
    @Published var notes = ""
    
    @Published var selectedOption: Symbols = .NC
    @Published var selectedDate: Date = Date.now
}
