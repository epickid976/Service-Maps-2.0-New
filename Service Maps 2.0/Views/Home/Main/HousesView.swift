//
//  HousesView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/28/23.
//

import SwiftUI
import CoreData
import NavigationTransitions
import SwipeActions
import Combine
import UIKit
import Lottie
import AlertKit
import MijickPopups
import Toasts

//MARK: - HousesView

struct HousesView: View {
    var address: TerritoryAddress
    
    //MARK: - Environment
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.presentToast) var presentToast
    
    //MARK: - Dependencies
    
    @StateObject var viewModel: HousesViewModel
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var preferencesViewModel = ColumnViewModel()
    
    //MARK: - Properties
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    @State var showFab = true
    @State var scrollOffset: CGFloat = 0.00
    
    
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    let minimumOffset: CGFloat = 60
    
    @State var highlightedHouseId: String?
    
    //MARK: - Initializers
    
    init(address: TerritoryAddress, houseIdToScrollTo: String? = nil) {
        self.address = address
        let initialViewModel = HousesViewModel(territoryAddress: address, houseIdToScrollTo: houseIdToScrollTo)
        _viewModel = StateObject(wrappedValue: initialViewModel)
        
    }
    
    //MARK: - Body
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ScrollViewReader { scrollViewProxy in
                    ScrollView {
                        LazyVStack {
                            if viewModel.houseData == nil && !dataStore.synchronized {
                                if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" {
                                    LottieView(animation: .named("loadsimple"))
                                        .playing(loopMode: .loop)
                                        .resizable()
                                        .frame(width: 250, height: 250)
                                } else {
                                    LottieView(animation: .named("loadsimple"))
                                        .playing(loopMode: .loop)
                                        .resizable()
                                        .frame(width: 350, height: 350)
                                }
                            } else {
                                if let data = viewModel.houseData {
                                    if data.isEmpty {
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
                                        
                                    } else {
                                        SwipeViewGroup {
                                            if UIDevice().userInterfaceIdiom == .pad && proxy.size.width > 400 && preferencesViewModel.isColumnViewEnabled {
                                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                                    let proxy = CGSize(width: proxy.size.width / 2 - 16, height: proxy.size.height)
                                                    ForEach(viewModel.houseData!, id: \.house.id) { houseData in
                                                        houseCellView(houseData: houseData, mainWindowSize: proxy).id(houseData.house.id).modifier(ScrollTransitionModifier())
                                                            .transition(.customBackInsertion)
                                                    }.modifier(ScrollTransitionModifier())
                                                }
                                            } else {
                                                LazyVGrid(columns: [GridItem(.flexible())]) {
                                                    ForEach(viewModel.houseData!, id: \.house.id) { houseData in
                                                        houseCellView(houseData: houseData, mainWindowSize: proxy.size).id(houseData.house.id).modifier(ScrollTransitionModifier())
                                                            .transition(.customBackInsertion)
                                                    }.modifier(ScrollTransitionModifier())
                                                }
                                            }
                                        }.animation(.spring(), value: viewModel.houseData!)
                                            .padding()
                                        
                                        
                                    }
                                }
                            }
                        }
                        .background(GeometryReader {
                            Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                        })
                        .onPreferenceChange(ViewOffsetKey.self) { currentOffset in
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
                        .animation(.easeInOut(duration: 0.25), value: viewModel.houseData == nil || viewModel.houseData != nil)
                        .onChange(of: viewModel.presentSheet) { value in
                            if value {
                                CentrePopup_AddHouse(viewModel: viewModel, address: address){
                                    let toast = ToastValue(
                                        icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green),
                                        message: "House Added"
                                    )
                                    presentToast(toast)
                                }.present()
                            }
                        }
                        .navigationBarTitle(address.address, displayMode: .automatic)
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarLeading) {
                                HStack {
                                    Button("", action: {withAnimation { viewModel.backAnimation.toggle(); HapticManager.shared.trigger(.lightImpact) };
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            dismissAllPopups()
                                            presentationMode.wrappedValue.dismiss()
                                        }
                                    })
                                    .buttonStyle(CircleButtonStyle(imageName: "arrow.backward", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.backAnimation))
                                }
                            }
                            ToolbarItemGroup(placement: .topBarTrailing) {
                                HStack {
                                    Button("", action: { viewModel.syncAnimation = true; synchronizationManager.startupProcess(synchronizing: true) })//.keyboardShortcut("s", modifiers: .command)
                                        .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $dataStore.synchronized, lastTime: $dataStore.lastTime))
                                    
                                    Menu {
                                        Picker("Sort", selection: $viewModel.sortPredicate) {
                                            ForEach(HouseSortPredicate.allCases, id: \.self) { option in
                                                Text(option.localized)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        
                                        Picker("Filter", selection: $viewModel.filterPredicate) {
                                            ForEach(HouseFilterPredicate.allCases, id: \.self) { option in
                                                Text(option.localized)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        
                                    } label: {
                                        Button("", action: { viewModel.optionsAnimation.toggle(); HapticManager.shared.trigger(.lightImpact); viewModel.presentSheet.toggle() })//.keyboardShortcut(";", modifiers: .command)
                                            .buttonStyle(CircleButtonStyle(imageName: "ellipsis", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.optionsAnimation))
                                    }
                                    
                                }
                            }
                        }
                        .navigationTransition(viewModel.presentSheet || viewModel.houseIdToScrollTo != nil ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
                        .navigationViewStyle(StackNavigationViewStyle())
                    }.coordinateSpace(name: "scroll")
                        .scrollIndicators(.never)
                        .refreshable {
                            synchronizationManager.startupProcess(synchronizing: true)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                hideFloatingButton = false
                            }
                        }
                        .onChange(of: viewModel.houseIdToScrollTo) { id in
                            if let id = id {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        scrollViewProxy.scrollTo(id, anchor: .center)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            HapticManager.shared.trigger(.selectionChanged)
                                            highlightedHouseId = id // Highlight after scrolling
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            highlightedHouseId = nil
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
                    .offset(y: hideFloatingButton ? 150 : 0)
                    .animation(.spring(), value: hideFloatingButton)
                    .vSpacing(.bottom).hSpacing(.trailing)
                    .padding()
                }
                
            }
        }
    }
    
    //MARK: - House Cell View
    
    @ViewBuilder
    func houseCellView(houseData: HouseData, mainWindowSize: CGSize) -> some View {
        SwipeView {
            NavigationLink(destination: NavigationLazyView(VisitsView(house: houseData.house).installToast(position: .bottom))) {
                HouseCell(house: houseData, mainWindowSize: mainWindowSize)
                    .padding(.bottom, 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16) // Same shape as the cell
                            .fill(highlightedHouseId == houseData.house.id ? Color.gray.opacity(0.5) : Color.clear).animation(.default, value: highlightedHouseId == houseData.house.id) // Fill with transparent gray if highlighted
                    )
                    .optionalViewModifier { content in
                        if AuthorizationLevelManager().existsAdminCredentials() {
                            content
                                .contextMenu {
                                    Button {
                                        HapticManager.shared.trigger(.lightImpact)
                                        DispatchQueue.main.async {
                                            self.viewModel.houseToDelete = (houseData.house.id, houseData.house.number)
                                            //self.showAlert = true
                                            if viewModel.houseToDelete.0 != nil && viewModel.houseToDelete.1 != nil {
                                                CentrePopup_DeleteHouse(viewModel: viewModel) {
                                                    let toast = ToastValue(
                                                        icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                                        message: NSLocalizedString("House Deleted", comment: "")
                                                    )
                                                    presentToast(toast)
                                                }.present()
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "trash")
                                            Text("Delete House")
                                        }
                                    }
                                    //TODO Trash and Pencil only if admin
                                }.clipShape(RoundedRectangle(cornerRadius: 16, style: .circular))
                        } else {
                            content
                        }
                    }
                
            }.onTapHaptic(.lightImpact)
        } leadingActions: { context in
            SwipeAction(
                systemImage: "pencil.tip.crop.circle.badge.plus.fill",
                backgroundColor: .green
            ) {
                HapticManager.shared.trigger(.lightImpact)
                DispatchQueue.main.async {
                    context.state.wrappedValue = .closed
                    CentrePopup_AddVisit(viewModel: VisitsViewModel(house: houseData.house), house: houseData.house
                    ) {
                           let toast = ToastValue(
                            icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green),
                               message: "Visit Added"
                           )
                        presentToast(toast)
                    }.present()
                }
            }
            .allowSwipeToTrigger()
            .font(.title.weight(.semibold))
            .foregroundColor(.white)
        } trailingActions: { context in
            if houseData.accessLevel == .Admin {
                SwipeAction(
                    systemImage: "trash",
                    backgroundColor: .red
                ) {
                    HapticManager.shared.trigger(.lightImpact)
                    DispatchQueue.main.async {
                        context.state.wrappedValue = .closed
                        self.viewModel.houseToDelete = (houseData.house.id, houseData.house.number)
                        //self.showAlert = true
                        if viewModel.houseToDelete.0 != nil && viewModel.houseToDelete.1 != nil {
                            CentrePopup_DeleteHouse(viewModel: viewModel){
                                let toast = ToastValue(
                                    icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                    message: NSLocalizedString("House Deleted", comment: "")
                                )
                                presentToast(toast)
                            }.present()
                        }
                    }
                }
                .font(.title.weight(.semibold))
                .foregroundColor(.white)
            }
        }
        .swipeActionCornerRadius(16)
        .swipeSpacing(5)
        .swipeOffsetCloseAnimation(stiffness: 500, damping: 100)
        .swipeOffsetExpandAnimation(stiffness: 500, damping: 100)
        .swipeOffsetTriggerAnimation(stiffness: 500, damping: 100)
        .swipeMinimumDistance(25)
        
    }
}

