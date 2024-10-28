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
import MijickPopups

struct CallsView: View {
    @StateObject var viewModel: CallsViewModel
    var phoneNumber: PhoneNumber
    @StateObject var realtimeManager = RealtimeManager.shared
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    @State var showFab = true
    @State var scrollOffset: CGFloat = 0.00
    @State private var isScrollingDown = false
    
    init(phoneNumber: PhoneNumber, callToScrollTo: String? = nil) {
        self.phoneNumber = phoneNumber
        let initialViewModel = CallsViewModel(phoneNumber: phoneNumber, callToScrollTo: callToScrollTo)
        _viewModel = StateObject(wrappedValue: initialViewModel)
    }
    
    let alertViewDeleted = AlertAppleMusic17View(title: "Call Deleted", subtitle: nil, icon: .custom(UIImage(systemName: "trash")!))
    let alertViewAdded = AlertAppleMusic17View(title: "Call Added", subtitle: nil, icon: .done)
    
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    let minimumOffset: CGFloat = 60
    @Environment(\.mainWindowSize) var mainWindowSize
    
    @State var highlightedCallId: String?
    
    @ObservedObject var preferencesViewModel = ColumnViewModel()
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ScrollViewReader { scrollViewProxy in
                    ScrollView {
                        VStack {
                            if viewModel.callsData == nil && viewModel.dataStore.synchronized == false {
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
                                if let data = viewModel.callsData {
                                    if data.isEmpty {
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
                                        
                                        //LazyVStack {
                                        SwipeViewGroup {
                                            if UIDevice().userInterfaceIdiom == .pad && proxy.size.width > 400 && preferencesViewModel.isColumnViewEnabled {
                                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                                    ForEach(viewModel.callsData!, id: \.phoneCall.id) { callData in
                                                        callCellView(callData: callData).id(callData.phoneCall.id)
                                                            .modifier(ScrollTransitionModifier())
                                                            .transition(.customBackInsertion)
                                                    }.modifier(ScrollTransitionModifier())
                                                }
                                            } else {
                                                LazyVGrid(columns: [GridItem(.flexible())]) {
                                                    ForEach(viewModel.callsData!, id: \.phoneCall.id) { callData in
                                                        callCellView(callData: callData).id(callData.phoneCall.id)
                                                            .modifier(ScrollTransitionModifier())
                                                            .transition(.customBackInsertion)
                                                    }.modifier(ScrollTransitionModifier())
                                                }
                                            }
                                            //.animation(.default, value: viewModel.callsData!)
                                        }.animation(.spring(), value: viewModel.callsData!)
                                            .padding()
                                        
                                        
                                    }
                                }
                            }
                        }.background(GeometryReader {
                            Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                        }).onPreferenceChange(ViewOffsetKey.self) { currentOffset in
                            let offsetDifference: CGFloat = self.previousViewOffset - currentOffset
                            if ( abs(offsetDifference) > minimumOffset) {
                                if offsetDifference > 0 {
                                    
                                    hideFloatingButton = false
                                } else {
                                    
                                    hideFloatingButton = true
                                }
                                self.previousViewOffset = currentOffset
                            }
                        }
                        .animation(.easeInOut(duration: 0.25), value: viewModel.callsData == nil || viewModel.callsData != nil)
                        .alert(isPresent: $viewModel.showToast, view: alertViewDeleted)
                        .alert(isPresent: $viewModel.showAddedToast, view: alertViewAdded)
                        .onChange(of: viewModel.presentSheet) { value in
                            if value {
                                CentrePopup_AddCall(viewModel: viewModel, phoneNumber: phoneNumber).present()
                            }
                        }
                        //.scrollIndicators(.never)
                        .navigationBarTitle(" \(viewModel.phoneNumber.number.formatPhoneNumber())", displayMode: .large)
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarLeading) {
                                HStack {
                                    Button("", action: {withAnimation { viewModel.backAnimation.toggle(); HapticManager.shared.trigger(.lightImpact) };
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            dismissAllPopups()
                                            presentationMode.wrappedValue.dismiss()
                                        }
                                    })//.keyboardShortcut(.delete, modifiers: .command)
                                        .buttonStyle(CircleButtonStyle(imageName: "arrow.backward", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.backAnimation))
                                }
                            }
                            ToolbarItemGroup(placement: .topBarTrailing) {
                                HStack {
                                    Button("", action: { viewModel.syncAnimation.toggle(); synchronizationManager.startupProcess(synchronizing: true) })//.keyboardShortcut("s", modifiers: .command)
                                        .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $viewModel.dataStore.synchronized, lastTime: $viewModel.dataStore.lastTime))
                                    
                                    //                            Button("", action: { viewModel.optionsAnimation.toggle();   ; viewModel.presentSheet.toggle() })
                                    //                                .buttonStyle(CircleButtonStyle(imageName: "plus", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.optionsAnimation))
                                    
                                }
                            }
                        }
                        .navigationTransition(viewModel.presentSheet || viewModel.callToScrollTo != nil ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
                        .navigationViewStyle(StackNavigationViewStyle())
                    }.coordinateSpace(name: "scroll")
                        .scrollIndicators(.never)
                        .refreshable {
                            viewModel.synchronizationManager.startupProcess(synchronizing: true)
                        }
