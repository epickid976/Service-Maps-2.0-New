//
//  TerritoryAddressView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/2/23.
//

import SwiftUI
import NukeUI
import NavigationTransitions
import ScalingHeaderScrollView
import SwipeActions
import Lottie
import AlertKit
import MijickPopups
import ImageViewerRemote
import Toasts

//MARK: - Territory Address View

struct TerritoryAddressView: View {
    var territory: Territory
    
    //MARK: - Initializer
    
    init(territory: Territory, territoryAddressIdToScrollTo: String? = nil) {
        self.territory = territory
        self.imageURL = territory.getImageURL()
        
        let initialViewModel = AddressViewModel(territory: territory, territoryAddressIdToScrollTo: territoryAddressIdToScrollTo)
        _viewModel = StateObject(wrappedValue: initialViewModel)
    }
    
    //MARK: - Environment
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.presentToast) var presentToast
    @Environment(\.mainWindowSize) var mainWindowSize
    
    //MARK: - Dependencies
    
    @StateObject var viewModel: AddressViewModel
    @ObservedObject var preferencesViewModel = ColumnViewModel()
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    
    //MARK: - Properties
    
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    
    let minimumOffset: CGFloat = 60
    
    @State var highlightedTerritoryAddressId: String?
    @State var imageURL = String()
    
    //MARK: - Body
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ScrollViewReader { scrollViewProxy in
                    ScalingHeaderScrollView {
                        ZStack {
                            Color(UIColor.secondarySystemBackground).ignoresSafeArea(.all)
                            viewModel.largeHeader(progress: viewModel.progress, mainWindowSize: proxy.size) .onTapGesture { if !imageURL.isEmpty {
                                HapticManager.shared.trigger(.lightImpact)
                                viewModel.showImageViewer = true }
                            }
                                
                        }
                        
                    } content: {
                        VStack {
                            if viewModel.addressData == nil && viewModel.dataStore.synchronized == false {
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
                                if let data = viewModel.addressData {
                                    if data.isEmpty {
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
                                                if UIDevice().userInterfaceIdiom == .pad && proxy.size.width > 400 && preferencesViewModel.isColumnViewEnabled  {
                                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                                        ForEach(viewModel.addressData ?? [], id: \.address.id) { addressData in
                                                            let proxy = CGSize(width: proxy.size.width / 2 - 16, height: proxy.size.height)
                                                            addressCell(addressData: addressData, mainWindowSize: proxy)
                                                                .padding(.bottom, 2)
                                                                .id(addressData.address.id)
                                                                .transition(.customBackInsertion)
                                                        }.modifier(ScrollTransitionModifier())
                                                    }
                                                } else {
                                                    LazyVGrid(columns: [GridItem(.flexible())]) {
                                                        ForEach(viewModel.addressData ?? [], id: \.address.id) { addressData in
                                                            addressCell(addressData: addressData, mainWindowSize: proxy.size)
                                                                .padding(.bottom, 2)
                                                                .id(addressData.address.id)
                                                                .transition(.customBackInsertion)
                                                        }.modifier(ScrollTransitionModifier())
                                                    }
                                                }
                                            }
                                            
                                        }
                                        .padding(.horizontal)
                                        .padding(.top)
                                        .padding(.bottom)
                                        .animation(.default, value: viewModel.addressData)
                                    }
                                }
                            }
                        }
                        .background(GeometryReader {
                            Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                        }).onPreferenceChange(ViewOffsetKey.self) { currentOffset in
                            Task { @MainActor in
                                let offsetDifference: CGFloat = self.previousViewOffset - currentOffset
                                if ( abs(offsetDifference) > minimumOffset) {
                                    if offsetDifference > 0 {
                                        
                                        hideFloatingButton = false
                                    } else {
                                        
                                        hideFloatingButton = true
                                    }
                                    self.previousViewOffset = currentOffset
                                }
                            }
                        }
                        .animation(.easeInOut(duration: 0.25), value: viewModel.addressData == nil || viewModel.addressData != nil)
                        .onChange(of: viewModel.presentSheet) { value in
                            if value {
                                Task {
                                    await CenterPopup_AddAddress(viewModel: viewModel, territory: territory){
                                        let toast = ToastValue(
                                            icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green),
                                            message: "Address Added"
                                        )
                                        presentToast(toast)
                                    }.present()
                                }
                            }
                        }
                    }
                    .height(min: 180, max: 350.0)
                    
                    .allowsHeaderGrowth()
                    .collapseProgress($viewModel.progress)
                    .pullToRefresh(isLoading: $viewModel.dataStore.synchronized.not) {
                        Task {
                            synchronizationManager.startupProcess(synchronizing: true)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                hideFloatingButton = false
                            }
                        }
                    }
                    .scrollIndicators(.never)
                    .coordinateSpace(name: "scroll")
                    .onChange(of: viewModel.territoryAddressIdToScrollTo) { id in
                        if let id = id {
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    scrollViewProxy.scrollTo(id, anchor: .center)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        HapticManager.shared.trigger(.selectionChanged)
                                        highlightedTerritoryAddressId = id // Highlight after scrolling
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        highlightedTerritoryAddressId = nil
                                    }
                                }
                            }
                            
                        }
                    }
                }
                
                if AuthorizationLevelManager().existsAdminCredentials() {
                    MainButton(imageName: "plus", colorHex: "#1e6794", width: 60) {
                        self.viewModel.presentSheet = true
                    }
                    .offset(y: hideFloatingButton ? 100 : -25)
                    .animation(.spring(), value: hideFloatingButton)
                    .vSpacing(.bottom).hSpacing(.trailing)
                    .padding()
                    //.keyboardShortcut("+", modifiers: .command)
                }
            }
            
            .ignoresSafeArea()
            .navigationBarBackButtonHidden()
            .navigationBarTitle("Addresses", displayMode: .inline)
            .toolbar {
                if !viewModel.showImageViewer {
                    ToolbarItemGroup(placement: .topBarLeading) {
                        HStack {
                            Button("", action: {withAnimation { viewModel.backAnimation.toggle();
                                HapticManager.shared.trigger(.lightImpact) };
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    Task {
                                        await dismissAllPopups()
                                    }
                                    presentationMode.wrappedValue.dismiss()
                                }
                            })//.keyboardShortcut(.delete, modifiers: .command)
                            .buttonStyle(CircleButtonStyle(imageName: "arrow.backward", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.backAnimation))
                        }
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        HStack {
                            Button("", action: { viewModel.syncAnimation = true;
                                viewModel.synchronizationManager.startupProcess(synchronizing: true)  }) //.ke yboardShortcut("s", modifiers: .command)
                                .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $viewModel.dataStore.synchronized, lastTime: $viewModel.dataStore.lastTime))
                        }
                    }
                }
            }
            .navigationTransition(viewModel.presentSheet || viewModel.territoryAddressIdToScrollTo != nil ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
        }.overlay(ImageViewerRemote(imageURL: $imageURL, viewerShown: $viewModel.showImageViewer))
    }
    
    //MARK: - Address Cell
    
    @ViewBuilder
    func addressCell(addressData: AddressData, mainWindowSize: CGSize) -> some View {
        var isIpad: Bool {
            return UIDevice.current.userInterfaceIdiom == .pad && mainWindowSize.width > 400
        }
        LazyVStack {
            SwipeView {
                NavigationLink(destination: NavigationLazyView(HousesView(address: addressData.address).installToast(position: .bottom))) {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(addressData.address.address)")
                                .font(.headline)
                                .fontWeight(.heavy)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                                .hSpacing(.leading)
                            Text("Doors: \(addressData.houseQuantity)")
                                .font(.body)
                                .lineLimit(5)
                                .foregroundColor(.secondaryLabel)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.leading)
                                .hSpacing(.leading)
                        }
                        .frame(maxWidth: mainWindowSize.width * 0.90)
                    }
                    .optionalViewModifier { content in
                        if isIpad {
                            content
                                .frame(maxHeight: .infinity)
                        } else {
                            content
                        }
                    }
                    //.id(territory.id)
                    .padding(10)
                    .frame(minWidth: mainWindowSize.width * 0.95)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .optionalViewModifier { content in
                        if AuthorizationLevelManager().existsAdminCredentials() {
                            content
                                .contextMenu {
                                    Button(action: {
                                        copyToClipboard(text: addressData.address.address)
                                    }) {
                                        Text("Copy Address")
                                            .padding()
                                            .background(Color.green)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                    
                                    Button {
                                        HapticManager.shared.trigger(.lightImpact)
                                        DispatchQueue.main.async {
                                            self.viewModel.addressToDelete = (addressData.address.id, addressData.address.address)
                                            //self.showAlert = true
                                            if viewModel.addressToDelete.0 != nil && viewModel.addressToDelete.1 != nil {
                                                Task {
                                                    await CenterPopup_DeleteTerritoryAddress(viewModel: viewModel){
                                                        let toast = ToastValue(
                                                            icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                                            message: NSLocalizedString("Address Added", comment: "")
                                                        )
                                                        presentToast(toast)
                                                    }.present()
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "trash")
                                            Text("Delete Address")
                                        }
                                    }
                                    
                                    Button {
                                        HapticManager.shared.trigger(.lightImpact)
                                        self.viewModel.currentAddress = addressData.address
                                        self.viewModel.presentSheet = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "pencil")
                                            Text("Edit Address")
                                        }
                                    }
                                    //TODO Trash and Pencil only if admin
                                }.clipShape(RoundedRectangle(cornerRadius: 16, style: .circular))
                        } else {
                            content
                        }
                    }
                    
                }.onTapHaptic(.lightImpact)
                .overlay(
                    RoundedRectangle(cornerRadius: 16) // Same shape as the cell
                        .fill(highlightedTerritoryAddressId == addressData.address.id ? Color.gray.opacity(0.5) : Color.clear).animation(.default, value: highlightedTerritoryAddressId == addressData.address.id) // Fill with transparent gray if highlighted
                )
            } trailingActions: { context in
                if addressData.accessLevel == .Admin {
                    SwipeAction(
                        systemImage: "trash",
                        backgroundColor: .red
                    ) {
                        HapticManager.shared.trigger(.lightImpact)
                        DispatchQueue.main.async {
                            context.state.wrappedValue = .closed
                            self.viewModel.addressToDelete = (addressData.address.id, addressData.address.address)
                            //self.showAlert = true
                            if viewModel.addressToDelete.0 != nil && viewModel.addressToDelete.1 != nil {
                                Task {
                                    await CenterPopup_DeleteTerritoryAddress(viewModel: viewModel){
                                       
                                        let toast = ToastValue(
                                            icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                            message: NSLocalizedString("Address Deleted", comment: "")
                                        )
                                        presentToast(toast)
                                    }.present()
                                }
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
                        HapticManager.shared.trigger(.lightImpact)
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

//MARK: - Delete Address Popup

struct CenterPopup_DeleteTerritoryAddress: CenterPopup {
    @ObservedObject var viewModel: AddressViewModel
    var onDone: () -> Void

    init(viewModel: AddressViewModel, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        viewModel.loading = false
        self.onDone = onDone
    }

    var body: some View {
        createContent()
    }

    func createContent() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundColor(.red)

            Text("Delete Address: \(viewModel.addressToDelete.1 ?? "0")")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text("Are you sure you want to delete the selected address?")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if viewModel.ifFailed {
                Text("Error deleting address, please try again later")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }

            HStack(spacing: 12) {
                if !viewModel.loading {
                    CustomBackButton(showImage: true, text: NSLocalizedString("Cancel", comment: "")) {
                        HapticManager.shared.trigger(.lightImpact)
                        withAnimation {
                            viewModel.ifFailed = false
                            viewModel.addressToDelete = (nil, nil)
                        }
                        Task { await dismissLastPopup() }
                    }
                }

                CustomButton(loading: viewModel.loading, title: NSLocalizedString("Delete", comment: ""), color: .red) {
                    HapticManager.shared.trigger(.lightImpact)
                    withAnimation { viewModel.loading = true }

                    Task {
                        if let id = viewModel.addressToDelete.0 {
                            switch await viewModel.deleteAddress(address: id) {
                            case .success:
                                HapticManager.shared.trigger(.success)
                                viewModel.ifFailed = false
                                viewModel.addressToDelete = (nil, nil)
                                await dismissLastPopup()
                                onDone()
                            case .failure:
                                HapticManager.shared.trigger(.error)
                                withAnimation { viewModel.loading = false }
                                viewModel.ifFailed = true
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Material.thin)
        .cornerRadius(20)
    }

    func configurePopup(config: CenterPopupConfig) -> CenterPopupConfig {
        config.popupHorizontalPadding(24)
    }
}

//MARK: - Add Address Popup

struct CenterPopup_AddAddress: CenterPopup {
    @ObservedObject var viewModel: AddressViewModel
    @State var territory: Territory
    var onDone: () -> Void

    init(viewModel: AddressViewModel, territory: Territory, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.territory = territory
        self.onDone = onDone
    }

    var body: some View {
        createContent()
    }

    func createContent() -> some View {
        AddAddressView(
            territory: territory,
            address: viewModel.currentAddress,
            onDone: {
                DispatchQueue.main.async {
                    viewModel.presentSheet = false
                    Task { await dismissLastPopup() }
                    onDone()
                }
            },
            onDismiss: {
                viewModel.presentSheet = false
                Task { await dismissLastPopup() }
            }
        )
        .padding()
        .background(Material.thin)
        .cornerRadius(20)
        .ignoresSafeArea(.keyboard)
        .simultaneousGesture(
            DragGesture().onChanged { _ in
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        )
    }

    func configurePopup(config: CenterPopupConfig) -> CenterPopupConfig {
        config.popupHorizontalPadding(24)
    }
}
