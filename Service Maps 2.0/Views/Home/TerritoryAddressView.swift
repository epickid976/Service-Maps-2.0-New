//
//  TerritoryAddressView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/2/23.
//

import SwiftUI
import NukeUI
import NavigationTransitions
import RealmSwift
import ScalingHeaderScrollView
import SwipeActions
import Lottie
import PopupView
import AlertKit
import MijickPopupView

struct TerritoryAddressView: View {
    var territory: TerritoryModel
    
    @StateObject var viewModel: AddressViewModel
    init(territory: TerritoryModel) {
        self.territory = territory
        
        let initialViewModel = AddressViewModel(territory: territory)
        _viewModel = StateObject(wrappedValue: initialViewModel)
    }
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    
    let alertViewDeleted = AlertAppleMusic17View(title: "Address Deleted", subtitle: nil, icon: .custom(UIImage(systemName: "trash")!)) 
    let alertViewAdded = AlertAppleMusic17View(title: "Address Added", subtitle: nil, icon: .done)
    
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    let minimumOffset: CGFloat = 40
    
    @Environment(\.mainWindowSize) var mainWindowSize
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ScalingHeaderScrollView {
                    ZStack {
                        Color(UIColor.secondarySystemBackground).ignoresSafeArea(.all)
                        viewModel.largeHeader(progress: viewModel.progress, mainWindowSize: proxy.size)
                    }
                } content: {
                    VStack {
                        if viewModel.addressData == nil || viewModel.dataStore.synchronized == false {
                            if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" {
                                LottieView(animation: .named("loadsimple"))
                                    .playing(loopMode: .loop)
                                    .resizable()
                                    .animationDidFinish { completed in
                                        self.animationDone = completed
                                    }
                                    .getRealtimeAnimationProgress($animationProgressTime)
                                    .frame(width: 250, height: 250)
                            } else {
                                LottieView(animation: .named("loadsimple"))
                                    .playing(loopMode: .loop)
                                    .resizable()
                                    .animationDidFinish { completed in
                                        self.animationDone = completed
                                    }
                                    .getRealtimeAnimationProgress($animationProgressTime)
                                    .frame(width: 350, height: 350)
                            }
                        } else {
                            if viewModel.addressData!.isEmpty {
                                VStack {
                                    if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" {
                                        LottieView(animation: .named("nodatapreview"))
                                            .playing()
                                            .resizable()
                                            .frame(width: 250, height: 250)
                                    } else {
                                        LottieView(animation: .named("nodatapreview"))
                                            .playing()
                                            .resizable()
                                            .frame(width: 350, height: 350)
                                    }
                                }
                            } else {
                                LazyVStack {
                                    SwipeViewGroup {
                                        ForEach(viewModel.addressData!) { addressData in
                                                addressCell(addressData: addressData, mainWindowSize: proxy.size)
                                                    .padding(.bottom, 2)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top)
                                .padding(.bottom)
                                .animation(.default, value: viewModel.addressData)
                                
                            }
                        }
                    }.background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    }).onPreferenceChange(ViewOffsetKey.self) { currentOffset in
                        let offsetDifference: CGFloat = self.previousViewOffset - currentOffset
                        if ( abs(offsetDifference) > minimumOffset) {
                            if offsetDifference > 0 {
                                print("Is scrolling up toward top.")
                                hideFloatingButton = false
                            } else {
                                print("Is scrolling down toward bottom.")
                                hideFloatingButton = true
                            }
                            self.previousViewOffset = currentOffset
                        }
                    }
                    .alert(isPresent: $viewModel.showToast, view: alertViewDeleted)
                    .alert(isPresent: $viewModel.showAddedToast, view: alertViewAdded)