//                        .onChange(of: viewModel.dataStore.synchronized) { value in
//                            if value {
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                                    viewModel.getCalls()
//                                }
//                            }
//                        }
//                        .onChange(of: realtimeManager.lastMessage) { value in
//                            if value != nil {
//                                viewModel.getCalls()
//                            }
//                            
//                        }
                        .onChange(of: viewModel.callToScrollTo) { id in
                            if let id = id {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        scrollViewProxy.scrollTo(id, anchor: .center)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            HapticManager.shared.trigger(.selectionChanged)
                                            highlightedCallId = id // Highlight after scrolling
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            highlightedCallId = nil
                                        }
                                    }
                                }
                                
                            }
                        }
                }
                MainButton(imageName: "plus", colorHex: "#1e6794", width: 60) {
                    self.viewModel.presentSheet = true
                }
                .offset(y: hideFloatingButton ? 100 : -25)
                .animation(.spring(), value: hideFloatingButton)
                .vSpacing(.bottom).hSpacing(.trailing)
                .padding()
                //.keyboardShortcut("+", modifiers: .command)
                
            }
        }
    }
    
    @ViewBuilder
    func callCellView(callData: PhoneCallData) -> some View {
        SwipeView {
            CallCell(call: callData, ipad: UIDevice().userInterfaceIdiom == .pad)
                .overlay(
                    RoundedRectangle(cornerRadius: 16) // Same shape as the cell
                        .fill(highlightedCallId == callData.phoneCall.id ? Color.gray.opacity(0.5) : Color.clear).animation(.default, value: highlightedCallId == callData.phoneCall.id) // Fill with transparent gray if highlighted
                )
                .padding(.bottom, 2)
                .contextMenu {
                    Button {
                        HapticManager.shared.trigger(.lightImpact)
                        DispatchQueue.main.async {
                            self.viewModel.callToDelete = callData.phoneCall.id
                            CentrePopup_DeleteCall(viewModel: viewModel).present()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Visit")
                        }
                    }
                    
                    Button {
                        HapticManager.shared.trigger(.lightImpact)
                        self.viewModel.currentCall = callData.phoneCall
                        self.viewModel.presentSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Visit")
                        }
                    }
                    //TODO Trash and Pencil only if admin
                }.clipShape(RoundedRectangle(cornerRadius: 16, style: .circular))
        } trailingActions: { context in
            if callData.accessLevel == .Admin {
                SwipeAction(
                    systemImage: "trash",
                    backgroundColor: .red
                ) {
                    HapticManager.shared.trigger(.lightImpact)
                    context.state.wrappedValue = .closed
                    DispatchQueue.main.async {
                        self.viewModel.callToDelete = callData.phoneCall.id
                        CentrePopup_DeleteCall(viewModel: viewModel).present()
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
                    HapticManager.shared.trigger(.lightImpact)
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
    
    var body: some View {
        createContent()
    }
    
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
                            HapticManager.shared.trigger(.lightImpact)
                            withAnimation {
                                dismissLastPopup()
                                self.viewModel.callToDelete = nil
                            }
                        }
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: viewModel.loading, title: NSLocalizedString("Delete", comment: ""), color: .red) {
                        HapticManager.shared.trigger(.lightImpact)
                        withAnimation {
                            self.viewModel.loading = true
                        }
                        Task {
                            if self.viewModel.callToDelete != nil{
                                switch await self.viewModel.deleteCall(call: self.viewModel.callToDelete!) {
                                case .success(_):
                                    HapticManager.shared.trigger(.success)
                                    withAnimation {
                                        //self.viewModel.synchronizationManager.startupProcess(synchronizing: true)
                                        self.viewModel.loading = false
                                        dismissLastPopup()
                                        self.viewModel.ifFailed = false
                                        self.viewModel.callToDelete = nil
                                        self.viewModel.showToast = true
                                    }
                                case .failure(_):
                                    HapticManager.shared.trigger(.error)
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
    
    func configurePopup(config: CentrePopupConfig) -> CentrePopupConfig {
        config
            .popupHorizontalPadding(24)
            
            
    }
}
struct CentrePopup_AddCall: CentrePopup {
    @ObservedObject var viewModel: CallsViewModel
    @State var phoneNumber: PhoneNumber
    
    var body: some View {
        createContent()
    }
    
    func createContent() -> some View {
        AddCallView(call: viewModel.currentCall, phoneNumber: phoneNumber) {
            DispatchQueue.main.async {
                viewModel.presentSheet = false
                dismissLastPopup()
                viewModel.showAddedToast = true
                
            }
        } onDismiss: {
            viewModel.presentSheet = false
            dismissLastPopup()
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
    
    func configurePopup(config: CentrePopupConfig) -> CentrePopupConfig {
        config
            .popupHorizontalPadding(24)
            
            
    }
}
