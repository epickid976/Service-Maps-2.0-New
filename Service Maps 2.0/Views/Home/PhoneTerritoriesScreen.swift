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
import AlertKit
import Nuke
import MijickPopupView

struct PhoneTerritoriesScreen: View {
    @StateObject var viewModel: PhoneScreenViewModel
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    @Environment(\.presentationMode) var presentationMode
    
    let alertViewDeleted = AlertAppleMusic17View(title: "Territory Deleted", subtitle: nil, icon: .custom(UIImage(systemName: "trash")!))
    let alertViewAdded = AlertAppleMusic17View(title: "Territory Added", subtitle: nil, icon: .done)
    
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    
    @State var searchViewDestination = false
    
    let minimumOffset: CGFloat = 60
    
    init(phoneTerritoryToScrollTo: String? = nil) {
       let viewModel = PhoneScreenViewModel(phoneTerritoryToScrollTo: phoneTerritoryToScrollTo)
        _viewModel = StateObject(wrappedValue: viewModel)
        
    }
    
    @State var highlightedTerritoryId: String?
    
    @ObservedObject var preferencesViewModel = ColumnViewModel()
    
    @State var isCircleExpanded = false
    
    @StateObject var dataStore = StorageManager.shared
    
    var body: some View {
        let transition: AnyNavigationTransition
                if viewModel.presentSheet || viewModel.phoneTerritoryToScrollTo != nil {
                    transition = AnyNavigationTransition.zoom.combined(with: .fade(.in))
                } else if searchViewDestination {
                    transition = AnyNavigationTransition.fade(.cross)
                } else {
                    transition = AnyNavigationTransition.slide.combined(with: .fade(.in))
                }
        
        return GeometryReader { proxy in
            ZStack {
                ScrollViewReader { scrollViewProxy in
                    ScrollView {
                        VStack {
                            if viewModel.phoneData == nil && viewModel.dataStore.synchronized == false {
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
                                if let data = viewModel.phoneData {
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
                                        LazyVStack {
                                            if !(viewModel.recentPhoneData == nil) {
                                                if viewModel.recentPhoneData!.count > 0 {
                                                    LazyVStack {
                                                        Text("Recent Territories")
                                                            .font(.title2)
                                                            .lineLimit(1)
                                                            .foregroundColor(.primary)
                                                            .fontWeight(.bold)
                                                            .hSpacing(.leading)
                                                            .padding(5)
                                                            .padding(.horizontal, 10)
                                                        ScrollView(.horizontal, showsIndicators: false) {
                                                            LazyHStack {
                                                                ForEach(viewModel.recentPhoneData!, id: \.id) { territoryData in
                                                                    NavigationLink(destination: NavigationLazyView(PhoneNumbersView(territory: territoryData.territory).implementPopupView()).implementPopupView()) {
                                                                        recentPhoneCell(territoryData: territoryData, mainWindowSize: proxy.size).transition(.customBackInsertion)
                                                                    }.onTapHaptic(.lightImpact)
                                                                }
                                                            }
                                                        }
                                                        .padding(.leading)
                                                        
                                                    }.modifier(ScrollTransitionModifier())
                                                        .animation(.smooth, value: viewModel.recentPhoneData == nil || viewModel.recentPhoneData != nil)
                                                }
                                            }
                                            LazyVStack {
                                                SwipeViewGroup {
                                                    if UIDevice().userInterfaceIdiom == .pad && proxy.size.width > 400 && preferencesViewModel.isColumnViewEnabled {
                                                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                                            ForEach(viewModel.phoneData!, id: \.territory.id) { phoneData in
                                                                
                                                                let proxy = CGSize(width: proxy.size.width / 2 - 16, height: proxy.size.height)
                                                                
                                                                territoryCell(phoneData: phoneData, mainViewSize: proxy).id(phoneData.territory.id).transition(.customBackInsertion)
                                                            }.modifier(ScrollTransitionModifier())
                                                        }
                                                    } else {
                                                        LazyVGrid(columns: [GridItem(.flexible())]) {
                                                            ForEach(viewModel.phoneData!, id: \.territory.id) { phoneData in
                                                                territoryCell(phoneData: phoneData, mainViewSize: proxy.size).id(phoneData.territory.id).transition(.customBackInsertion)
                                                            }.modifier(ScrollTransitionModifier())
                                                        }
                                                    }
                                                    //.animation(.default, value: viewModel.phoneData!)
                                                    
                                                    
                                                }
                                            }.animation(.spring(), value: viewModel.phoneData)
                                        }
                                        
                                        
                                        
                                    }
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
                        .animation(.easeInOut(duration: 0.25), value: viewModel.phoneData == nil || viewModel.phoneData != nil)
                        .alert(isPresent: $viewModel.showToast, view: alertViewDeleted)
                        .alert(isPresent: $viewModel.showAddedToast, view: alertViewAdded)
                        .navigationDestination(isPresented: $viewModel.presentSheet) {
                            AddPhoneTerritoryView(territory: viewModel.currentTerritory) {
                                //synchronizationManager.startupProcess(synchronizing: true)
                                viewModel.getTeritories()
                                DispatchQueue.main.async {
                                    viewModel.showAddedToast = true
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    viewModel.showAddedToast = false
                                }
                            }
                        }
                        .navigationDestination(isPresented: $searchViewDestination) {
                            NavigationLazyView(SearchView(searchMode: .PhoneTerritories) { DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                withAnimation(.spring()) {
                                    isCircleExpanded = false
                                    viewModel.backAnimation.toggle()
                                }
                            }})
                        }
                        //.scrollIndicators(.never)
                        .navigationBarTitle("Phone Territories", displayMode: .automatic)
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarLeading) {
                                HStack {
                                    if viewModel.phoneTerritoryToScrollTo != nil {
                                        Button("", action: {withAnimation { viewModel.backAnimation.toggle(); HapticManager.shared.trigger(.lightImpact) };
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                dismissAll()
                                                presentationMode.wrappedValue.dismiss()
                                            }
                                        })//.keyboardShortcut(.delete, modifiers: .command)
                                            .buttonStyle(CircleButtonStyle(imageName: "arrow.backward", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.backAnimation))
                                    }
                                }
                            }
                            ToolbarItemGroup(placement: .topBarTrailing) {
                                HStack {
                                    
                                    Button("", action: { viewModel.syncAnimation.toggle();  print("Syncing") ; synchronizationManager.startupProcess(synchronizing: true) })//.keyboardShortcut("s", modifiers: .command)
                                        .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $viewModel.dataStore.synchronized, lastTime: $viewModel.dataStore.lastTime)).padding(.leading, viewModel.phoneData == nil || dataStore.synchronized ? 0 : 50)
                                if viewModel.phoneData == nil || dataStore.synchronized {
                                    if viewModel.phoneTerritoryToScrollTo == nil {
                                        Button("", action: { HapticManager.shared.trigger(.lightImpact) ;
                                            //DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                                withAnimation(.spring()) {
                                                    isCircleExpanded = true
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                        viewModel.backAnimation.toggle()
                                                        searchViewDestination = true
                                                    }
                                                }
                                                
                                            }
                                            //}
                                            
                                        }).scaleEffect(viewModel.phoneData == nil || dataStore.synchronized ? 1 : 0)
                                        .buttonStyle(CircleButtonStyle(imageName: "magnifyingglass", background: .white.opacity(0), width: !isCircleExpanded ? 40 : proxy.size.width * 4, height: !isCircleExpanded ? 40 : proxy.size.height * 4, progress: $viewModel.progress, animation: $viewModel.backAnimation)).transition(.scale).padding(.top, isCircleExpanded ? 1000 : 0).animation(.spring(), value: isCircleExpanded)
                                    }
                                }
                                }.animation(.spring(), value: viewModel.phoneData == nil || viewModel.dataStore.synchronized)
                            }
                        }
                        .navigationTransition(transition)
                        .navigationViewStyle(StackNavigationViewStyle())
                    }.coordinateSpace(name: "scroll")
                        .scrollIndicators(.never)
                        .refreshable {
                            synchronizationManager.startupProcess(synchronizing: true)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                hideFloatingButton = false
                            }
                        }
                        .onChange(of: viewModel.dataStore.synchronized) { value in
                            if value {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    viewModel.getTeritories()
                                }
                            }
                        }
                        .onChange(of: viewModel.phoneTerritoryToScrollTo) { id in
                            if let id = id {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        scrollViewProxy.scrollTo(id, anchor: .center)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            HapticManager.shared.trigger(.selectionChanged)
                                            highlightedTerritoryId = id // Highlight after scrolling
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            highlightedTerritoryId = nil
                                        }
                                    }
                                }
                                
                            }
                        }
                }
                if AuthorizationLevelManager().existsAdminCredentials() {
                    MainButton(imageName: "plus", colorHex: "#1e6794", width: 60) {
                        self.viewModel.presentSheet = true
                    }
                    .offset(y: hideFloatingButton ? 150 : 0)
                    .animation(.spring(), value: hideFloatingButton)
                    .vSpacing(.bottom).hSpacing(.trailing)
                    .padding()
                   // //.keyboardShortcut("+", modifiers: .command)
                }
            }
        }
    }
    
    @ViewBuilder
    func territoryCell(phoneData: PhoneData, mainViewSize: CGSize) -> some View {
        LazyVStack {
        SwipeView {
            NavigationLink(destination: NavigationLazyView(PhoneNumbersView(territory: phoneData.territory).implementPopupView()).implementPopupView()) {
                PhoneTerritoryCellView(territory: phoneData.territory, numbers: phoneData.numbersQuantity, mainWindowSize: mainViewSize)
                    .padding(.bottom, 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16) // Same shape as the cell
                            .fill(highlightedTerritoryId == phoneData.territory.id ? Color.gray.opacity(0.5) : Color.clear).animation(.default, value: highlightedTerritoryId == phoneData.territory.id) // Fill with transparent gray if highlighted
                    )
                    .optionalViewModifier { content in
                        if AuthorizationLevelManager().existsAdminCredentials() {
                            content
                                .contextMenu {
                                    Button {
                                        DispatchQueue.main.async {
                                            self.viewModel.territoryToDelete = (String(phoneData.territory.id), String(phoneData.territory.number))
                                            CentrePopup_DeletePhoneTerritory(viewModel: viewModel).showAndStack()
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "trash")
                                            Text("Delete Territory")
                                        }
                                    }
                                    
                                    Button {
                                        self.viewModel.currentTerritory = phoneData.territory
                                        self.viewModel.presentSheet = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "pencil")
                                            Text("Edit Territory")
                                        }
                                    }
                                    //TODO Trash and Pencil only if admin
                                }.clipShape(RoundedRectangle(cornerRadius: 16, style: .circular))
                        } else if AuthorizationLevelManager().existsPhoneCredentials() {
                            content
                                .contextMenu {
                                    Button {
                                        self.viewModel.currentTerritory = phoneData.territory
                                        self.viewModel.presentSheet = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "pencil")
                                            Text("Edit Territory")
                                        }
                                    }
                                    //TODO Trash and Pencil only if admin
                                }.clipShape(RoundedRectangle(cornerRadius: 16, style: .circular))
                        } else {
                            content
                        }
                    }
                    
            }.onTapHaptic(.lightImpact)
        } trailingActions: { context in
            if self.viewModel.isAdmin {
                SwipeAction(
                    systemImage: "trash",
                    backgroundColor: .red
                ) {
                    HapticManager.shared.trigger(.lightImpact)
                    DispatchQueue.main.async {
                        context.state.wrappedValue = .closed
                        self.viewModel.territoryToDelete = (String(phoneData.territory.id), String(phoneData.territory.number))
                        CentrePopup_DeletePhoneTerritory(viewModel: viewModel).showAndStack()
                    }
                }
                .font(.title.weight(.semibold))
                .foregroundColor(.white)
                
                SwipeAction(
                    systemImage: "pencil",
                    backgroundColor: Color.teal
                ) {
                    HapticManager.shared.trigger(.lightImpact)
                    context.state.wrappedValue = .closed
                    self.viewModel.currentTerritory = phoneData.territory
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
        .swipeMinimumDistance(viewModel.isAdmin ? 25:1000)
        }.padding(.horizontal, 15)
    }
}
struct CentrePopup_DeletePhoneTerritory: CentrePopup {
    @ObservedObject var viewModel: PhoneScreenViewModel
    
    
    func createContent() -> some View {
        ZStack {
            VStack {
                Text("Delete Territory \(viewModel.territoryToDelete.1 ?? "0")")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                    .padding(.leading)
                Text("Are you sure you want to delete the selected territory?")
                    .font(.headline)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                    .padding(.leading)
                if viewModel.ifFailed {
                    Text("Error deleting territory, please try again later")
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                //.vSpacing(.bottom)
                
                HStack {
                    if !viewModel.loading {
                        CustomBackButton() {
                            HapticManager.shared.trigger(.lightImpact)
                            withAnimation {
                                //self.showAlert = false
                                dismiss()
                                self.viewModel.territoryToDelete = (nil,nil)
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
                            if self.viewModel.territoryToDelete.0 != nil && self.viewModel.territoryToDelete.1 != nil {
                                switch await self.viewModel.deleteTerritory(territory: self.viewModel.territoryToDelete.0 ?? "") {
                                case .success(_):
                                    HapticManager.shared.trigger(.success)
                                    viewModel.getTeritories()
                                    withAnimation {
                                        withAnimation {
                                            self.viewModel.loading = false
                                        }
                                        dismiss()
                                        self.viewModel.territoryToDelete = (nil,nil)
                                        self.viewModel.showToast = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                            self.viewModel.showToast = false
                                        }
                                    }
                                case .failure(_):
                                    HapticManager.shared.trigger(.error)
                                    withAnimation {
                                        self.viewModel.loading = false
                                    }
                                    self.viewModel.ifFailed = true
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