//                    .popup(isPresented: $viewModel.showAlert) {
//                        if viewModel.addressToDelete.0 != nil && viewModel.addressToDelete.1 != nil {
//                            viewModel.alert()
//                                .frame(width: 400, height: 230)
//                                .background(Material.thin).cornerRadius(16, corners: .allCorners)
//                        }
//                    } customize: {
//                        $0
//                            .type(.default)
//                            .closeOnTapOutside(false)
//                            .dragToDismiss(false)
//                            .isOpaque(true)
//                            .animation(.spring())
//                            .closeOnTap(false)
//                            .backgroundColor(.black.opacity(0.8))
//                            
//                    }
//                    .popup(isPresented: $viewModel.presentSheet) {
//                        
//                        .frame(width: 400, height: 230)
//                        .background(Material.thin).cornerRadius(16, corners: .allCorners)
//                    } customize: {
//                        $0
//                            .type(.default)
//                            .closeOnTapOutside(false)
//                            .dragToDismiss(false)
//                            .isOpaque(true)
//                            .animation(.spring())
//                            .closeOnTap(false)
//                            .backgroundColor(.black.opacity(0.8))
//                    }
                    .animation(.easeInOut(duration: 0.25), value: viewModel.addressData == nil || viewModel.addressData != nil)
                    .onChange(of: viewModel.presentSheet) { value in
                        if value {
                            CentrePopup_AddAddress(viewModel: viewModel, territory: territory).showAndStack()
                        }
                    }
                }
                .height(min: 180, max: 350.0)
                
                .allowsHeaderGrowth()
                .collapseProgress($viewModel.progress)
                .pullToRefresh(isLoading: $viewModel.dataStore.synchronized.not) {
                    synchronizationManager.startupProcess(synchronizing: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        hideFloatingButton = false
                    }
                }
                .scrollIndicators(.hidden)
                .coordinateSpace(name: "scroll")
                if AuthorizationLevelManager().existsAdminCredentials() {
                    MainButton(imageName: "plus", colorHex: "#1e6794", width: 60) {
                        self.viewModel.presentSheet = true
                    }
                    .offset(y: hideFloatingButton ? 100 : -25)
                    .animation(.spring(), value: hideFloatingButton)
                    .vSpacing(.bottom).hSpacing(.trailing)
                    .padding()
                }
            }
            .ignoresSafeArea()
            .navigationBarBackButtonHidden()
            .navigationBarTitle("Addresses", displayMode: .inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    HStack {
                        Button("", action: {withAnimation { viewModel.backAnimation.toggle() };
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        })
                        .buttonStyle(CircleButtonStyle(imageName: "arrow.backward", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.backAnimation))
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    HStack {
                        Button("", action: { viewModel.syncAnimation.toggle();  print("Syncing") ; synchronizationManager.startupProcess(synchronizing: true) })
                            .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $viewModel.dataStore.synchronized, lastTime: $viewModel.dataStore.lastTime))
                        //                    if viewModel.isAdmin {
                        //                        Button("", action: { viewModel.optionsAnimation.toggle();  print("Add") ; viewModel.presentSheet.toggle() })
                        //                            .buttonStyle(CircleButtonStyle(imageName: "plus", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.optionsAnimation))
                        //                    }
                    }
                }
            }
            .navigationTransition(viewModel.presentSheet ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
        }
    }
    
    @ViewBuilder
    func addressCell(addressData: AddressData, mainWindowSize: CGSize) -> some View {
        LazyVStack {
            SwipeView {
                NavigationLink(destination: NavigationLazyView(HousesView(address: addressData.address).implementPopupView()).implementPopupView()) {
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
                        .frame(maxWidth: mainWindowSize.width * 0.90)
                    }
                    //.id(territory.id)
                    .padding(10)
                    .frame(minWidth: mainWindowSize.width * 0.95)
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
                            self.viewModel.addressToDelete = (addressData.address.id, addressData.address.address)
                            //self.showAlert = true
                            if viewModel.addressToDelete.0 != nil && viewModel.addressToDelete.1 != nil {
                                CentrePopup_DeleteTerritoryAddress(viewModel: viewModel).showAndStack()
                            }
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
                        self.viewModel.currentAddress = addressData.address
                        self.viewModel.presentSheet = true
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
    }
}

struct CentrePopup_DeleteTerritoryAddress: CentrePopup {
    @ObservedObject var viewModel: AddressViewModel
    
    
    func createContent() -> some View {
        ZStack {
            VStack {
                Text("Delete Address: \(viewModel.addressToDelete.1 ?? "0")")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                    .padding(.leading)
                Text("Are you sure you want to delete the selected address?")
                    .font(.headline)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                    .padding(.leading)
                if viewModel.ifFailed {
                    Text("Error deleting address, please try again later")
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                //.vSpacing(.bottom)
                
                HStack {
                    if !viewModel.loading {
                        CustomBackButton() {
                            withAnimation {
                                //self.showAlert = false
                                dismiss()
                                self.viewModel.ifFailed = false
                                self.viewModel.addressToDelete = (nil,nil)
                            }
                        }
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: viewModel.loading, title: "Delete", color: .red) {
                        withAnimation {
                            self.viewModel.loading = true
                        }
                        Task {
                            if self.viewModel.addressToDelete.0 != nil && self.viewModel.addressToDelete.1 != nil {
                                switch await self.viewModel.deleteAddress(address: self.viewModel.addressToDelete.0 ?? "") {
                                case .success(_):
                                    withAnimation {
                                        self.viewModel.synchronizationManager.startupProcess(synchronizing: true)
                                        self.viewModel.getAddresses()
                                        self.viewModel.loading = false
                                        //self.viewModel.showAlert = false
                                        dismiss()
                                        self.viewModel.ifFailed = false
                                        self.viewModel.addressToDelete = (nil,nil)
                                        self.viewModel.showToast = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                            self.viewModel.showToast = false
                                        }
                                    }
                                case .failure(_):
                                    withAnimation {
                                        self.viewModel.loading = false
                                    }
                                    self.viewModel.ifFailed = true
                                }
                            }
                        }
                        
                    }
                }
                .padding([.horizontal, .bottom])
            }
            .ignoresSafeArea(.keyboard)
            
        }.ignoresSafeArea(.keyboard)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .padding(.horizontal, 10)
            .background(Material.thin).cornerRadius(15, corners: .allCorners)
    }
    
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup
            .horizontalPadding(24)
            .cornerRadius(15)
            .backgroundColour(Color(UIColor.systemGray6).opacity(85))
    }
}

struct CentrePopup_AddAddress: CentrePopup {
    @ObservedObject var viewModel: AddressViewModel
    @State var territory: TerritoryModel
    
    
    func createContent() -> some View {
        AddAddressView(territory: territory, address: viewModel.currentAddress, onDone: {
            DispatchQueue.main.async {
                viewModel.presentSheet = false
                dismiss()
                viewModel.synchronizationManager.startupProcess(synchronizing: true)
                viewModel.getAddresses()
                viewModel.showAddedToast = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    viewModel.showAddedToast = false
                }
            }
        }, onDismiss: {
            viewModel.presentSheet = false
            dismiss()
        })
            .padding(.top, 10)
            .padding(.bottom, 10)
            .padding(.horizontal, 10)
            .background(Material.thin).cornerRadius(15, corners: .allCorners)
            .simultaneousGesture(
                // Hide the keyboard on scroll
                DragGesture().onChanged { _ in
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
            )
    }
    
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup
            .horizontalPadding(24)
            .cornerRadius(15)
            .backgroundColour(Color(UIColor.systemGray6).opacity(85))
    }
}
