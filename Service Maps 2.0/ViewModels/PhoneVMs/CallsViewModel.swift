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
    
    // MARK: - Dependencies
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var dataUploaderManager = DataUploaderManager()
    
    
    // MARK: - Initializers
        init(phoneNumber: PhoneNumber, callToScrollTo: String? = nil) {
            self.phoneNumber = phoneNumber
            
            getCalls(callToScrollTo: callToScrollTo)
        }
    
    // MARK: - Published Properties
    let latestCallUpdatePublisher = PassthroughSubject<PhoneCall?, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Properties
    @Published var callsData: Optional<[PhoneCallData]> = nil
    
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
    
    @Published var search: String = "" {
        didSet {
            getCalls()
        }
    }
    
    @Published var searchActive = false
    
    // MARK: - Methods
    
    func deleteCall(call: String) async -> Result<Void, Error> {
        return await dataUploaderManager.deletePhoneCall(phoneCallId: call)
    }
}

// MARK: - Extensions + Publishers
@MainActor
extension CallsViewModel {
    
    // MARK: - Get Calls
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

    // MARK: - Scroll to Call
    // Scroll to the specified call after data is received
    private func scrollToCall(_ callToScrollTo: String?) {
        if let callToScrollTo = callToScrollTo {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.callToScrollTo = callToScrollTo
            }
        }
    }
}

// MARK: - CallCell

struct CallCell: View {
    var call: PhoneCallData
    var ipad: Bool = false
    @Environment(\.mainWindowSize) var mainWindowSize

    private var isIpad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad && mainWindowSize.width > 400
    }

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                // Date row
                Text(
                    formattedDate(
                        date: Date(
                            timeIntervalSince1970: TimeInterval(call.phoneCall.date / 1_000)
                        )
                    )
                )
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundColor(.secondary)
                .lineLimit(2)

                // Notes
                Text(call.phoneCall.notes)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(4)

                // User
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(call.phoneCall.user)
                            .font(.subheadline)
                            .fontWeight(.heavy)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .frame(
            minWidth: ipad
                ? (mainWindowSize.width / 2) * 0.90
                : mainWindowSize.width * 0.90
        )
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.6)
                )
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .optionalViewModifier { content in
            if isIpad {
                content.frame(maxHeight: .infinity)
            } else {
                content
            }
        }
    }
}
