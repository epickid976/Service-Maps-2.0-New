//
//  AddressViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/17/24.
//

import Foundation
import SwiftUI
import SwipeActions
import Combine
import NukeUI
import ScalingHeaderScrollView
import Nuke

// MARK: - AddressViewModel

@MainActor
class AddressViewModel: ObservableObject {
    // MARK: - Dependencies
    
    @ObservedObject var dataStore = StorageManager.shared
       @ObservedObject var dataUploaderManager = DataUploaderManager()
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    // MARK: - Properties
     private var cancellables = Set<AnyCancellable>()
    
    // Published properties for UI
    @Published var addressData: [AddressData]? = nil
    @Published var currentAddress: TerritoryAddress?
    @Published var addressToDelete: (String?, String?) = (nil, nil)
    
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    @Published var territory: Territory
    @Published var search: String = "" {
        didSet { getAddresses() }
    }
    
    // UI State Management
    @Published var presentSheet = false {
        didSet { if !presentSheet { currentAddress = nil } }
    }
    @Published var progress: CGFloat = 0.0
    @Published var optionsAnimation = false
    @Published var syncAnimation = false
    @Published var syncAnimationprogress: CGFloat = 0.0
    @Published var backAnimation = false
    @Published var showAlert = false
    @Published var ifFailed = false
    @Published var loading = false
    @Published var territoryAddressIdToScrollTo: String? = nil
    @Published var isShowingSearch = false
    @Published var showImageViewer = false
    
     // MARK: - Initializers
    
    init(territory: Territory, territoryAddressIdToScrollTo: String? = nil) {
        self.territory = territory
        getAddresses(territoryAddressIdToScrollTo: territoryAddressIdToScrollTo)
    }
    
    // MARK: - Methods
    // Address deletion logic
    @BackgroundActor
    func deleteAddress(address: String) async -> Result<Void, Error> {
        return await dataUploaderManager.deleteTerritoryAddress(territoryAddressId: address)
    }
    
    // MARK: - UI Large Header
    //Headers
    @ViewBuilder
    func largeHeader(progress: CGFloat, mainWindowSize: CGSize) -> some View  {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                // Image Background
                LazyImage(url: URL(string: territory.getImageURL())) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: mainWindowSize.width, height: 350)
                            .clipped()
                    } else if state.isLoading {
                        ProgressView().frame(height: 350)
                    } else {
                        Image("mapImage")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: mainWindowSize.width, height: 100)
                    }
                }
                .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                .frame(height: 350)

                // Glassmorphic Header Overlay
                VStack(spacing: 0) {
                    smallHeader
                        //.padding(.vertical, 10)
                        //.padding(.horizontal)
                }
//                .frame(height: 85)
//                .frame(maxWidth: .infinity)
//                //.background(.ultraThinMaterial)
////                .overlay(
////                    RoundedRectangle(cornerRadius: 20)
////                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
////                )
//                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            }
        }
        .frame(width: mainWindowSize.width, height: 350)
        .animation(.easeInOut, value: progress)
    }
    
    // MARK: - UI Small Header
    @ViewBuilder
    var smallHeader: some View {
        HStack(spacing: 12) {
            // Number
            VStack(alignment: .leading, spacing: 2) {
                Text("№")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Text("\(territory.number)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            // Image
            if territory.getImageURL() != "" {
                if !(progress < 0.98) { // Show image only if progress is sufficient
                    LazyImage(url: URL(string: territory.getImageURL())) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        } else {
                            Color.gray.opacity(0.2)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
            // Address info
            VStack(alignment: .leading, spacing: 2) {
                Text(territory.description)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .fill(.thickMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke((progress < 0.98) ? Color.white.opacity(0.15) : Color.clear, lineWidth: 0.6)
                )
                .shadow(color: .black.opacity(0.1), radius: (progress < 0.98) ? 6 : 0, x: 0, y: 3)
                .animation(.easeInOut, value: progress)
                .cornerRadius((progress < 0.98) ? 20 : 0, corners: [.topLeft, .topRight])
                .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
        )
        //.padding(.horizontal)
    }
}

// MARK: - Extension Publishers
@MainActor
extension AddressViewModel {
    // Fetch and observe address data from GRDB
    func getAddresses(territoryAddressIdToScrollTo: String? = nil) {
        GRDBManager.shared.getAddressData(territoryId: territory.id)
            .receive(on: DispatchQueue.main)  // Ensure updates are received on the main thread
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("Error retrieving address data: \(error)")
                    self?.ifFailed = true
                }
            }, receiveValue: { [weak self] addressData in
                self?.handleAddressData(addressData, scrollTo: territoryAddressIdToScrollTo)
            })
            .store(in: &cancellables)
    }
    
    // Handle and process address data
    private func handleAddressData(_ addressData: [AddressData], scrollTo territoryAddressIdToScrollTo: String?) {
        if search.isEmpty {
            self.addressData = addressData.sorted { $0.address.address < $1.address.address }
            scrollToAddress(territoryAddressIdToScrollTo)
        } else {
            self.addressData = addressData.filter {
                $0.address.address.lowercased().contains(search.lowercased())
            }
        }
    }
    
    // Handle scrolling to a specific address after data is received
    private func scrollToAddress(_ territoryAddressIdToScrollTo: String?) {
        if let territoryAddressIdToScrollTo = territoryAddressIdToScrollTo {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.territoryAddressIdToScrollTo = territoryAddressIdToScrollTo
            }
        }
    }
}
