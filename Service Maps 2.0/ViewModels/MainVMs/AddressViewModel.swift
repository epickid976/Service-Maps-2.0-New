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

@MainActor
class AddressViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    // Dependencies
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var dataUploaderManager = DataUploaderManager()
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
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
    @Published var showToast = false
    @Published var showAddedToast = false
    @Published var territoryAddressIdToScrollTo: String? = nil
    @Published var isShowingSearch = false
    @Published var showImageViewer = false
    
    // Initializer
    init(territory: Territory, territoryAddressIdToScrollTo: String? = nil) {
        self.territory = territory
        getAddresses(territoryAddressIdToScrollTo: territoryAddressIdToScrollTo)
    }
    
    // Address deletion logic
    func deleteAddress(address: String) async -> Result<Bool, Error> {
        return await dataUploaderManager.deleteTerritoryAddress(territoryAddressId: address)
    }
    
    //Headers
    @ViewBuilder
    func largeHeader(progress: CGFloat, mainWindowSize: CGSize) -> some View  {
        VStack {
            ZStack {
                VStack {
                    LazyImage(url: URL(string: territory.getImageURL())) { state in
                        if let image = state.image {
                            image.resizable().aspectRatio(contentMode: .fill).frame(width: UIScreen.screenWidth, height: 350)
                            
                            //image.opacity(1 - progress)
                            
                        } else if state.isLoading  {
                            ProgressView().progressViewStyle(.circular)
                            
                        } else if state.error != nil {
                            Image(uiImage: UIImage(named: "mapImage")!)
                                .resizable()
                                .frame(width: 100, height: 100)
                                .padding(.bottom, 125)
                        } else {
                            Image(uiImage: UIImage(named: "mapImage")!)
                                .resizable()
                                .frame(width: 100, height: 100)
                                .padding(.bottom, 125)
                        }
                    }
                    .pipeline(ImagePipeline.shared)
                    .vSpacing(.bottom)
                    .cornerRadius(10)
                }
                .frame(width: mainWindowSize.width, height: 350, alignment: .center)
                VStack {
                    smallHeader
                    
                        .padding(.vertical)
                        .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
                    
                }.frame(height: 85)
                    .background(
                        Material.ultraThickMaterial
                    )
                    .vSpacing(.bottom)
            }
            .frame(width: mainWindowSize.width, height: 350)
        }
        
        .animation(.default, value: progress)
        
    }
    
    @ViewBuilder
    var smallHeader: some View {
        HStack(spacing: 12.0) {
            HStack {
                Image(systemName: "numbersign").imageScale(.large).fontWeight(.heavy)
                    .foregroundColor(.primary).font(.title2)
                Text("\(territory.number)")
                    .font(.largeTitle)
                    .bold()
                    .fontWeight(.heavy)
            }
            
            Divider()
                .frame(maxHeight: 75)
                .padding(.horizontal, -5)
            if !(progress < 0.98) {
                LazyImage(url: URL(string: territory.getImageURL())) { state in
                    if let image = state.image {
                        image.resizable().aspectRatio(contentMode: .fill).frame(maxWidth: 75, maxHeight: 60)
                    } else if state.error != nil {
                        Image(uiImage: UIImage(named: "mapImage")!)
                            .resizable()
                            .frame(width: 75, height: 75)
                        //.padding(.bottom, 125)
                    } else {
                        ProgressView().progressViewStyle(.circular)
                    }
                }
                
                .cornerRadius(10)
                .padding(.horizontal, 2)
            }
            Text(territory.description)
                .font(.body)
                .fontWeight(.heavy)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxHeight: 75)
        .animation(.easeInOut(duration: 0.25), value: progress)
        .padding(.horizontal)
        .hSpacing(.center)
    }
}

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
