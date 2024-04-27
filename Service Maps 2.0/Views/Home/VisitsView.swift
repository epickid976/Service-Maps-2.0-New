//
//  VisitsView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/5/23.
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


struct VisitsView: View {
    
    @StateObject var viewModel: VisitsViewModel
    var house: HouseModel
    
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    @State var showFab = true
    @State var scrollOffset: CGFloat = 0.00
    @State private var isScrollingDown = false
    
    init(house: HouseModel) {
        self.house = house
        let initialViewModel = VisitsViewModel(house: house)
        _viewModel = StateObject(wrappedValue: initialViewModel)
    }
    
    let alertViewDeleted = AlertAppleMusic17View(title: "Visit Deleted", subtitle: nil, icon: .custom(UIImage(systemName: "trash")!))
    let alertViewAdded = AlertAppleMusic17View(title: "Visit Added", subtitle: nil, icon: .done)
    
    var body: some View {
        ScrollView {
            ZStack {
                VStack {
                    if viewModel.visitData == nil || viewModel.dataStore.synchronized == false {
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
                        if viewModel.visitData!.isEmpty {
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
                                    ForEach(viewModel.visitData!, id: \.self) { visitData in
                                        viewModel.visitCellView(visitData: visitData)
                                    }
                                    .animation(.default, value: viewModel.visitData!)
                                    
                                    
                                }
                            }.animation(.spring(), value: viewModel.visitData)
                                .padding()
                            
                            
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: viewModel.visitData == nil || animationProgressTime < 0.25)
                .alert(isPresent: $viewModel.showToast, view: alertViewDeleted)
                .alert(isPresent: $viewModel.showAddedToast, view: alertViewAdded)
                .popup(isPresented: $viewModel.showAlert) {
                    if viewModel.visitToDelete != nil{
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
                    AddVisitView(visit: viewModel.currentVisit, house: house) {
                        DispatchQueue.main.async {
                            viewModel.presentSheet = false
                            viewModel.synchronizationManager.startupProcess(synchronizing: true)
                            viewModel.getVisits()
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
            }
            //.scrollIndicators(.hidden)
            .navigationBarTitle("House: \(viewModel.house.number)", displayMode: .automatic)
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



//#Preview {
//    VisitsView()
//}
