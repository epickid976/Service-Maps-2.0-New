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
import Toasts

//MARK: - CallsView

struct CallsView: View {
    
    //MARK: - Environment
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.presentToast) var presentToast
    @Environment(\.mainWindowSize) var mainWindowSize
    
    //MARK: - Dependencies
    
    @StateObject var viewModel: CallsViewModel
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var preferencesViewModel = ColumnViewModel()
    
    //MARK: - Properties
    
    var phoneNumber: PhoneNumber
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    @State var showFab = true
    @State var scrollOffset: CGFloat = 0.00
    @State private var isScrollingDown = false
    
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    let minimumOffset: CGFloat = 60
    
    
    @State var highlightedCallId: String?
    
    //MARK: - Initializers
    
    init(phoneNumber: PhoneNumber, callToScrollTo: String? = nil) {
        self.phoneNumber = phoneNumber
        let initialViewModel = CallsViewModel(phoneNumber: phoneNumber, callToScrollTo: callToScrollTo)
        _viewModel = StateObject(wrappedValue: initialViewModel)
    }
    
    //MARK: - Body
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ScrollViewReader { scrollViewProxy in
                    ScrollView {
                        LazyVStack {
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
                        }
                        .background(GeometryReader {
                            Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                        }).onPreferenceChange(ViewOffsetKey.self) { currentOffset in
                            Task { @MainActor in
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
                        }
                        .animation(.easeInOut(duration: 0.25), value: viewModel.callsData == nil || viewModel.callsData != nil)
                        .onChange(of: viewModel.presentSheet) { value in
                            if value {
                                Task {
                                    await CenterPopup_AddCall(viewModel: viewModel, phoneNumber: phoneNumber){
                                        let toast = ToastValue(
                                            icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green),
                                            message: "Call Added"
                                        )
                                        presentToast(toast)
                                    }.present()
                                }
                            }
                        }
                        //.scrollIndicators(.never)
                        .navigationBarTitle(" \(viewModel.phoneNumber.number.formatPhoneNumber())", displayMode: .large)
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarLeading) {
                                if #available(iOS 26.0, *) {
                                    Button(action: {
                                        withAnimation { viewModel.backAnimation.toggle(); HapticManager.shared.trigger(.lightImpact) }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            Task {
                                                await dismissAllPopups()
                                            }
                                            presentationMode.wrappedValue.dismiss()
                                        }
                                    }) {
                                        Image(systemName: "arrow.backward")
                                    }
                                } else {
                                    HStack {
                                        Button("", action: {withAnimation { viewModel.backAnimation.toggle(); HapticManager.shared.trigger(.lightImpact) };
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                Task {
                                                    await dismissAllPopups()
                                                }
                                                presentationMode.wrappedValue.dismiss()
                                            }
                                        })
                                        .buttonStyle(CircleButtonStyle(imageName: "arrow.backward", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.backAnimation))
                                    }
                                }
                            }
                            ToolbarItemGroup(placement: .topBarTrailing) {
                                if #available(iOS 26.0, *) {
                                    SyncPillButton(
                                        synced: viewModel.dataStore.synchronized,
                                        lastTime: viewModel.dataStore.lastTime
                                    ) {
                                        HapticManager.shared.trigger(.lightImpact)
                                        synchronizationManager.startupProcess(synchronizing: true)
                                    }
                                } else {
                                    HStack {
                                        Button("", action: { viewModel.syncAnimation = true; synchronizationManager.startupProcess(synchronizing: true) })
                                            .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $viewModel.dataStore.synchronized, lastTime: $viewModel.dataStore.lastTime))
                                    }
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
                .offset(y: -25)
                .fabImplode(isHidden: hideFloatingButton)
                .vSpacing(.bottom).hSpacing(.trailing)
                .padding()
            }
        }
    }
    
    //MARK: - Call Cell
    
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
                            Task {
                                await  CenterPopup_DeleteCall(viewModel: viewModel){
                                    let toast = ToastValue(
                                        icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.red),
                                        message: "Call Deleted"
                                    )
                                    presentToast(toast)
                                }.present()
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Call")
                        }
                    }
                    
                    Button {
                        HapticManager.shared.trigger(.lightImpact)
                        self.viewModel.currentCall = callData.phoneCall
                        self.viewModel.presentSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Call")
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
                        Task {
                            await CenterPopup_DeleteCall(viewModel: viewModel){
                                let toast = ToastValue(
                                    icon: Image(systemName: "checkmark.circle.fill"),
                                    message: "Call Deleted"
                                )
                                presentToast(toast)
                            }.present()
                        }
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

//MARK: - Add Call Popup

struct CenterPopup_AddCall: CenterPopup {
    @ObservedObject var viewModel: CallsViewModel
    var phoneNumber: PhoneNumber
    var onDone: () -> Void

    init(viewModel: CallsViewModel, phoneNumber: PhoneNumber, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.phoneNumber = phoneNumber
        self.onDone = onDone
    }

    var body: some View {
        createContent()
    }

    func createContent() -> some View {
        AddCallView(call: viewModel.currentCall, phoneNumber: phoneNumber) {
            viewModel.presentSheet = false
            Task { await dismissLastPopup() }
            onDone()
        } onDismiss: {
            viewModel.presentSheet = false
            Task { await dismissLastPopup() }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(Material.thin)
        .cornerRadius(15)
        .simultaneousGesture(
            DragGesture().onChanged { _ in
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }

    func configurePopup(config: CenterPopupConfig) -> CenterPopupConfig {
        config.popupHorizontalPadding(24)
    }
}

//MARK: - Delete Call Popup

struct CenterPopup_DeleteCall: CenterPopup {
    @ObservedObject var viewModel: CallsViewModel
    var onDone: () -> Void

    init(viewModel: CallsViewModel, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDone = onDone
        self.viewModel.loading = false
    }

    var body: some View {
        createContent()
    }

    func createContent() -> some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: "phone.down.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundColor(.red)

            // Title
            Text("Delete Call")
                .font(.title3)
                .fontWeight(.heavy)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            // Message
            Text("Are you sure you want to delete the selected call?")
                .font(.headline)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            // Error
            if viewModel.ifFailed {
                Text("Error deleting call, please try again later")
                    .font(.footnote)
                    .foregroundColor(.red)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
            }

            // Buttons
            HStack(spacing: 12) {
                if !viewModel.loading {
                    CustomBackButton(showImage: true, text: NSLocalizedString("Cancel", comment: "")) {
                        HapticManager.shared.trigger(.lightImpact)
                        withAnimation {
                            self.viewModel.callToDelete = nil
                        }
                        Task {
                            await dismissLastPopup()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                CustomButton(
                    loading: viewModel.loading,
                    title: NSLocalizedString("Delete", comment: ""),
                    color: .red
                ) {
                    HapticManager.shared.trigger(.lightImpact)
                    withAnimation { viewModel.loading = true }

                    Task {
                        if let callId = viewModel.callToDelete {
                            switch await viewModel.deleteCall(call: callId) {
                            case .success:
                                HapticManager.shared.trigger(.success)
                                withAnimation {
                                    viewModel.callToDelete = nil
                                    viewModel.ifFailed = false
                                }
                                onDone()
                                await dismissLastPopup()
                            case .failure:
                                HapticManager.shared.trigger(.error)
                                withAnimation {
                                    viewModel.loading = false
                                    viewModel.ifFailed = true
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Material.thin)
        .cornerRadius(20)
    }

    func configurePopup(config: CenterPopupConfig) -> CenterPopupConfig {
        config.popupHorizontalPadding(24)
    }
}
