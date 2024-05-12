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
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var visitData: Optional<[VisitData]> = nil
    //@ObservedObject var databaseManager = RealmManager.shared
    
    init(house: HouseModel) {
        self.house = house
        
        getVisits()
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
    
    func deleteVisit(visit: String) async -> Result<Bool, Error> {
        return await dataUploaderManager.deleteVisit(visit: visit)
    }
    
    
    
    
}

@MainActor
extension VisitsViewModel {
    func getVisits() {
        RealmManager.shared.getVisitData(houseId: house.id)
            .receive(on: DispatchQueue.main) // Update on main thread
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Handle errors here
                    print("Error retrieving territory data: \(error)")
                }
            }, receiveValue: { visitData in
                if self.search.isEmpty {
                    DispatchQueue.main.async {
                        self.visitData = visitData
                    }
                } else {
                    DispatchQueue.main.async {
                        self.visitData = visitData.filter { visitData in
                            visitData.visit.notes.lowercased().contains(self.search.lowercased()) ||
                            visitData.visit.user.lowercased().contains(self.search.lowercased())
                        }
                    }
                }
            })
            .store(in: &cancellables)
    }
}
