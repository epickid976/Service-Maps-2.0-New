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
    
    let latestCallUpdatePublisher = PassthroughSubject<PhoneCall, Never>()
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
    
    func deleteCall(call: String) async -> Result<Bool, Error> {
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
    func getCalls(callToScrollTo: String? = nil) {
        GRDBManager.shared.getPhoneCallData(phoneNumberId: phoneNumber.id)
            .subscribe(on: DispatchQueue.main)
            .receive(on: DispatchQueue.main) // Update on main thread
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Handle errors here
                    print("Error retrieving territory data: \(error)")
                }
            }, receiveValue: { callData in
                DispatchQueue.main.async {
                    self.callsData = callData.sorted { $0.phoneCall.date > $1.phoneCall.date}
                    
                    if let latestCall = callData.sorted(by: { $0.phoneCall.date > $1.phoneCall.date }).first?.phoneCall {
                        self.latestCallUpdatePublisher.send(latestCall)
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let callToScrollTo = callToScrollTo {
                            self.callToScrollTo = callToScrollTo
                        }
                    }
                }
                
            })
            .store(in: &cancellables)
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
