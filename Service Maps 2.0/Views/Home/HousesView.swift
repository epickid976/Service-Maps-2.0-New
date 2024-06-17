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
import MijickPopupView

struct HousesView: View {
    var address: TerritoryAddressModel
    
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: HousesViewModel
    
    @State var showFab = true
    @State var scrollOffset: CGFloat = 0.00
    
    init(address: TerritoryAddressModel, houseIdToScrollTo: String? = nil) {
        self.address = address
        let initialViewModel = HousesViewModel(territoryAddress: address, houseIdToScrollTo: houseIdToScrollTo)
        _viewModel = ObservedObject(wrappedValue: initialViewModel)
        
    }
    
    let alertViewDeleted = AlertAppleMusic17View(title: "House Deleted", subtitle: nil, icon: .custom(UIImage(systemName: "trash")!))
    let alertViewAdded = AlertAppleMusic17View(title: "House Added", subtitle: nil, icon: .done)
    
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    let minimumOffset: CGFloat = 60
    
    @State var highlightedHouseId: String?
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ScrollViewReader { scrollViewProxy in
                    ScrollView {
                        LazyVStack {
                            if viewModel.houseData == nil || !viewModel.dataStore.synchronized {
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
                                if viewModel.houseData!.isEmpty {
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
                                            ForEach(viewModel.houseData!, id: \.id) { houseData in
                                                houseCellView(houseData: houseData, mainWindowSize: proxy.size).id(houseData.house.id)
                                            }.modifier(ScrollTransitionModifier())
                                        }
                                    }.animation(.default, value: viewModel.houseData!)
                                        .padding()
                                    
                                    
                                }
                            }
                        }.background(GeometryReader {
                            Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                        })
                        .onPreferenceChange(ViewOffsetKey.self) { currentOffset in
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
                        .animation(.easeInOut(duration: 0.25), value: viewModel.houseData == nil || viewModel.houseData != nil)
                        .alert(isPresent: $viewModel.showToast, view: alertViewDeleted)
                        .alert(isPresent: $viewModel.showAddedToast, view: alertViewAdded)
                        .onChange(of: viewModel.presentSheet) { value in
                            if value {
                                CentrePopup_AddHouse(viewModel: viewModel, address: address).showAndStack()
                            }
                        }
                        .navigationBarTitle("\(address.address)", displayMode: .large)
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarLeading) {
                                HStack {
                                    Button("", action: {withAnimation { viewModel.backAnimation.toggle() };
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            presentationMode.wrappedValue.dismiss()
                                        }
                                    }).keyboardShortcut(.delete, modifiers: .command)
                                        .buttonStyle(CircleButtonStyle(imageName: "arrow.backward", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.backAnimation))
                                }
                            }
                            ToolbarItemGroup(placement: .topBarTrailing) {
                                HStack {
                                    Button("", action: { viewModel.syncAnimation.toggle();  print("Syncing") ; viewModel.synchronizationManager.startupProcess(synchronizing: true) }).keyboardShortcut("s", modifiers: .command)
                                        .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $viewModel.dataStore.synchronized, lastTime: $viewModel.dataStore.lastTime))
                                    
                                    Menu {
                                        Picker("Sort", selection: $viewModel.sortPredicate) {
                                            ForEach(HouseSortPredicate.allCases, id: \.self) { option in
                                                Text(String(describing: option).capitalized)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        
                                        Picker("Filter", selection: $viewModel.filterPredicate) {
                                            ForEach(HouseFilterPredicate.allCases, id: \.self) { option in
                                                Text(option.rawValue)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                    } label: {
                                        Button("", action: { viewModel.optionsAnimation.toggle();  print("Add") ; viewModel.presentSheet.toggle() }).keyboardShortcut(";", modifiers: .command)
                                            .buttonStyle(CircleButtonStyle(imageName: "ellipsis", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.optionsAnimation))
                                    }
                                    
                                }
                            }
                        }
                        .navigationTransition(viewModel.presentSheet || viewModel.houseIdToScrollTo != nil ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
                        .navigationViewStyle(StackNavigationViewStyle())
                    }.coordinateSpace(name: "scroll")
                        .scrollIndicators(.hidden)
                        .refreshable {
                            viewModel.synchronizationManager.startupProcess(synchronizing: true)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                hideFloatingButton = false
                            }
                        }
                        .onChange(of: viewModel.dataStore.synchronized) { value in
                            if value {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    viewModel.getHouses()
                                }
                            }
                        }
                        .onChange(of: viewModel.houseIdToScrollTo) { id in
                            if let id = id {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        scrollViewProxy.scrollTo(id, anchor: .center)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
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
                    .keyboardShortcut("+", modifiers: .command)
                }
                
            }
        }
    }
    
    @ViewBuilder
    func houseCellView(houseData: HouseData, mainWindowSize: CGSize) -> some View {
        SwipeView {
            NavigationLink(destination: NavigationLazyView(VisitsView(house: houseData.house).implementPopupView())) {
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
                                        DispatchQueue.main.async {
                                            self.viewModel.houseToDelete = (houseData.house.id, houseData.house.number)
                                            //self.showAlert = true
                                            if viewModel.houseToDelete.0 != nil && viewModel.houseToDelete.1 != nil {
                                                CentrePopup_DeleteHouse(viewModel: viewModel).showAndStack()
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
                
            }
        } trailingActions: { context in
            if houseData.accessLevel == .Admin {
                SwipeAction(
                    systemImage: "trash",
                    backgroundColor: .red
                ) {
                    DispatchQueue.main.async {
                        context.state.wrappedValue = .closed
                        self.viewModel.houseToDelete = (houseData.house.id, houseData.house.number)
                        //self.showAlert = true
                        if viewModel.houseToDelete.0 != nil && viewModel.houseToDelete.1 != nil {
                            CentrePopup_DeleteHouse(viewModel: viewModel).showAndStack()
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
        .swipeMinimumDistance(houseData.accessLevel != .User ? 25:1000)
        
    }
    
    struct BorderModifier: ViewModifier {
        let highlighted: Bool
        
        func body(content: Content) -> some View {
            content
                .border(highlighted ? Color.gray : Color.clear, width: 2)
                .cornerRadius(16)
        }
    }
}


struct CentrePopup_DeleteHouse: CentrePopup {
    @ObservedObject var viewModel: HousesViewModel
    
    
    func createContent() -> some View {
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
                //.vSpacing(.bottom)
                
                HStack {
                    if !viewModel.loading {
                        CustomBackButton() {
                            withAnimation {
                                //self.viewModel.showAlert = false
                                dismiss()
                                self.viewModel.houseToDelete = (nil,nil)
                            }
                        }
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: viewModel.loading, title: "Delete", color: .red) {
                        withAnimation {
                            self.viewModel.loading = true
                        }
                        Task {
                            if self.viewModel.houseToDelete.0 != nil && self.viewModel.houseToDelete.1 != nil {
                                switch await self.viewModel.deleteHouse(house: self.viewModel.houseToDelete.0 ?? "") {
                                case .success(_):
                                    withAnimation {
                                        self.viewModel.synchronizationManager.startupProcess(synchronizing: true)
                                        self.viewModel.getHouses()
                                        self.viewModel.loading = false
                                        //self.showAlert = false
                                        dismiss()
                                        self.viewModel.ifFailed = false
                                        self.viewModel.houseToDelete = (nil,nil)
                                        self.viewModel.showToast = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                            self.viewModel.showToast = false
                                        }
                                    }
                                case .failure(_):
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
                //.vSpacing(.bottom)
                
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

struct CentrePopup_AddHouse: CentrePopup {
    @ObservedObject var viewModel: HousesViewModel
    @State var address: TerritoryAddressModel
    
    
    func createContent() -> some View {
        AddHouseView(house: viewModel.currentHouse, address: address, onDone: {
            DispatchQueue.main.async {
                viewModel.presentSheet = false
                dismiss()
                viewModel.synchronizationManager.startupProcess(synchronizing: true)
                viewModel.getHouses()
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
