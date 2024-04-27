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
    
    var body: some View {
        ScrollView {
            ZStack {
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
                                        viewModel.houseCellView(houseData: houseData)
                                    }
                                    .animation(.default, value: viewModel.houseData!)
                                    
                                    
                                }
                            }.animation(.spring(), value: viewModel.houseData)
                                .padding()
                            
                            
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: viewModel.houseData == nil || animationProgressTime < 0.25)
                .alert(isPresent: $viewModel.showToast, view: alertViewDeleted)
                .alert(isPresent: $viewModel.showAddedToast, view: alertViewAdded)
                .popup(isPresented: $viewModel.showAlert) {
                    if viewModel.houseToDelete.0 != nil && viewModel.houseToDelete.1 != nil {
                        viewModel.alert()
                            .frame(width: 400, height: 260)
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
                    AddHouseView(house: viewModel.currentHouse, address: address, onDone: {
                        DispatchQueue.main.async {
                            viewModel.presentSheet = false
                            viewModel.synchronizationManager.startupProcess(synchronizing: true)
                            viewModel.getHouses()
                            viewModel.showAddedToast = true
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                viewModel.showAddedToast = false
                            }
                        }
                    }, onDismiss: {
                        viewModel.presentSheet = false
                    })
                    .frame(width: 400, height: 260)
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
            }
            //                .navigationDestination(isPresented: $viewModel.presentSheet) {
            //                    AddHouseView(house: viewModel.currentHouse, address: address) {
            //                        viewModel.synchronizationManager.startupProcess(synchronizing: true)
            //                        DispatchQueue.main.async {
            //                            viewModel.showAddedToast = true
            //                        }
            //                        
            //                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            //                            viewModel.showAddedToast = false
            //                        }
            //                    }
            //                }
            
            //.scrollIndicators(.hidden)
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
                        if viewModel.isAdmin {
                            Button("", action: { viewModel.optionsAnimation.toggle();  print("Add") ; viewModel.presentSheet.toggle() })
                                .buttonStyle(CircleButtonStyle(imageName: "plus", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.optionsAnimation))
                        }
                    }
                }
            }
            .navigationTransition(viewModel.presentSheet ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .refreshable {
            viewModel.synchronizationManager.startupProcess(synchronizing: true)
        }
        
    }
    
}


