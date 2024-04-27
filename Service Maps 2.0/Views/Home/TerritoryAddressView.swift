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
    
    var body: some View {
        ZStack {
            ScalingHeaderScrollView {
                ZStack {
                    Color(UIColor.secondarySystemBackground).ignoresSafeArea(.all)
                    viewModel.largeHeader(progress: viewModel.progress)
                    
                    
                }
            } content: {
                VStack {
                    if viewModel.addressData == nil || viewModel.dataStore.synchronized == false {
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
                                        SwipeView {
                                            NavigationLink(destination: HousesView(address: addressData.address)) {
                                                viewModel.addressCell(addressData: addressData)
                                                    .padding(.bottom, 2)
                                            }
                                            
                                        } trailingActions: { context in
                                            if addressData.accessLevel == .Admin {
                                                SwipeAction(
                                                    systemImage: "trash",
                                                    backgroundColor: .red
                                                ) {
                                                    DispatchQueue.main.async {
                                                        self.viewModel.addressToDelete = (addressData.address.id, String(addressData.address.address))
                                                        self.viewModel.showAlert = true
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
                                                    viewModel.currentAddress = addressData.address
                                                    viewModel.presentSheet = true
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
                                        .swipeMinimumDistance(addressData.accessLevel != .User ? 25:1000)
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
                .alert(isPresent: $viewModel.showToast, view: alertViewDeleted)
                .alert(isPresent: $viewModel.showAddedToast, view: alertViewAdded)
                .popup(isPresented: $viewModel.showAlert) {
                    if viewModel.addressToDelete.0 != nil && viewModel.addressToDelete.1 != nil {
                        viewModel.alert()
                            .frame(width: 400, height: 230)
                            .background(Material.thin).cornerRadius(16, corners: .allCorners)
                    }
                } customize: {
                    $0
                        .type(.default)
                        .closeOnTapOutside(false)
                        .dragToDismiss(false)
                        .isOpaque(true)
                        .animation(.spring())
                        .closeOnTap(false)
                        .backgroundColor(.black.opacity(0.8))
                }
                .popup(isPresented: $viewModel.presentSheet) {
                    AddAddressView(territory: territory, address: viewModel.currentAddress, onDone: {
                        DispatchQueue.main.async {
                            viewModel.presentSheet = false
                            synchronizationManager.startupProcess(synchronizing: true)
                            viewModel.getAddresses()
                            viewModel.showAddedToast = true
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                viewModel.showAddedToast = false
                            }
                        }
                    }, onDismiss: {
                        viewModel.presentSheet = false
                    })
                    .frame(width: 400, height: 230)
                    .background(Material.thin).cornerRadius(16, corners: .allCorners)
                } customize: {
                    $0
                        .type(.default)
                        .closeOnTapOutside(false)
                        .dragToDismiss(false)
                        .isOpaque(true)
                        .animation(.spring())
                        .closeOnTap(false)
                        .backgroundColor(.black.opacity(0.8))
                }
                .animation(.easeInOut(duration: 0.25), value: viewModel.addressData == nil || animationProgressTime < 0.25)
            }
            .height(min: 180, max: 350.0)
            //.allowsHeaderCollapse()
            .allowsHeaderGrowth()
            //.headerIsClipped()
            //.scrollOffset($scrollOffset)
            .collapseProgress($viewModel.progress)
            .scrollIndicators(.hidden)
            //            .navigationDestination(isPresented: $viewModel.presentSheet) {
            //                
            //            }
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
                    if viewModel.isAdmin {
                        Button("", action: { viewModel.optionsAnimation.toggle();  print("Add") ; viewModel.presentSheet.toggle() })
                            .buttonStyle(CircleButtonStyle(imageName: "plus", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.optionsAnimation))
                    }
                }
            }
        }
        .navigationTransition(viewModel.presentSheet ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
    }
    
    
}
