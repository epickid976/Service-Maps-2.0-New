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
    
    let latestCallUpdatePublisher = PassthroughSubject<PhoneCall?, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var callsData: Optional<[PhoneCallData]> = nil
    //@ObservedObject var databaseManager = RealmManager.shared
    
    init(phoneNumber: PhoneNumber, callToScrollTo: String? = nil) {
        self.phoneNumber = phoneNumber
        
        getCalls(callToScrollTo: callToScrollTo)
    }
    
    @Published var callToScrollTo: String? = nil
    
    @Published var backAnimation = false
    @Published var optionsAnimation = false
    @Published var progress: CGFloat = 0.0
    @Published var phoneNumber: PhoneNumber
    
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    @Published var currentCall: PhoneCall?
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
    
    func deleteCall(call: String) async -> Result<Void, Error> {
        return await dataUploaderManager.deletePhoneCall(phoneCallId: call)
    }
    
    @Published var search: String = "" {
        didSet {
            getCalls()
        }
    }
    
    @Published var searchActive = false
    
}

@MainActor
extension CallsViewModel {
    // Fetch and observe call data using GRDB
    func getCalls(callToScrollTo: String? = nil) {
        GRDBManager.shared.getPhoneCallData(phoneNumberId: phoneNumber.id)
            .receive(on: DispatchQueue.main)  // Ensure UI updates on the main thread
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("Error retrieving phone call data: \(error)")
                    self?.ifFailed = true
                }
            }, receiveValue: { [weak self] callData in
                self?.handleCallData(callData, callToScrollTo: callToScrollTo)
            })
            .store(in: &cancellables)
    }

    // Process call data and determine the latest call
    private func handleCallData(_ callData: [PhoneCallData], callToScrollTo: String?) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Sort calls by date
            let sortedData = callData.sorted { $0.phoneCall.date > $1.phoneCall.date }

            // Determine the latest call
            let latestCall: PhoneCall? = sortedData.first?.phoneCall

            // Update the UI on the main thread
            DispatchQueue.main.async {
                if sortedData.isEmpty || latestCall == nil {
                    self.latestCallUpdatePublisher.send(nil)
                } else {
                    self.latestCallUpdatePublisher.send(latestCall)
                }

                self.callsData = sortedData
                self.scrollToCall(callToScrollTo)
            }
        }
    }

    // Scroll to the specified call after data is received
    private func scrollToCall(_ callToScrollTo: String?) {
        if let callToScrollTo = callToScrollTo {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.callToScrollTo = callToScrollTo
            }
        }
    }
}


struct CallCell: View {
    var call: PhoneCallData
    var ipad: Bool = false
    @Environment(\.mainWindowSize) var mainWindowSize
    
    var isIpad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad && mainWindowSize.width > 400
    }

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    HStack {
                        Text(formattedDate(date: Date(timeIntervalSince1970: TimeInterval(call.phoneCall.date / 1000))))
                        //.frame(maxWidth: .infinity)
                            .font(.headline)
                            .lineLimit(3)
                            .foregroundColor(.secondaryLabel)
                            .fontWeight(.heavy)
                            .hSpacing(.leading)
                    }
                    
                }
                
                Text(call.phoneCall.notes)
                    .font(.headline)
                    .lineLimit(4)
                    .foregroundColor(.primary)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                Spacer().frame(height: 5)
                Text(call.phoneCall.user)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundColor(.secondaryLabel)
                    .fontWeight(.heavy)
                    .hSpacing(.trailing)
                
            }
            .frame(maxWidth: .infinity)
            .padding(5)
            
        }
        .padding(10)
        .frame(minWidth: ipad ? (mainWindowSize.width / 2) * 0.90 : mainWindowSize.width * 0.90)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .optionalViewModifier { content in
            if isIpad {
                content
                    .frame(maxHeight: .infinity)
            } else {
                content
            }
        }
    }
    
}
