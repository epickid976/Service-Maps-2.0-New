//
//  CallsView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 5/1/24.
//

import SwiftUI
import CoreData
import NavigationTransitions
import SwipeActions
import Combine
import UIKit
import Lottie
import AlertKit
import PopupView

struct CallsView: View {
    @StateObject var viewModel: CallsViewModel
    var phoneNumber: PhoneNumberModel
    
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    @State var showFab = true
    @State var scrollOffset: CGFloat = 0.00
    @State private var isScrollingDown = false
    
    init(phoneNumber: PhoneNumberModel) {
        self.phoneNumber = phoneNumber
        let initialViewModel = CallsViewModel(phoneNumber: phoneNumber)
        _viewModel = StateObject(wrappedValue: initialViewModel)
    }
    
    let alertViewDeleted = AlertAppleMusic17View(title: "Visit Deleted", subtitle: nil, icon: .custom(UIImage(systemName: "trash")!))
    let alertViewAdded = AlertAppleMusic17View(title: "Visit Added", subtitle: nil, icon: .done)
    
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    let minimumOffset: CGFloat = 40
    
    var body: some View {
        ZStack {
            ScrollView {
                    VStack {
                        if viewModel.callsData == nil || viewModel.dataStore.synchronized == false {
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
                            if viewModel.callsData!.isEmpty {
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
                                        ForEach(viewModel.callsData!, id: \.self) { callData in
                                            viewModel.callCellView(callData: callData)
                                        }
                                        .animation(.default, value: viewModel.callsData!)
                                    }
                                }.animation(.spring(), value: viewModel.callsData)
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
                    .animation(.easeInOut(duration: 0.25), value: viewModel.callsData == nil || animationProgressTime < 0.25)
                    .alert(isPresent: $viewModel.showToast, view: alertViewDeleted)
                    .alert(isPresent: $viewModel.showAddedToast, view: alertViewAdded)
                    .popup(isPresented: $viewModel.showAlert) {
                        if viewModel.callToDelete != nil{
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
                        AddCallView(call: viewModel.currentCall, phoneNumber: phoneNumber) {
                            DispatchQueue.main.async {
                                viewModel.presentSheet = false
                                viewModel.synchronizationManager.startupProcess(synchronizing: true)
                                viewModel.getCalls()
                                viewModel.showAddedToast = true
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    viewModel.showAddedToast = false
                                }
                            }
                        } onDismiss: {
                            viewModel.presentSheet = false
                        }
                        .frame(width: 400, height: 300)
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
                
                //.scrollIndicators(.hidden)
                .navigationBarTitle("Number: \(viewModel.phoneNumber.number)", displayMode: .automatic)
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
                            
//                            Button("", action: { viewModel.optionsAnimation.toggle();  print("Add") ; viewModel.presentSheet.toggle() })
//                                .buttonStyle(CircleButtonStyle(imageName: "plus", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.optionsAnimation))
                            
                        }
                    }
                }
                .navigationTransition(viewModel.presentSheet ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
                .navigationViewStyle(StackNavigationViewStyle())
            }.coordinateSpace(name: "scroll")
            .refreshable {
                viewModel.synchronizationManager.startupProcess(synchronizing: true)
            }
                    MainButton(imageName: "plus", colorHex: "#00b2f6", width: 60) {
                        self.viewModel.presentSheet = true
                    }
                    .offset(y: hideFloatingButton ? 100 : -25)
                        .animation(.spring(), value: hideFloatingButton)
                        .vSpacing(.bottom).hSpacing(.trailing)
                        .padding()
                
        }
    }
}
