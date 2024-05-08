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
    let minimumOffset: CGFloat = 40
    @Environment(\.mainWindowSize) var mainWindowSize
    var body: some View {
        ZStack {
            ScrollView {
                    VStack {
                        if viewModel.phoneData == nil || viewModel.dataStore.synchronized == false {
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
                                            viewModel.territoryCell(phoneData: phoneData)
                                        }
                                        .animation(.default, value: viewModel.phoneData!)
                                        
                                        
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
                    .animation(.easeInOut(duration: 0.25), value: viewModel.phoneData == nil || animationProgressTime < 0.25)
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
                            Button("", action: { viewModel.syncAnimation.toggle();  print("Syncing") ; synchronizationManager.startupProcess(synchronizing: true) })
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
            }.coordinateSpace(name: "scroll")
                .scrollIndicators(.hidden)
            .refreshable {
                synchronizationManager.startupProcess(synchronizing: true)
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
