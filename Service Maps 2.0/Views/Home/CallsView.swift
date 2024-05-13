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
import MijickPopupView

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
    let minimumOffset: CGFloat = 60
    @Environment(\.mainWindowSize) var mainWindowSize
    var body: some View {
        ZStack {
            ScrollView {
                    VStack {
                        if viewModel.callsData == nil || viewModel.dataStore.synchronized == false {
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
                                            callCellView(callData: callData)
                                        }
                                        //.animation(.default, value: viewModel.callsData!)
                                    }
                                }.animation(.default, value: viewModel.callsData)
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
                    .animation(.easeInOut(duration: 0.25), value: viewModel.callsData == nil || viewModel.callsData != nil)
                    .alert(isPresent: $viewModel.showToast, view: alertViewDeleted)
                    .alert(isPresent: $viewModel.showAddedToast, view: alertViewAdded)
//                    .popup(isPresented: $viewModel.showAlert) {
//                        if viewModel.callToDelete != nil{
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
//                        AddCallView(call: viewModel.currentCall, phoneNumber: phoneNumber) {
//                            DispatchQueue.main.async {
//                                viewModel.presentSheet = false
//                                viewModel.synchronizationManager.startupProcess(synchronizing: true)
//                                viewModel.getCalls()
//                                viewModel.showAddedToast = true
//                                
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                                    viewModel.showAddedToast = false
//                                }
//                            }
//                        } onDismiss: {
//                            viewModel.presentSheet = false
//                        }
//                        .frame(width: 400, height: 300)
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
                            CentrePopup_AddCall(viewModel: viewModel, phoneNumber: phoneNumber).showAndStack()
                        }
                    }
                //.scrollIndicators(.hidden)
                .navigationBarTitle("Number: \(viewModel.phoneNumber.number)", displayMode: .large)
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
                            
//                            Button("", action: { viewModel.optionsAnimation.toggle();  print("Add") ; viewModel.presentSheet.toggle() })
//                                .buttonStyle(CircleButtonStyle(imageName: "plus", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.optionsAnimation))
                            
                        }
                    }
                }
                .navigationTransition(viewModel.presentSheet ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
                .navigationViewStyle(StackNavigationViewStyle())
            }.coordinateSpace(name: "scroll").searchable(text: $viewModel.search)
                .scrollIndicators(.hidden)
            .refreshable {
                viewModel.synchronizationManager.startupProcess(synchronizing: true)
            }
                    MainButton(imageName: "plus", colorHex: "#1e6794", width: 60) {
                        self.viewModel.presentSheet = true
                    }
                    .offset(y: hideFloatingButton ? 100 : -25)
                        .animation(.spring(), value: hideFloatingButton)
                        .vSpacing(.bottom).hSpacing(.trailing)
                        .padding()
                        .hoverEffect()
                        .keyboardShortcut("+", modifiers: .command)
                
        }
    }
    
    @ViewBuilder
    func callCellView(callData: PhoneCallData) -> some View {
        SwipeView {
            CallCell(call: callData)
                .padding(.bottom, 2)
                .contextMenu {
                    Button {
                        DispatchQueue.main.async {
                            self.viewModel.callToDelete = callData.phoneCall.id
                            CentrePopup_DeleteCall(viewModel: viewModel).showAndStack()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Visit")
                        }
                    }
                    
                    Button {
                        self.viewModel.currentCall = callData.phoneCall
                        self.viewModel.presentSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Visit")
                        }
                    }
                    //TODO Trash and Pencil only if admin
                }
        } trailingActions: { context in
            if callData.accessLevel == .Admin {
                SwipeAction(
                    systemImage: "trash",
                    backgroundColor: .red
                ) {
                    DispatchQueue.main.async {
                        self.viewModel.callToDelete = callData.phoneCall.id
                        CentrePopup_DeleteCall(viewModel: viewModel).showAndStack()
                    }
                }
                .font(.title.weight(.semibold))
                .foregroundColor(.white)
                
                
            }
            
            if callData.accessLevel == .Moderator || callData.accessLevel == .Admin {
                SwipeAction(
                    systemImage: "pencil",
                    backgroundColor: Color.teal
                ) {
                    self.viewModel.currentCall = callData.phoneCall
                    context.state.wrappedValue = .closed
                    
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
        .swipeMinimumDistance(callData.accessLevel != .User ? 25:1000)
        
    }
}

struct CentrePopup_DeleteCall: CentrePopup {
    @ObservedObject var viewModel: CallsViewModel
    
    
    func createContent() -> some View {
        ZStack {
            VStack {
                Text("Delete Call")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                    .padding(.leading)
                Text("Are you sure you want to delete the selected call?")
                    .font(.headline)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                    .padding(.leading)
                if viewModel.ifFailed {
                    Text("Error deleting call, please try again later")
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                //.vSpacing(.bottom)
                
                HStack {
                    if !viewModel.loading {
                        CustomBackButton() {
                            withAnimation {
                                dismiss()
                                self.viewModel.callToDelete = nil
                            }
                        }
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: viewModel.loading, title: "Delete", color: .red) {
                        withAnimation {
                            self.viewModel.loading = true
                        }
                        Task {
                            if self.viewModel.callToDelete != nil{
                                switch await self.viewModel.deleteCall(call: self.viewModel.callToDelete!) {
                                case .success(_):
                                    withAnimation {
                                        self.viewModel.synchronizationManager.startupProcess(synchronizing: true)
                                        self.viewModel.getCalls()
                                        self.viewModel.loading = false
                                        dismiss()
                                        self.viewModel.ifFailed = false
                                        self.viewModel.callToDelete = nil
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
struct CentrePopup_AddCall: CentrePopup {
    @ObservedObject var viewModel: CallsViewModel
    @State var phoneNumber: PhoneNumberModel
    
    
    func createContent() -> some View {
        AddCallView(call: viewModel.currentCall, phoneNumber: phoneNumber) {
            DispatchQueue.main.async {
                viewModel.presentSheet = false
                dismiss()
                viewModel.synchronizationManager.startupProcess(synchronizing: true)
                viewModel.getCalls()
                viewModel.showAddedToast = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    viewModel.showAddedToast = false
                }
            }
        } onDismiss: {
            viewModel.presentSheet = false
            dismiss()
        }
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
