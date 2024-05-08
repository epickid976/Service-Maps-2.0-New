//
//  PhoneScreenViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/30/24.
//

import Foundation
import SwiftUI
import Nuke
import AlertKit
import Combine
import SwipeActions

@MainActor
class PhoneScreenViewModel: ObservableObject {
    
    init() {
        getTeritories()
    }
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var dataUploaderManager = DataUploaderManager()
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var phoneData: Optional<[PhoneData]> = nil
    
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    // Boolean state variable to track the sorting order
    @Published var currentTerritory: PhoneTerritoryModel?
    @Published var presentSheet = false {
        didSet {
            if presentSheet == false {
                currentTerritory = nil
            }
        }
    }
    
    @Published var progress: CGFloat = 0.0
    @Published var optionsAnimation = false
    @Published var syncAnimation = false
    @Published var syncAnimationprogress: CGFloat = 0.0
    
    @Published var restartAnimation = false
    @Published var animationProgress: Bool = false {
        didSet {
            print(animationProgress)
        }
    }
    
    @Published var showAlert = false
    @Published var ifFailed = false
    @Published var loading = false
    @Published var territoryToDelete: (String?,String?)
    
    @Published var showToast = false
    @Published var showAddedToast = false
    
    func deleteTerritory(territory: String) async -> Result<Bool, Error> {
        return await dataUploaderManager.deleteTerritory(phoneTerritory: territory)
    }
    
    @ViewBuilder
    func territoryCell(phoneData: PhoneData) -> some View {
        LazyVStack {
        SwipeView {
            NavigationLink(destination: PhoneNumbersView(territory: phoneData.territory)) {
                PhoneTerritoryCellView(territory: phoneData.territory, numbers: phoneData.numbersQuantity)
                    .padding(.bottom, 2)
            }
        } trailingActions: { context in
            if self.isAdmin {
                SwipeAction(
                    systemImage: "trash",
                    backgroundColor: .red
                ) {
                    DispatchQueue.main.async {
                        self.territoryToDelete = (String(phoneData.territory.id), String(phoneData.territory.number))
                        self.showAlert = true
                    }
                }
                .font(.title.weight(.semibold))
                .foregroundColor(.white)
                
                SwipeAction(
                    systemImage: "pencil",
                    backgroundColor: Color.teal
                ) {
                    context.state.wrappedValue = .closed
                    self.currentTerritory = phoneData.territory
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
        .swipeMinimumDistance(isAdmin ? 25:1000)
        }.padding(.horizontal, 15)
    }
    
    @ViewBuilder
    func alert() -> some View {
        ZStack {
            VStack {
                Text("Delete Territory \(territoryToDelete.1 ?? "0")")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                    .padding(.leading)
                Text("Are you sure you want to delete the selected territory?")
                    .font(.headline)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                    .padding(.leading)
                if ifFailed {
                    Text("Error deleting territory, please try again later")
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                //.vSpacing(.bottom)
                
                HStack {
                    if !loading {
                        CustomBackButton() {
                            withAnimation {
                                self.showAlert = false
                                self.territoryToDelete = (nil,nil)
                            }
                        }
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: loading, title: "Delete", color: .red) {
                        withAnimation {
                            self.loading = true
                        }
                        Task {
                            if self.territoryToDelete.0 != nil && self.territoryToDelete.1 != nil {
                                switch await self.deleteTerritory(territory: self.territoryToDelete.0 ?? "") {
                                case .success(_):
                                    withAnimation {
                                        withAnimation {
                                            self.loading = false
                                        }
                                        self.showAlert = false
                                        self.territoryToDelete = (nil,nil)
                                        self.showToast = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                            self.showToast = false
                                        }
                                    }
                                case .failure(_):
                                    withAnimation {
                                        self.loading = false
                                    }
                                    self.ifFailed = true
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

@MainActor
extension PhoneScreenViewModel {
    func getTeritories() {
        RealmManager.shared.getPhoneData()
            .receive(on: DispatchQueue.main) // Update on main thread
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Handle errors here
                    print("Error retrieving territory data: \(error)")
                }
            }, receiveValue: { phoneData in
                DispatchQueue.main.async {
                    self.phoneData = phoneData
                }
            })
            .store(in: &cancellables)
    }
}
