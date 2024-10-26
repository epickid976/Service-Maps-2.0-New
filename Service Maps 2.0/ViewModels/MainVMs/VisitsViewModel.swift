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
    let latestVisitUpdatePublisher = CurrentValueSubject<Visit?, Never>(nil)
    private var cancellables = Set<AnyCancellable>()
    
    @Published var visitData: [VisitData]? = nil
    @Published var visitIdToScrollTo: String?
    @Published var house: House
    
    // UI State management
    @Published var backAnimation = false
    @Published var optionsAnimation = false
    @Published var progress: CGFloat = 0.0
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    @Published var currentVisit: Visit?
    @Published var presentSheet = false {
        didSet {
            if !presentSheet { currentVisit = nil }
        }
    }
    
    @Published var recallAdded = false
    
    @Published var visitToDelete: String?
    @Published var showAlert = false
    @Published var ifFailed = false
    @Published var loading = false
    @Published var showToast = false
    @Published var showAddedToast = false
    @Published var showRecallAddedToast = false
    @Published var syncAnimation = false
    @Published var syncAnimationprogress: CGFloat = 0.0
    @Published var search: String = "" {
        didSet { getVisits() }
    }
    
    @Published var searchActive = false
    @Published var revisitAnimation = false
    @Published var revisitAnimationprogress: CGFloat = 0.0

    // Initializer
    init(house: House, visitIdToScrollTo: String? = nil, revisitView: Bool = false) {
        self.house = house
        getVisits(visitIdToScrollTo: visitIdToScrollTo, revisitView: revisitView)
        recallAdded = GRDBManager.shared.isHouseRecall(house: house.id)
    }

    // Methods for recall and deletion
    func deleteVisit(visit: String) async -> Result<Void, Error> {
        return await dataUploaderManager.deleteVisit(visitId: visit)
    }

    func addRecall(user: String, house: String) async -> Result<Void, Error> {
        return await dataUploaderManager.addRecall(user: user, house: house)
    }

    func deleteRecall(id: Int64, user: String, house: String) async -> Result<Void, Error> {
        return await dataUploaderManager.deleteRecall(recall: Recalls(id: id, user: user, house: house))
    }
    
    func getRecallId(house: String) async -> Int64? {
        return GRDBManager.shared.findRecallId(house: house)
    }
}

@MainActor
extension VisitsViewModel {
    // Fetch and observe visit data using GRDB
    func getVisits(visitIdToScrollTo: String? = nil, revisitView: Bool = false) {
        GRDBManager.shared.getVisitData(houseId: house.id)
            .receive(on: DispatchQueue.main)  // Ensure UI updates on the main thread
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("Error retrieving visit data: \(error)")
                    self?.ifFailed = true
                }
            }, receiveValue: { [weak self] visitData in
                self?.handleVisitData(visitData, visitIdToScrollTo: visitIdToScrollTo, revisitView: revisitView)
            })
            .store(in: &cancellables)
    }

    // Process visit data and determine the latest visit
    private func handleVisitData(_ visitData: [VisitData], visitIdToScrollTo: String?, revisitView: Bool) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Sort visits by date
            let sortedData = visitData.sorted { $0.visit.date > $1.visit.date }

            // Determine the latest visit based on revisitView
            let latestVisit: Visit? = revisitView
                ? sortedData.first?.visit
                : sortedData.first { $0.visit.symbol != "nc" }?.visit ?? sortedData.first?.visit

            // Update the UI on the main thread
            DispatchQueue.main.async {
                if sortedData.isEmpty || latestVisit == nil {
                    self.latestVisitUpdatePublisher.send(nil)
                } else {
                    self.latestVisitUpdatePublisher.send(latestVisit)
                }

                self.visitData = sortedData
                self.scrollToVisit(visitIdToScrollTo)
            }
        }
    }

    // Scroll to the specified visit after data is received
    private func scrollToVisit(_ visitIdToScrollTo: String?) {
        if let visitIdToScrollTo = visitIdToScrollTo {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.visitIdToScrollTo = visitIdToScrollTo
            }
        }
    }
}
