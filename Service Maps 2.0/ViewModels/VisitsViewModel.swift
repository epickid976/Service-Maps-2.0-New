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
import SwipeActions

@MainActor
class VisitsViewModel: ObservableObject {
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var dataUploaderManager = DataUploaderManager()
    let latestVisitUpdatePublisher = PassthroughSubject<VisitModel, Never>()
    var cancellables = Set<AnyCancellable>()
    
    @Published var visitData: Optional<[VisitData]> = nil {
        didSet {
            print("VISIT DATA \(visitData)")
        }
    }
    //@ObservedObject var databaseManager = RealmManager.shared
    
    init(house: HouseModel, visitIdToScrollTo: String? = nil) {
        self.house = house
        
        getVisits(visitIdToScrollTo: visitIdToScrollTo)
    }
    
    @Published var visitIdToScrollTo: String?
    
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
    
    @Published var visitToDelete: String?
    
    @Published var showAlert = false
    @Published var ifFailed = false
    @Published var loading = false
    
    @Published var showToast = false
    @Published var showAddedToast = false
    
    @Published var syncAnimation = false
    @Published var syncAnimationprogress: CGFloat = 0.0
    
    @Published var search: String = "" {
        didSet {
            getVisits()
        }
    }
    
    @Published var searchActive = false
    
    func deleteVisit(visit: String) async -> Result<Bool, Error> {
        return await dataUploaderManager.deleteVisit(visit: visit)
    }
    
    
    
    
}

@MainActor
extension VisitsViewModel {
    func getVisits(visitIdToScrollTo: String? = nil) {
        RealmManager.shared.getVisitData(houseId: house.id)
            .subscribe(on: DispatchQueue.main)
            .receive(on: DispatchQueue.main) // Update on main thread
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Handle errors here
                    print("Error retrieving visit data: \(error)")
                }
            }, receiveValue: { visitData in
                    DispatchQueue.main.async {
                        let data = visitData.sorted { $0.visit.date > $1.visit.date }
                       
                        if let  latestVisit = visitData.sorted(by: { $0.visit.date > $1.visit.date }).first?.visit {
                            self.latestVisitUpdatePublisher.send(latestVisit)
                        }
                        
                        self.visitData = data
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if let visitIdToScrollTo = visitIdToScrollTo {
                                self.visitIdToScrollTo = visitIdToScrollTo
                            }
                        }
                    }
            })
            .store(in: &cancellables)
    }
}
