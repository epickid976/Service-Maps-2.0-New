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
import MijickPopupView

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
    
    init(house: HouseModel, visitIdToScrollTo: String? = nil) {
        self.house = house
        let initialViewModel = VisitsViewModel(house: house, visitIdToScrollTo: visitIdToScrollTo)
        _viewModel = StateObject(wrappedValue: initialViewModel)
    }
    
    let alertViewDeleted = AlertAppleMusic17View(title: "Visit Deleted", subtitle: nil, icon: .custom(UIImage(systemName: "trash")!))
    let alertViewAdded = AlertAppleMusic17View(title: "Visit Added", subtitle: nil, icon: .done)
    
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    let minimumOffset: CGFloat = 60
    @Environment(\.mainWindowSize) var mainWindowSize
    
    @State var highlightedVisitId: String?
    
    var body: some View {
        ZStack {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    VStack {
                        if viewModel.visitData == nil || viewModel.dataStore.synchronized == false {
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
                                            visitCellView(visitData: visitData).id(visitData.visit.id)
                                        }
                                        .animation(.default, value: viewModel.visitData!)
                                        
                                        
                                    }
                                }.animation(.spring(), value: viewModel.visitData)
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
                    .animation(.easeInOut(duration: 0.25), value: viewModel.visitData == nil || viewModel.visitData != nil)
                    .alert(isPresent: $viewModel.showToast, view: alertViewDeleted)
                    .alert(isPresent: $viewModel.showAddedToast, view: alertViewAdded)
                    .onChange(of: viewModel.presentSheet) { value in
                        if value {
                            CentrePopup_AddVisit(viewModel: viewModel, house: house).showAndStack()
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
                                }).keyboardShortcut(.delete, modifiers: .command)
                                    .buttonStyle(CircleButtonStyle(imageName: "arrow.backward", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.backAnimation))
                            }
                        }
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            HStack {
                                Button("", action: { viewModel.syncAnimation.toggle();  print("Syncing") ; viewModel.synchronizationManager.startupProcess(synchronizing: true) }).keyboardShortcut("s", modifiers: .command)
                                    .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $viewModel.dataStore.synchronized, lastTime: $viewModel.dataStore.lastTime))
                            }
                        }
                    }
                    .navigationTransition(viewModel.presentSheet || viewModel.visitIdToScrollTo != nil ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
                    .navigationViewStyle(StackNavigationViewStyle())
                }.coordinateSpace(name: "scroll")
                    .scrollIndicators(.hidden)
                    .refreshable {
                        viewModel.synchronizationManager.startupProcess(synchronizing: true)
                    }
                    .onChange(of: viewModel.dataStore.synchronized) { value in
                        if value {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                viewModel.getVisits()
                            }
                        }
                    }
                
                    .onChange(of: viewModel.visitIdToScrollTo) { id in
                        if let id = id {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    scrollViewProxy.scrollTo(id, anchor: .center)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        highlightedVisitId = id // Highlight after scrolling
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        highlightedVisitId = nil
                                    }
                                }
                            }
                            
                        }
                    }
            }
            MainButton(imageName: "plus", colorHex: "#1e6794", width: 60) {
                        self.viewModel.presentSheet = true
                    }
                    .offset(y: hideFloatingButton ? 200 : 0)
                        .animation(.spring(), value: hideFloatingButton)
                        .vSpacing(.bottom).hSpacing(.trailing)
                        .padding()
                        .keyboardShortcut("+", modifiers: .command)
                
        }
    }
    
    @ViewBuilder
    func visitCellView(visitData: VisitData) -> some View {
        SwipeView {
            VisitCell(visit: visitData)
                .padding(.bottom, 2)
                .overlay(
                    highlightedVisitId == visitData.visit.id ? Color.gray.opacity(0.5) : Color.clear
                ).cornerRadius(16, corners: .allCorners).animation(.default, value: highlightedVisitId == visitData.visit.id)
                .optionalViewModifier { content in
                    if AuthorizationLevelManager().existsAdminCredentials() {
                       content
                            .contextMenu {
                                Button {
                                    self.viewModel.currentVisit = visitData.visit
                                    self.viewModel.presentSheet = true
                                } label: {
                                    HStack {
                                        Image(systemName: "pencil")
                                        Text("Edit Visit")
                                    }
                                }
                                //TODO Trash and Pencil only if admin
                            }
                    } else {
                        content
                    }
                }
                
        } trailingActions: { context in
            if visitData.accessLevel == .Admin {
                SwipeAction(
                    systemImage: "trash",
                    backgroundColor: .red
                ) {
                    DispatchQueue.main.async {
                        self.viewModel.visitToDelete = visitData.visit.id
                        //self.viewModel.showAlert = true
                        CentrePopup_DeleteVisit(viewModel: viewModel).showAndStack()
                    }
                }
                .font(.title.weight(.semibold))
                .foregroundColor(.white)
                
                
            }
            
            if visitData.accessLevel == .Moderator || visitData.accessLevel == .Admin {
                SwipeAction(
                    systemImage: "pencil",
                    backgroundColor: Color.teal
                ) {
                    self.viewModel.currentVisit = visitData.visit
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
        .swipeMinimumDistance(visitData.accessLevel != .User ? 25:1000)
        
    }
}

struct CentrePopup_DeleteVisit: CentrePopup {
    @ObservedObject var viewModel: VisitsViewModel
    
    
    func createContent() -> some View {
        ZStack {
            VStack {
                Text("Delete Visit")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                    .padding(.leading)
                Text("Are you sure you want to delete the selected visit?")
                    .font(.headline)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                    .padding(.leading)
                if viewModel.ifFailed {
                    Text("Error deleting visit, please try again later")
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                //.vSpacing(.bottom)
                
                HStack {
                    if !viewModel.loading {
                        CustomBackButton() {
                            withAnimation {
                                //self.viewModel.showAlert = false
                                dismiss()
                                self.viewModel.visitToDelete = nil
                            }
                        }
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: viewModel.loading, title: "Delete", color: .red) {
                        withAnimation {
                            self.viewModel.loading = true
                        }
                        Task {
                            if self.viewModel.visitToDelete != nil{
                                switch await self.viewModel.deleteVisit(visit: self.viewModel.visitToDelete ?? "") {
                                case .success(_):
                                    withAnimation {
                                        self.viewModel.synchronizationManager.startupProcess(synchronizing: true)
                                        self.viewModel.getVisits()
                                        self.viewModel.loading = false
                                        //self.showAlert = false
                                        dismiss()
                                        self.viewModel.ifFailed = false
                                        self.viewModel.visitToDelete = nil
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

struct CentrePopup_AddVisit: CentrePopup {
    @ObservedObject var viewModel: VisitsViewModel
    @State var house: HouseModel
    
    
    func createContent() -> some View {
        AddVisitView(visit: viewModel.currentVisit, house: house) {
            DispatchQueue.main.async {
                viewModel.presentSheet = false
                dismiss()
                viewModel.synchronizationManager.startupProcess(synchronizing: true)
                viewModel.getVisits()
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

//#Preview {
//    VisitsView()
//}
