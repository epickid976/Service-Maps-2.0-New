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
    
    @ObservedObject var databaseManager = RealmManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var dataUploaderManager = DataUploaderManager()
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    @Published var addressData: Optional<[AddressData]> = nil 
    
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    
    @Published var currentAddress: TerritoryAddressModel?
    @Published var addressToDelete: (String?,String?)
    
    @Published var presentSheet = false {
        didSet {
            if presentSheet == false {
                currentAddress = nil
            }
        }
    }
    
    @Published var progress: CGFloat = 0.0
    @Published var optionsAnimation = false
    
    @Published var syncAnimation = false
    @Published var syncAnimationprogress: CGFloat = 0.0
    
    @Published var backAnimation = false
    @Published var showAlert = false
    @Published var ifFailed = false
    @Published var loading = false
    
    func deleteAddress(address: String) async -> Result<Bool,Error> {
        return await dataUploaderManager.deleteTerritoryAddress(territoryAddress: address)
    }
    
    @Published var territory: TerritoryModel
    
    init(territory: TerritoryModel) {
        self.territory = territory
        
        getAddresses()
   }
    
    @Published var showToast = false
    @Published var showAddedToast = false
    
    func addressCell(addressData: AddressData) -> some View {
        SwipeView {
            NavigationLink(destination: HousesView(address: addressData.address)) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(addressData.address.address)")
                            .font(.headline)
                            .fontWeight(.heavy)
                            .foregroundColor(.primary)
                            .hSpacing(.leading)
                        Text("Doors: \(addressData.houseQuantity)")
                            .font(.body)
                            .lineLimit(5)
                            .foregroundColor(.primary)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.leading)
                            .hSpacing(.leading)
                    }
                    .frame(maxWidth: UIScreen.screenWidth * 0.90)
                }
                //.id(territory.id)
                .padding(10)
                .frame(minWidth: UIScreen.main.bounds.width * 0.95)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        } trailingActions: { context in
            if addressData.accessLevel == .Admin {
                SwipeAction(
                    systemImage: "trash",
                    backgroundColor: .red
                ) {
                    DispatchQueue.main.async {
                        self.addressToDelete = (addressData.address.id, addressData.address.address)
                        self.showAlert = true
                    }
                }
                .font(.title.weight(.semibold))
                .foregroundColor(.white)
            }
            
            if addressData.accessLevel == .Moderator || addressData.accessLevel == .Admin {
                SwipeAction(
                    systemImage: "pencil",
                    backgroundColor: Color.teal
                ) {
                    context.state.wrappedValue = .closed
                    self.currentAddress = addressData.address
                    self.presentSheet = true
                }
                .allowSwipeToTrigger()
                .font(.title.weight(.semibold))
                .foregroundColor(.white)
            }
        }
        .swipeActionCornerRadius(16)
        .swipeSpacing(5)
        .swipeOffsetCloseAnimation(stiffness: 1000, damping: 70)
        .swipeOffsetExpandAnimation(stiffness: 1000, damping: 70)
        .swipeOffsetTriggerAnimation(stiffness: 1000, damping: 70)
        .swipeMinimumDistance(addressData.accessLevel != .User ? 50:1000)
    }
    
    @ViewBuilder
    func largeHeader(progress: CGFloat) -> some View  {
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
                    .frame(width: UIScreen.screenSize.width, height: 350, alignment: .center)
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
            .frame(width: UIScreen.screenWidth, height: 350)
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
        }
        .frame(maxHeight: 75)
        .animation(.easeInOut(duration: 0.25), value: progress)
        .padding(.horizontal)
        .hSpacing(.center)
    }
    
    @ViewBuilder
    func alert() -> some View {
        ZStack {
                VStack {
                    Text("Delete Address: \(addressToDelete.1 ?? "0")")
                        .font(.title)
                            .fontWeight(.heavy)
                            .hSpacing(.leading)
                        .padding(.leading)
                    Text("Are you sure you want to delete the selected address?")
                        .font(.title3)
                            .fontWeight(.bold)
                            .hSpacing(.leading)
                        .padding(.leading)
                    if ifFailed {
                        Text("Error deleting address, please try again later")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                            //.vSpacing(.bottom)
                    
                    HStack {
                        if !loading {
                            CustomBackButton() {
                                withAnimation {
                                    self.showAlert = false
                                    self.ifFailed = false
                                    self.addressToDelete = (nil,nil)
                                }
                            }
                        }
                        //.padding([.top])
                        
                        CustomButton(loading: loading, title: "Delete", color: .red) {
                            withAnimation {
                                self.loading = true
                            }
                            Task {
                                if self.addressToDelete.0 != nil && self.addressToDelete.1 != nil {
                                    switch await self.deleteAddress(address: self.addressToDelete.0 ?? "") {
                                    case .success(_):
                                        withAnimation {
                                                self.synchronizationManager.startupProcess(synchronizing: true)
                                                self.getAddresses()
                                                self.loading = false
                                                self.showAlert = false
                                                self.ifFailed = false
                                                self.addressToDelete = (nil,nil)
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
extension AddressViewModel {
    func getAddresses() {
        databaseManager.getAddressData(territoryId: territory.id)
        .receive(on: DispatchQueue.main) // Update on main thread
        .sink(receiveCompletion: { completion in
          if case .failure(let error) = completion {
            // Handle errors here
            print("Error retrieving territory data: \(error)")
          }
        }, receiveValue: { addressData in
          self.addressData = addressData
        })
        .store(in: &cancellables)
    }
}