//MARK: - Delete House Popup

struct CentrePopup_DeleteHouse: CentrePopup {
    @ObservedObject var viewModel: HousesViewModel
    var onDone: () -> Void
    
    init(viewModel: HousesViewModel, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDone = onDone
    }
    
    var body: some View {
        ZStack {
            VStack {
                Text("Delete House \(viewModel.houseToDelete.1 ?? "0")")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                    .padding(.leading)
                Text("Are you sure you want to delete the selected house?")
                    .font(.headline)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                    .padding(.leading)
                if viewModel.ifFailed {
                    Text("Error deleting house, please try again later")
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                
                HStack {
                    if !viewModel.loading {
                        CustomBackButton() {
                            HapticManager.shared.trigger(.lightImpact)
                            withAnimation {
                                dismissLastPopup()
                                self.viewModel.houseToDelete = (nil,nil)
                            }
                        }
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: viewModel.loading, title: NSLocalizedString("Delete", comment: ""), color: .red) {
                        HapticManager.shared.trigger(.lightImpact)
                        withAnimation {
                            self.viewModel.loading = true
                        }
                        Task {
                            if self.viewModel.houseToDelete.0 != nil && self.viewModel.houseToDelete.1 != nil {
                                switch await self.viewModel.deleteHouse(house: self.viewModel.houseToDelete.0 ?? "") {
                                case .success(_):
                                    HapticManager.shared.trigger(.success)
                                    withAnimation {
                                        self.viewModel.loading = false
                                        dismissLastPopup()
                                        self.viewModel.ifFailed = false
                                        self.viewModel.houseToDelete = (nil,nil)
                                        onDone()
                                    }
                                case .failure(_):
                                    HapticManager.shared.trigger(.error)
                                    withAnimation {
                                        self.viewModel.loading = false
                                        self.viewModel.ifFailed = true
                                    }
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
    func configurePopup(config: CentrePopupConfig) -> CentrePopupConfig {
        config
            .popupHorizontalPadding(24)
        
        
    }
}

//MARK: - Add House Popup

struct CentrePopup_AddHouse: CentrePopup {
    @ObservedObject var viewModel: HousesViewModel
    @State var address: TerritoryAddress
    var onDone: () -> Void
    
    init(viewModel: HousesViewModel, address: TerritoryAddress, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.address = address
        self.onDone = onDone
    }
    
    var body: some View {
        AddHouseView(house: viewModel.currentHouse, address: address, onDone: {
            DispatchQueue.main.async {
                viewModel.presentSheet = false
                dismissLastPopup()
                onDone()
                
            }
        }, onDismiss: {
            viewModel.presentSheet = false
            dismissLastPopup()
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
    
    func configurePopup(config: CentrePopupConfig) -> CentrePopupConfig {
        config
            .popupHorizontalPadding(24)
        
        
    }
}
