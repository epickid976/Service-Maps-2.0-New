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
import PopupView
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
    
    init(address: TerritoryAddressModel) {
        
        self.address = address
        let initialViewModel = HousesViewModel(territoryAddress: address)
        _viewModel = ObservedObject(wrappedValue: initialViewModel)
        
    }
    
    let alertViewDeleted = AlertAppleMusic17View(title: "House Deleted", subtitle: nil, icon: .custom(UIImage(systemName: "trash")!))
    let alertViewAdded = AlertAppleMusic17View(title: "House Added", subtitle: nil, icon: .done)
    
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    let minimumOffset: CGFloat = 40
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ScrollView {
                    VStack {
                        if viewModel.houseData == nil || viewModel.dataStore.synchronized == false {
                            if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" {
                                LottieView(animation: .named("loadsimple"))
                                    .playing()
                                    .resizable()
                                    .animationDidFinish { completed in
                                        self.animationDone = completed
                                    }
                                    .getRealtimeAnimationProgress($animationProgressTime)
                                    .frame(width: 250, height: 250)
                            } else {
                                LottieView(animation: .named("loadsimple"))
                                    .playing()
                                    .resizable()
                                    .animationDidFinish { completed in
                                        self.animationDone = completed
                                    }
                                    .getRealtimeAnimationProgress($animationProgressTime)
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
                                        ForEach(viewModel.houseData!, id: \.self) { houseData in
                                            houseCellView(houseData: houseData, mainWindowSize: proxy.size)
                                        }
                                        .animation(.default, value: viewModel.houseData!)
                                        
                                        
                                    }
                                }.animation(.spring(), value: viewModel.houseData)
                                    .padding()
                                
                                
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
                    .animation(.easeInOut(duration: 0.25), value: viewModel.houseData == nil || animationProgressTime < 0.25)
                    .alert(isPresent: $viewModel.showToast, view: alertViewDeleted)
                    .alert(isPresent: $viewModel.showAddedToast, view: alertViewAdded)
//                    .popup(isPresented: $viewModel.showAlert) {
//                        if viewModel.houseToDelete.0 != nil && viewModel.houseToDelete.1 != nil {
//                            viewModel.alert()
//                                .frame(width: 400, height: 260)
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
//                    }
//                    .popup(isPresented: $viewModel.presentSheet) {
//
//                        .frame(width: 400, height: 260)
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
                    .onChange(of: viewModel.presentSheet) { value in
                        if value {
                            CentrePopup_AddHouse(viewModel: viewModel, address: address).showAndStack()
                        }
                    }
                    .navigationBarTitle("\(address.address)", displayMode: .automatic)
                    .navigationBarBackButtonHidden(true)
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
                                Button("", action: { viewModel.syncAnimation.toggle();  print("Syncing") ; viewModel.synchronizationManager.startupProcess(synchronizing: true) })
                                    .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $viewModel.dataStore.synchronized, lastTime: $viewModel.dataStore.lastTime))
                                
                                Menu {
                                    //                                if viewModel.isAdmin {
                                    //                                    Button {
                                    //                                        viewModel.optionsAnimation.toggle();  print("Add") ; viewModel.presentSheet.toggle()
                                    //                                    } label: {
                                    //                                        HStack {
                                    //                                            Image(systemName: "plus")
                                    //                                            Text("Add House")
                                    //                                        }
                                    //                                    }
                                    //                                }
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
                                    Button("", action: { viewModel.optionsAnimation.toggle();  print("Add") ; viewModel.presentSheet.toggle() })
                                        .buttonStyle(CircleButtonStyle(imageName: "ellipsis", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.optionsAnimation))
                                }
                                
                            }
                        }
                    }
                    .navigationTransition(viewModel.presentSheet ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
                    .navigationViewStyle(StackNavigationViewStyle())
                }.coordinateSpace(name: "scroll")
                    .scrollIndicators(.hidden)
                    .refreshable {
                        viewModel.synchronizationManager.startupProcess(synchronizing: true)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            hideFloatingButton = false
                        }
                    }
                if AuthorizationLevelManager().existsAdminCredentials() {
                    MainButton(imageName: "plus", colorHex: "#00b2f6", width: 60) {
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
    
    @ViewBuilder
    func houseCellView(houseData: HouseData, mainWindowSize: CGSize) -> some View {
        SwipeView {
            NavigationLink(destination: VisitsView(house: houseData.house).implementPopupView()) {
                HouseCell(house: houseData, mainWindowSize: mainWindowSize)
                    .padding(.bottom, 2)
            }
        } trailingActions: { context in
            if houseData.accessLevel == .Admin {
                SwipeAction(
                    systemImage: "trash",
                    backgroundColor: .red
                ) {
                    DispatchQueue.main.async {
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
    }
    
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup
            .horizontalPadding(24)
            .cornerRadius(15)
            .backgroundColour(Color(UIColor.systemGray6).opacity(85))
    }
}
