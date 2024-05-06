//
//  Territory View.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/4/23.
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

struct TerritoryView: View {
    
    
    @ObservedObject var viewModel = TerritoryViewModel()
    
    //@Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    @Environment(\.presentationMode) var presentationMode
    
    init() {
        
    }
    
    let alertViewDeleted = AlertAppleMusic17View(title: "Territory Deleted", subtitle: nil, icon: .custom(UIImage(systemName: "trash")!))
    let alertViewAdded = AlertAppleMusic17View(title: "Territory Added", subtitle: nil, icon: .done)
    
    var body: some View {
        ScrollView {
            ZStack {
                VStack {
                    if viewModel.territoryData == nil || viewModel.dataStore.synchronized == false {
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
                        if viewModel.territoryData!.isEmpty {
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
                                    ForEach(viewModel.territoryData!, id: \.self) { dataWithKeys in
                                        viewModel.territoryCell(dataWithKeys: dataWithKeys)
                                    }
                                    .animation(.default, value: viewModel.territoryData!)
                                    
                                    
                                }
                            }.animation(.spring(), value: viewModel.territoryData)
                            
                            
                            
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: viewModel.territoryData == nil || animationProgressTime < 0.25)
                .alert(isPresent: $viewModel.showToast, view: alertViewDeleted)
                .alert(isPresent: $viewModel.showAddedToast, view: alertViewAdded)
                .popup(isPresented: $viewModel.showAlert) {
                    if viewModel.territoryToDelete.0 != nil && viewModel.territoryToDelete.1 != nil {
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
            }
            .navigationDestination(isPresented: $viewModel.presentSheet) {
                AddTerritoryView(territory: viewModel.currentTerritory) {
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
            .navigationBarTitle("Territories", displayMode: .automatic)
            .navigationBarBackButtonHidden(true)
            .toolbar {
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
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .refreshable {
            synchronizationManager.startupProcess(synchronizing: true)
        }
    }
}
