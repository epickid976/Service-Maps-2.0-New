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
    
    func deleteVisit(visit: String) async -> Result<Bool, Error> {
        return await dataUploaderManager.deleteVisit(visit: visit)
    }
    
    func visitCellView(visitData: VisitData) -> some View {
            SwipeView {
                VisitCell(visit: visitData)
                        .padding(.bottom, 2)
            } trailingActions: { context in
                if visitData.accessLevel == .Admin {
                    SwipeAction(
                        systemImage: "trash",
                        backgroundColor: .red
                    ) {
                        DispatchQueue.main.async {
                            self.visitToDelete = visitData.visit.id
                            self.showAlert = true
                        }
                    }
                    .font(.title.weight(.semibold))
                    .foregroundColor(.white)
                    
                    
                    }
                
                if visitData.accessLevel == .Moderator || visitData.accessLevel == .Admin {
                    SwipeAction(
                        systemImage: "pencil",
                        backgroundColor: Color.teal
                    ) {
                        self.currentVisit = visitData.visit
                        context.state.wrappedValue = .closed
                       
                        self.presentSheet = true
                    }
                    .allowSwipeToTrigger()
                    .font(.title.weight(.semibold))
                    .foregroundColor(.white)
                }
            }
            .swipeActionCornerRadius(16)
            .swipeSpacing(5)
            .swipeOffsetCloseAnimation(stiffness: 500, damping: 100)
            .swipeOffsetExpandAnimation(stiffness: 500, damping: 100)
            .swipeOffsetTriggerAnimation(stiffness: 500, damping: 100)
            .swipeMinimumDistance(visitData.accessLevel != .User ? 25:1000)
        
    }
    
    @ViewBuilder
    func alert() -> some View {
        ZStack {
                VStack {
                    Text("Delete Visit")
                        .font(.title)
                            .fontWeight(.heavy)
                            .hSpacing(.leading)
                        .padding(.leading)
                    Text("Are you sure you want to delete the selected house?")
                        .font(.title3)
                            .fontWeight(.bold)
                            .hSpacing(.leading)
                        .padding(.leading)
                    if ifFailed {
                        Text("Error deleting house, please try again later")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                            //.vSpacing(.bottom)
                    
                    HStack {
                        if !loading {
                            CustomBackButton() {
                                withAnimation {
                                    self.showAlert = false
                                    self.visitToDelete = nil
                                }
                            }
                        }
                        //.padding([.top])
                        
                        CustomButton(loading: loading, title: "Delete", color: .red) {
                            withAnimation {
                                self.loading = true
                            }
                            Task {
                                if self.visitToDelete != nil{
                                    switch await self.deleteVisit(visit: self.visitToDelete ?? "") {
                                    case .success(_):
                                        withAnimation {
                                            self.synchronizationManager.startupProcess(synchronizing: true)
                                            self.getVisits()
                                            self.loading = false
                                            self.showAlert = false
                                            self.ifFailed = false
                                            self.visitToDelete = nil
                                            self.showToast = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                self.showToast = false
                                            }
                                        }
                                    case .failure(_):
                                        withAnimation {
                                            self.loading = false
                                            self.ifFailed = true
                                        }
                                    }
                                }
                            }
                            
                        }
                    }
                    .padding([.horizontal, .bottom])
                    //.vSpacing(.bottom)
                    
                }
                .ignoresSafeArea(.keyboard)
            
        }.ignoresSafeArea(.keyboard)
    }
}

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
              self.visitData = visitData
            })
            .store(in: &cancellables)
    }
}
