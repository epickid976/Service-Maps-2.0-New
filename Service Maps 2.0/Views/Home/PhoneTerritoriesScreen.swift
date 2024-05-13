//
//  PhoneTerritoriesScreen.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/30/24.
//

import SwiftUI
import NavigationTransitions
import SwipeActions
import Combine
import UIKit
import Lottie
import PopupView
import AlertKit
import Nuke
import MijickPopupView

struct PhoneTerritoriesScreen: View {
    @ObservedObject var viewModel = PhoneScreenViewModel()
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    @Environment(\.presentationMode) var presentationMode
    
    let alertViewDeleted = AlertAppleMusic17View(title: "Territory Deleted", subtitle: nil, icon: .custom(UIImage(systemName: "trash")!))
    let alertViewAdded = AlertAppleMusic17View(title: "Territory Added", subtitle: nil, icon: .done)
    
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    let minimumOffset: CGFloat = 60
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ScrollView {
                    VStack {
                        if viewModel.phoneData == nil || viewModel.dataStore.synchronized == false {
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
                            if viewModel.phoneData!.isEmpty {
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
                                        ForEach(viewModel.phoneData!, id: \.self) { phoneData in
                                            territoryCell(phoneData: phoneData, mainViewSize: proxy.size)
                                        }
                                        //.animation(.default, value: viewModel.phoneData!)
                                        
                                        
                                    }
                                }.animation(.spring(), value: viewModel.phoneData)
                                
                                
                                
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
                    .animation(.easeInOut(duration: 0.25), value: viewModel.phoneData == nil || viewModel.phoneData != nil)
                    .alert(isPresent: $viewModel.showToast, view: alertViewDeleted)
                    .alert(isPresent: $viewModel.showAddedToast, view: alertViewAdded)
                    //                    .popup(isPresented: $viewModel.showAlert) {
                    //                        if viewModel.territoryToDelete.0 != nil && viewModel.territoryToDelete.1 != nil {
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
                    //                    }
                    
                    .navigationDestination(isPresented: $viewModel.presentSheet) {
                        AddPhoneTerritoryView(territory: viewModel.currentTerritory) {
                            synchronizationManager.startupProcess(synchronizing: true)
                            DispatchQueue.main.async {
                                viewModel.showAddedToast = true
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                viewModel.showAddedToast = false
                            }
                        }
                    }
                    
                    //.scrollIndicators(.hidden)
                    .navigationBarTitle("Phone Territories", displayMode: .automatic)
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            HStack {
                                Button("", action: { viewModel.syncAnimation.toggle();  print("Syncing") ; synchronizationManager.startupProcess(synchronizing: true) }).keyboardShortcut("s", modifiers: .command)
                                    .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $viewModel.dataStore.synchronized, lastTime: $viewModel.dataStore.lastTime))
                                //                            if viewModel.isAdmin {
                                //                                Button("", action: { viewModel.optionsAnimation.toggle();  print("Add") ; viewModel.presentSheet.toggle() })
                                //                                    .buttonStyle(CircleButtonStyle(imageName: "plus", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.optionsAnimation))
                                //                            }
                            }
                        }
                    }
                    .navigationTransition(viewModel.presentSheet ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
                    .navigationViewStyle(StackNavigationViewStyle())
                }.coordinateSpace(name: "scroll").searchable(text: $viewModel.search, placement: .navigationBarDrawer)
                    .scrollIndicators(.hidden)
                    .refreshable {
                        synchronizationManager.startupProcess(synchronizing: true)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            hideFloatingButton = false
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
                    .hoverEffect()
                    .keyboardShortcut("+", modifiers: .command)
                }
            }
        }
    }
    
    @ViewBuilder
    func territoryCell(phoneData: PhoneData, mainViewSize: CGSize) -> some View {
        LazyVStack {
        SwipeView {
            NavigationLink(destination: PhoneNumbersView(territory: phoneData.territory).implementPopupView()) {
                PhoneTerritoryCellView(territory: phoneData.territory, numbers: phoneData.numbersQuantity, mainWindowSize: mainViewSize)
                    .padding(.bottom, 2)
                    .contextMenu {
                        Button {
                            DispatchQueue.main.async {
                                self.viewModel.territoryToDelete = (String(phoneData.territory.id), String(phoneData.territory.number))
                                CentrePopup_DeletePhoneTerritory(viewModel: viewModel).showAndStack()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Visit")
                            }
                        }
                        
                        Button {
                            self.viewModel.currentTerritory = phoneData.territory
                            self.viewModel.presentSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit Visit")
                            }
                        }
                        //TODO Trash and Pencil only if admin
                    }
            }
        } trailingActions: { context in
            if self.viewModel.isAdmin {
                SwipeAction(
                    systemImage: "trash",
                    backgroundColor: .red
                ) {
                    DispatchQueue.main.async {
                        self.viewModel.territoryToDelete = (String(phoneData.territory.id), String(phoneData.territory.number))
                        CentrePopup_DeletePhoneTerritory(viewModel: viewModel).showAndStack()
                    }
                }
                .font(.title.weight(.semibold))
                .foregroundColor(.white)
                
                SwipeAction(
                    systemImage: "pencil",
                    backgroundColor: Color.teal
                ) {
                    context.state.wrappedValue = .closed
                    self.viewModel.currentTerritory = phoneData.territory
                    self.viewModel.presentSheet = true
                }
                .allowSwipeToTrigger()
                .font(.title.weight(.semibold))
                .foregroundColor(.white)
            }
        }
        .swipeActionCornerRadius(16)
        .swipeSpacing(5)
        .swipeOffsetCloseAnimation(stiffness: 500, damping: 100)
        .swipeOffsetExpandAnimation(stiffness: 500, damping: 100)
        .swipeOffsetTriggerAnimation(stiffness: 500, damping: 100)
        .swipeMinimumDistance(viewModel.isAdmin ? 25:1000)
        }.padding(.horizontal, 15)
    }
}
struct CentrePopup_DeletePhoneTerritory: CentrePopup {
    @ObservedObject var viewModel: PhoneScreenViewModel
    
    
    func createContent() -> some View {
        ZStack {
            VStack {
                Text("Delete Territory \(viewModel.territoryToDelete.1 ?? "0")")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                    .padding(.leading)
                Text("Are you sure you want to delete the selected territory?")
                    .font(.headline)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                    .padding(.leading)
                if viewModel.ifFailed {
                    Text("Error deleting territory, please try again later")
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
                                self.viewModel.territoryToDelete = (nil,nil)
                            }
                        }
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: viewModel.loading, title: "Delete", color: .red) {
                        withAnimation {
                            self.viewModel.loading = true
                        }
                        Task {
                            if self.viewModel.territoryToDelete.0 != nil && self.viewModel.territoryToDelete.1 != nil {
                                switch await self.viewModel.deleteTerritory(territory: self.viewModel.territoryToDelete.0 ?? "") {
                                case .success(_):
                                    withAnimation {
                                        withAnimation {
                                            self.viewModel.loading = false
                                        }
                                        dismiss()
                                        self.viewModel.territoryToDelete = (nil,nil)
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
                //.vSpacing(.bottom)
                
            }
            .ignoresSafeArea(.keyboard)
            
        }.ignoresSafeArea(.keyboard)
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
