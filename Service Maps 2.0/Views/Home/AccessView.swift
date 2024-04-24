//
//  AccessView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/7/23.
//

import SwiftUI
import NavigationTransitions
import SwipeActions
import Combine
import UIKit
import Lottie
import PopupView
import AlertKit

struct AccessView: View {
    @ObservedObject var viewModel = AccessViewModel()
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var databaseManager = RealmManager.shared
    
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    
    let alertViewDeleted = AlertAppleMusic17View(title: "Key Deleted", subtitle: nil, icon: .custom(UIImage(systemName: "trash")!))
    let alertViewAdded = AlertAppleMusic17View(title: "Key Added", subtitle: nil, icon: .done)
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    var body: some View {
        ScrollView {
            ZStack {
                VStack {
                    if viewModel.keyData == nil || viewModel.dataStore.synchronized == false {
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
                        if viewModel.keyData!.isEmpty {
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
                                    ForEach(viewModel.keyData!, id: \.self) { keyData in
                                        viewModel.keyCell(keyData: keyData)
                                    }
                                    .animation(.default, value: viewModel.keyData!)
                                }
                            }
                            .animation(.spring(), value: viewModel.keyData)
                            .padding()
                            
                            
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: viewModel.keyData == nil || animationProgressTime < 0.25)
                .alert(isPresent: $viewModel.showToast, view: alertViewDeleted)
                .alert(isPresent: $viewModel.showAddedToast, view: alertViewAdded)
                .popup(isPresented: $viewModel.showAlert) {
                    if viewModel.keyToDelete.0 != nil && viewModel.keyToDelete.1 != nil {
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
                AddKeyView {
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
            .navigationBarTitle("Keys", displayMode: .automatic)
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
