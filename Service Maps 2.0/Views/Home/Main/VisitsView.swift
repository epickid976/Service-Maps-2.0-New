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
import MijickPopups
import Toasts

struct VisitsView: View {
    
    init(house: House, visitIdToScrollTo: String? = nil) {
        self.house = house
        let initialViewModel = VisitsViewModel(house: house, visitIdToScrollTo: visitIdToScrollTo)
        _viewModel = StateObject(wrappedValue: initialViewModel)
    }
    var house: House
    
    @StateObject var viewModel: VisitsViewModel
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var preferencesViewModel = ColumnViewModel()
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.mainWindowSize) var mainWindowSize
    @Environment(\.presentToast) var presentToast
    
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    @State var showFab = true
    @State var scrollOffset: CGFloat = 0.00
    @State private var isScrollingDown = false
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    @State var highlightedVisitId: String?
    
    let minimumOffset: CGFloat = 60
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ScrollViewReader { scrollViewProxy in
                    ScrollView {
                        LazyVStack {
                        
                            if viewModel.visitData == nil && viewModel.dataStore.synchronized == false {
                                if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" {
                                    LottieView(animation: .named("loadsimple"))
                                        .playing(loopMode: .loop)
                                        .resizable()
                                        .frame(width: 250, height: 250)
                                } else {
                                    LottieView(animation: .named("loadsimple"))
                                        .playing(loopMode: .loop)
                                        .resizable()
                                        .frame(width: 350, height: 350)
                                }
                            } else {
                                if let data = viewModel.visitData {
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
                                                    ForEach(viewModel.visitData!, id: \.visit.id) { visitData in
                                                        visitCellView(visitData: visitData, mainWindowSize: proxy.size, ipad: UIDevice().userInterfaceIdiom == .pad).id(visitData.visit.id)
                                                            .modifier(ScrollTransitionModifier())
                                                            .transition(.customBackInsertion)
                                                    }.modifier(ScrollTransitionModifier())
                                                }
                                            } else {
                                                LazyVGrid(columns: [GridItem(.flexible())]) {
                                                    ForEach(viewModel.visitData!, id: \.visit.id) { visitData in
                                                        visitCellView(visitData: visitData, mainWindowSize: proxy.size).id(visitData.visit.id)
                                                            .modifier(ScrollTransitionModifier())
                                                            .transition(.customBackInsertion)
                                                    }.modifier(ScrollTransitionModifier())
                                                }
                                            }
                                            
                                        }
                                        .animation(.spring(), value: viewModel.visitData!)
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
                        .animation(.easeInOut(duration: 0.25), value: viewModel.visitData == nil || viewModel.visitData != nil)
                        
                        .onChange(of: viewModel.presentSheet) { value in
                            if value {
                                CentrePopup_AddVisit(viewModel: viewModel, house: house
                                ) {
                                       let toast = ToastValue(
                                        icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green),
                                           message: "Visit Added"
                                       )
                                       presentToast(toast)
                                }.present()
                                
                            }
                        }
                        //.scrollIndicators(.never)
                        .navigationBarTitle("House: \(viewModel.house.number)", displayMode: .automatic)
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarLeading) {
                                HStack {
                                    Button("", action: { viewModel.backAnimation.toggle(); HapticManager.shared.trigger(.lightImpact) ;
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
                                    Button("", action: { viewModel.syncAnimation.toggle();
                                        synchronizationManager.startupProcess(synchronizing: true) })//.ke yboardShortcut("s", modifiers: .command)
                                        .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $viewModel.dataStore.synchronized, lastTime: $viewModel.dataStore.lastTime))
                                    Button("", action: { 
                                        viewModel.revisitAnimation.toggle()
                                        if viewModel.recallAdded {
                                            CentrePopup_DeleteRecall(viewModel: viewModel, house: house.id) {
                                                let toast = ToastValue(
                                                    icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                                    message: NSLocalizedString("Recall Deleted", comment: "")
                                                )
                                                presentToast(toast)
                                            }.present()
                                        } else {
                                            CentrePopup_AddRecall(viewModel: viewModel, house: house.id) {
                                                let toast = ToastValue(
                                                 icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green),
                                                    message: "Recall Added"
                                                )
                                                presentToast(toast)
                                            }.present()
                                        }
                                    })
                                    .buttonStyle(CircleButtonStyle(imageName: viewModel.recallAdded ? "person.fill.checkmark"  : "person.badge.plus.fill", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.revisitAnimationprogress, animation: $viewModel.revisitAnimation))
                                }
                            }
                        }
                        .navigationTransition(viewModel.presentSheet || viewModel.visitIdToScrollTo != nil ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
                        .navigationViewStyle(StackNavigationViewStyle())
                    }.coordinateSpace(name: "scroll")
                        .scrollIndicators(.never)
                        .refreshable {
                           viewModel.synchronizationManager.startupProcess(synchronizing: true)
                        }
