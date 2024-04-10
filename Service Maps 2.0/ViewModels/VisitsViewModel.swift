//
//  VisitsViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/7/24.
//

import Foundation
import SwiftUI
import CoreData
import NukeUI
import Combine

@MainActor
class VisitsViewModel: ObservableObject {
    private var visits: FetchedResultList<Visit>
    
    
     init(house: House, context: NSManagedObjectContext = DataController.shared.container.viewContext) {
        self.house = house
        
         visits = FetchedResultList(context: context, sortDescriptors: [
            NSSortDescriptor(keyPath: \Visit.date, ascending: false)
           ])
         
         visits.willChange = { [weak self] in self?.objectWillChange.send() }
         
    }
    
    @Published var backAnimation = false
    @Published var optionsAnimation = false
    @Published var progress: CGFloat = 0.0
    @Published var house: House
    
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    @Published var currentVisit: Visit?
    @Published var presentSheet = false {
        didSet {
            if presentSheet == false {
                currentVisit = nil
            }
        }
    }
    
    var sortDescriptors: [NSSortDescriptor] {
        // Compute the sort descriptors based on the current sorting order
        return [NSSortDescriptor(keyPath: \Visit.date, ascending: true)]
    }
    
    func deleteVisit(house: House) {
        //TODO CONNECT TO SERVER ETC
    }
}

extension VisitsViewModel {
    var visitsList: [Visit] {
        visits.items
    }
}
