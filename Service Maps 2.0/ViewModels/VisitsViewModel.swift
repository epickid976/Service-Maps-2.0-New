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
    
    @Published var visits = [VisitModel]() {
        didSet {
            visits.sort(by: { $0.date > $1.date })
        }
    }
    //@ObservedObject var databaseManager = RealmManager.shared
    
     init(house: HouseModel) {
        self.house = house
        
         //visits = databaseManager.visitsFlow
    }
    
    @Published var backAnimation = false
    @Published var optionsAnimation = false
    @Published var progress: CGFloat = 0.0
    @Published var house: HouseModel
    
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    @Published var currentVisit: VisitModel?
    @Published var presentSheet = false {
        didSet {
            if presentSheet == false {
                currentVisit = nil
            }
        }
    }
    
    func deleteVisit(house: House) {
        //TODO CONNECT TO SERVER ETC
    }
}
