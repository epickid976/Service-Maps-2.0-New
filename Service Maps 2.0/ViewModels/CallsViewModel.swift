//
//  CallsViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 5/1/24.
//

import Foundation
import SwiftUI
import Nuke
import AlertKit
import Combine
import SwipeActions

@MainActor
class CallsViewModel: ObservableObject {
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var dataUploaderManager = DataUploaderManager()
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var callsData: Optional<[PhoneCallData]> = nil
    //@ObservedObject var databaseManager = RealmManager.shared
    
    init(phoneNumber: PhoneNumberModel) {
        self.phoneNumber = phoneNumber
        
        getCalls()
    }
    
    @Published var backAnimation = false
    @Published var optionsAnimation = false
    @Published var progress: CGFloat = 0.0
    @Published var phoneNumber: PhoneNumberModel
    
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    @Published var currentCall: PhoneCallModel?
    @Published var presentSheet = false {
        didSet {
            if presentSheet == false {
                currentCall = nil
            }
        }
    }
    
    @Published var callToDelete: String?
    
    @Published var showAlert = false
    @Published var ifFailed = false
    @Published var loading = false
    
    @Published var showToast = false
    @Published var showAddedToast = false
    
    @Published var syncAnimation = false
    @Published var syncAnimationprogress: CGFloat = 0.0
    
    func deleteCall(call: String) async -> Result<Bool, Error> {
        return await dataUploaderManager.deleteCall(call: call)
    }
    
    @ViewBuilder
    func callCellView(callData: PhoneCallData) -> some View {
        SwipeView {
            CallCell(call: callData)
                .padding(.bottom, 2)
        } trailingActions: { context in
            if callData.accessLevel == .Admin {
                SwipeAction(
                    systemImage: "trash",
                    backgroundColor: .red
                ) {
                    DispatchQueue.main.async {
                        self.callToDelete = callData.phoneCall.id
                        self.showAlert = true
                    }
                }
                .font(.title.weight(.semibold))
                .foregroundColor(.white)
                
                
            }
            
            if callData.accessLevel == .Moderator || callData.accessLevel == .Admin {
                SwipeAction(
                    systemImage: "pencil",
                    backgroundColor: Color.teal
                ) {
                    self.currentCall = callData.phoneCall
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
        .swipeMinimumDistance(callData.accessLevel != .User ? 25:1000)
        
    }
    
    @ViewBuilder
    func alert() -> some View {
        ZStack {
            VStack {
                Text("Delete Call")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                    .padding(.leading)
                Text("Are you sure you want to delete the selected call?")
                    .font(.headline)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                    .padding(.leading)
                if ifFailed {
                    Text("Error deleting call, please try again later")
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                //.vSpacing(.bottom)
                
                HStack {
                    if !loading {
                        CustomBackButton() {
                            withAnimation {
                                self.showAlert = false
                                self.callToDelete = nil
                            }
                        }
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: loading, title: "Delete", color: .red) {
                        withAnimation {
                            self.loading = true
                        }
                        Task {
                            if self.callToDelete != nil{
                                switch await self.deleteCall(call: self.callToDelete!) {
                                case .success(_):
                                    withAnimation {
                                        self.synchronizationManager.startupProcess(synchronizing: true)
                                        self.getCalls()
                                        self.loading = false
                                        self.showAlert = false
                                        self.ifFailed = false
                                        self.callToDelete = nil
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

@MainActor
extension CallsViewModel {
    func getCalls() {
        RealmManager.shared.getPhoneCallData(phoneNumberId: phoneNumber.id)
            .receive(on: DispatchQueue.main) // Update on main thread
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Handle errors here
                    print("Error retrieving territory data: \(error)")
                }
            }, receiveValue: { callData in
                DispatchQueue.main.async {
                    self.callsData = callData.sorted { $0.phoneCall.date > $1.phoneCall.date}
                }
            })
            .store(in: &cancellables)
    }
}


struct CallCell: View {
    var call: PhoneCallData
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    HStack {
                        Text(formattedDate(date: Date(timeIntervalSince1970: TimeInterval(call.phoneCall.date / 1000))))
                        //.frame(maxWidth: .infinity)
                            .font(.title3)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                            .fontWeight(.heavy)
                            .hSpacing(.leading)
                    }.frame(maxWidth: UIScreen.screenWidth * 0.95, maxHeight: 100)
                    
                }
                
                Text(call.phoneCall.notes)
                    .font(.headline)
                    .lineLimit(4)
                    .foregroundColor(.primary)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                
                Text(call.phoneCall.user)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                    .fontWeight(.heavy)
                    .hSpacing(.trailing)
                
            }
            .frame(maxWidth: .infinity)
            
        }
        .padding(10)
        .frame(minWidth: UIScreen.main.bounds.width * 0.95)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
}