//                        .onChange(of: viewModel.dataStore.synchronized) { value in
//                            if value {
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                                    viewModel.getVisits()
//                                }
//                            }
//                        }
//                        .onChange(of: RealtimeManager.shared.lastMessage) { value in
//                            if value != nil {
//                                viewModel.getVisits()
//                            }
//                        }
                    
                        .onChange(of: viewModel.visitIdToScrollTo) { id in
                            if let id = id {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        scrollViewProxy.scrollTo(id, anchor: .center)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            HapticManager.shared.trigger(.selectionChanged)
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
            }
        }
    }
    
    @ViewBuilder
    func visitCellView(visitData: VisitData, mainWindowSize: CGSize, ipad: Bool = false) -> some View {
        SwipeView {
            VisitCell(visit: visitData, ipad: ipad, mainWindowSize: mainWindowSize)
                .padding(.bottom, 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16) // Same shape as the cell
                        .fill(highlightedVisitId == visitData.visit.id ? Color.gray.opacity(0.5) : Color.clear).animation(.default, value: highlightedVisitId == visitData.visit.id) // Fill with transparent gray if highlighted
                )
                .optionalViewModifier { content in
                    if AuthorizationLevelManager().existsAdminCredentials() {
                       content
                            .contextMenu {
                                Button {
                                    HapticManager.shared.trigger(.lightImpact)
                                    self.viewModel.currentVisit = visitData.visit
                                    self.viewModel.presentSheet = true
                                } label: {
                                    HStack {
                                        Image(systemName: "pencil")
                                        Text("Edit Visit")
                                    }
                                }
                                //TODO Trash and Pencil only if admin
                            }.clipShape(RoundedRectangle(cornerRadius: 16, style: .circular))
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
                    HapticManager.shared.trigger(.lightImpact)
                    context.state.wrappedValue = .closed
                    DispatchQueue.main.async {
                        self.viewModel.visitToDelete = visitData.visit.id
                        //self.viewModel.showAlert = true
                        CentrePopup_DeleteVisit(viewModel: viewModel) {
                            let toast = ToastValue(
                             icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                message: NSLocalizedString("Visit Deleted", comment: "")
                            )
                            presentToast(toast)
                        }.present()
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
                    HapticManager.shared.trigger(.lightImpact)
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
    var onDone: () -> Void
    
    init(viewModel: VisitsViewModel, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDone = onDone
    }
    var body: some View {
        createContent()
    }
    
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
                                dismissLastPopup()
                                self.viewModel.visitToDelete = nil
                            }
                        }
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: viewModel.loading, title: NSLocalizedString("Delete", comment: ""), color: .red) {
                        withAnimation {
                            self.viewModel.loading = true
                        }
                        Task {
                            if self.viewModel.visitToDelete != nil{
                                switch await self.viewModel.deleteVisit(visit: self.viewModel.visitToDelete ?? "") {
                                case .success(_):
                                    withAnimation {
                                        //self.viewModel.synchronizationManager.startupProcess(synchronizing: true)
                                        //self.viewModel.getVisits()
                                        self.viewModel.loading = false
                                    }
                                        //self.showAlert = false
                                        dismissLastPopup()
                                        self.viewModel.ifFailed = false
                                        self.viewModel.visitToDelete = nil
                                        onDone()
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
    
    func configurePopup(config: CentrePopupConfig) -> CentrePopupConfig {
        config
            .popupHorizontalPadding(24)
            
            
    }
}

struct CentrePopup_AddVisit: CentrePopup {
    @ObservedObject var viewModel: VisitsViewModel
    var onDone: () -> Void
    var house: House
    
    init(viewModel: VisitsViewModel, house: House, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDone = onDone
        self.house = house
    }
    
    var body: some View {
        createContent()
    }
    
    func createContent() -> some View {
        AddVisitView(visit: viewModel.currentVisit, house: house) {
            
                viewModel.presentSheet = false
                dismissLastPopup()
            
                onDone()
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

struct CentrePopup_AddRecall: CentrePopup {
    @ObservedObject var viewModel: VisitsViewModel
    let house: String
    let user = StorageManager.shared.userEmail
    var onDone: () -> Void
    
    init(viewModel: VisitsViewModel, house: String, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.house = house
        self.onDone = onDone
    }
    
    var body: some View {
        createContent()
    }
    
    func createContent() -> some View {
        VStack {
            Text("Add Recall")
                .font(.title2)
                .fontWeight(.heavy)
                .hSpacing(.center)
                .padding(.leading)
            Text("By adding this house as a recall, it will be displayed in the recalls tab and you will be able to access it more easily.")
                .font(.headline)
                .fontWeight(.bold)
                .hSpacing(.leading)
                .padding(.leading)
            if viewModel.ifFailed {
                Text("Error adding recall, please try again later")
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
            //.vSpacing(.bottom)
            
            HStack {
                if !viewModel.loading {
                    CustomBackButton() {
                        withAnimation {
                            //self.viewModel.showAlert = false
                            dismissLastPopup()
                            
                        }
                    }
                }
                //.padding([.top])
                
                CustomButton(loading: viewModel.loading, title: NSLocalizedString("Add", comment: "")) {
                    withAnimation {
                        self.viewModel.loading = true
                        
                    }
                    Task {
                        switch await viewModel.addRecall(user: user ?? "", house: house) {
                        case .success(_):
                            viewModel.loading = false
                            dismissLastPopup()
                            onDone()
                        case .failure(_):
                            viewModel.ifFailed = true
                        }
                    }
                    
                }
            }
            .padding([.horizontal])
        }.padding(10)
    }
    
    func configurePopup(config: CentrePopupConfig) -> CentrePopupConfig {
        config
            .popupHorizontalPadding(24)
            
    }
}

struct CentrePopup_DeleteRecall: CentrePopup {
    @ObservedObject var viewModel: VisitsViewModel
    let house: String
    let user = StorageManager.shared.userEmail
    var onDone: () -> Void
    
    init(viewModel: VisitsViewModel, house: String, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.house = house
        self.onDone = onDone
    }
    
    var body: some View {
        createContent()
    }
    
    func createContent() -> some View {
        VStack {
            Text("Remove Recall")
                .font(.title2)
                .fontWeight(.heavy)
                .hSpacing(.center)
                .padding(.leading)
            Text("By removing this house as a recall, it will be removed from the recalls tab.")
                .font(.headline)
                .fontWeight(.bold)
                .hSpacing(.leading)
                .padding(.leading)
            if viewModel.ifFailed {
                Text("Error removing recall, please try again later")
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
            
            HStack {
                if !viewModel.loading {
                    CustomBackButton() {
                        withAnimation {
                            dismissLastPopup()
                            
                        }
                    }
                }
                
                CustomButton(loading: viewModel.loading, title: NSLocalizedString("Remove", comment: ""), color: .red) {
                    withAnimation {
                        self.viewModel.loading = true
                        
                    }
                    Task {
                        switch await viewModel.deleteRecall(id: viewModel.getRecallId(house: house) ?? Date().millisecondsSince1970 ,user: user ?? "", house: house) {
                        case .success(_):
                            viewModel.loading = false
                            dismissLastPopup()
                            onDone()
                        case .failure(_):
                            viewModel.ifFailed = true
                        }
                    }
                    
                }
            }
            .padding([.horizontal])
            //.vSpacing(.bottom)
        }.padding(10)
    }
    
    func configurePopup(config: CentrePopupConfig) -> CentrePopupConfig {
        config
            .popupHorizontalPadding(24)
            
            
    }
}

