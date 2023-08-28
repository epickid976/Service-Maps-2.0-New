//
//  TerritoryViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/14/23.
//

import Foundation
import SwiftUI
import CoreData

class TerritoryViewModel: ObservableObject {
    
    @Published var isAscending = true // Boolean state variable to track the sorting order
    @Published var currentTerritory: Territory?
    @Published var presentSheet = false
    
    var sortDescriptors: [NSSortDescriptor] {
        // Compute the sort descriptors based on the current sorting order
        return [NSSortDescriptor(keyPath: \Territory.number, ascending: isAscending)]
    }
}
