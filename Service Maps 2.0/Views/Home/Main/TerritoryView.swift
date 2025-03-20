//
//  Territory View.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/4/23.
//

import SwiftUI
import NavigationTransitions
import SwipeActions
import Combine
import UIKit
import Lottie
import AlertKit
import Nuke
import FloatingButton
import MijickPopups
import Toasts

//MARK: - Territory View

struct TerritoryView: View {
    
    //MARK: - Environment
    
    @Environment(\.dismissSearch) private var dismissSearch
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.presentToast) var presentToast
    
    //MARK: - Dependencies
    
    @StateObject var viewModel: TerritoryViewModel
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var preferencesViewModel = ColumnViewModel()
    
    //MARK: - Properties
    
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    @State var searchViewDestination = false
    
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    let minimumOffset: CGFloat = 60
    @State private var animationTrigger: Bool = false
    
    @State private var highlightedTerritoryId: String?
    
    @State var isCircleExpanded = false
    
    //MARK: -  Initializers
    
    init(territoryIdToScrollTo: String? = nil) {
        let viewModel = TerritoryViewModel(territoryIdToScrollTo: territoryIdToScrollTo)
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    
    var body: some View {
        
        //MARK: - Transition Logic
        
        let transition: AnyNavigationTransition
        if viewModel.presentSheet || viewModel.territoryIdToScrollTo != nil {
            transition = AnyNavigationTransition.zoom.combined(with: .fade(.in))
        } else if searchViewDestination {
            transition = AnyNavigationTransition.fade(.cross)
        } else {
            transition = AnyNavigationTransition.slide.combined(with: .fade(.in))
        }
        
        return NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    ScrollViewReader { scrollViewProxy in
                        ScrollView {
                            VStack {
                                if viewModel.territoryData == nil && !viewModel.dataStore.synchronized {
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
                                    if let data = viewModel.territoryData {
                                        if data.isEmpty {
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
                                        } else {
                                            if viewModel.recentTerritoryData != nil {
                                                if viewModel.recentTerritoryData!.count > 0 {
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
                                                                ForEach(viewModel.recentTerritoryData!, id: \.id) { territoryData in
                                                                    RecentTerritoryCellView(territoryData: territoryData, mainWindowSize: proxy.size)
                                                                }
                                                            }
                                                            .padding(.leading, 10)
                                                        }
                                                        .scrollIndicators(.never)
                                                        
                                                    }.modifier(ScrollTransitionModifier())
                                                        .animation(
                                                            .spring(),
                                                            value: viewModel.recentTerritoryData == nil || viewModel.recentTerritoryData != nil
                                                        )
                                                        .animation(
                                                            .spring(),
                                                            value: viewModel.recentTerritoryData
                                                        )
                                                    
                                                }
                                            }
                                            
                                            
                                            SwipeViewGroup {
                                                // Initialize the `isWideScreen` variable
                                                let isWideScreen = UIDevice.current.userInterfaceIdiom == .pad &&
                                                proxy.size.width > 400 &&
                                                preferencesViewModel.isColumnViewEnabled
                                                
                                                if isWideScreen {
                                                    // Two independent columns for wide screens
                                                    HStack(alignment: .top, spacing: 16) {
                                                        // Left Column
                                                        LazyVStack(spacing: 16) {
                                                            ForEach(viewModel.territoryData?.enumerated().filter { $0.offset % 2 == 0 }.map { $0.element } ?? [], id: \.id) { dataWithKeys in
                                                                CustomDisclosureGroup(
                                                                    title: dataWithKeys.keys.isEmpty ? "Other Territories" : dataWithKeys.keys.map(\.name).joined(separator: ", "),
                                                                    items: dataWithKeys.territoriesData
                                                                ) { territoryData in
                                                                    territoryCell(
                                                                        dataWithKeys: dataWithKeys,
                                                                        territoryData: territoryData,
                                                                        mainViewSize: proxy.size
                                                                    )
                                                                    .id(territoryData.territory.id)
                                                                    .transition(.customBackInsertion)
                                                                    .modifier(ScrollTransitionModifier())
                                                                }
                                                            }
                                                        }
                                                        
                                                        // Right Column
                                                        LazyVStack(spacing: 16) {
                                                            ForEach(viewModel.territoryData?.enumerated().filter { $0.offset % 2 == 1 }.map { $0.element } ?? [], id: \.id) { dataWithKeys in
                                                                CustomDisclosureGroup(
                                                                    title: dataWithKeys.keys.isEmpty ? "Other Territories" : dataWithKeys.keys.map(\.name).joined(separator: ", "),
                                                                    items: dataWithKeys.territoriesData
                                                                ) { territoryData in
                                                                    territoryCell(
                                                                        dataWithKeys: dataWithKeys,
                                                                        territoryData: territoryData,
                                                                        mainViewSize: proxy.size
                                                                    )
                                                                    .id(territoryData.territory.id)
                                                                    .transition(.customBackInsertion)
                                                                    .modifier(ScrollTransitionModifier())
                                                                }
                                                            }
                                                        }
                                                    }
                                                } else {
                                                    // Single column for narrow screens
                                                    LazyVStack(spacing: 16) {
                                                        ForEach(viewModel.territoryData ?? [], id: \.id) { dataWithKeys in
                                                            CustomDisclosureGroup(
                                                                title: dataWithKeys.keys.isEmpty ? "Other Territories" : dataWithKeys.keys.map(\.name).joined(separator: ", "),
                                                                items: dataWithKeys.territoriesData
                                                            ) { territoryData in
                                                                territoryCell(
                                                                    dataWithKeys: dataWithKeys,
                                                                    territoryData: territoryData,
                                                                    mainViewSize: proxy.size
                                                                )
                                                                .id(territoryData.territory.id)
                                                                .transition(.customBackInsertion)
                                                                .modifier(ScrollTransitionModifier())
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .hSpacing(.center)
                            .background(GeometryReader {
                                Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                            }).onPreferenceChange(ViewOffsetKey.self) { currentOffset in
                                Task { @MainActor in
                                    let offsetDifference: CGFloat = self.previousViewOffset - currentOffset
                                    if ( abs(offsetDifference) > minimumOffset) {
                                        if offsetDifference > 0 {
                                            DispatchQueue.main.async {
                                                hideFloatingButton = false
                                            }
                                        } else {
                                            hideFloatingButton = true
                                        }
                                        self.previousViewOffset = currentOffset
                                    }
                                }
                            }
                            //.animation(.easeInOut(duration: 0.25), value: viewModel.territoryData == nil || viewModel.territoryData != nil)
                            .navigationDestination(isPresented: $viewModel.presentSheet) {
                                AddTerritoryView(territory: viewModel.currentTerritory) {
                                    let toast = ToastValue(
                                        icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green),
                                        message: "Territory Added"
                                    )
                                    presentToast(toast)
                                }
                            }
                            .navigationDestination(isPresented: $searchViewDestination) {
                                
                                NavigationLazyView(SearchView(searchMode: .Territories) { DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    withAnimation(.spring()) {
                                        isCircleExpanded = false
                                        viewModel.backAnimation.toggle()
                                    }
                                }})
                            }
                            .navigationBarTitle("Territories", displayMode: .automatic)
                            .navigationBarBackButtonHidden(true)
                            .toolbar {
                                ToolbarItemGroup(placement: .topBarLeading) {
                                    HStack {
                                        if viewModel.territoryIdToScrollTo != nil {
                                            Button("", action: {withAnimation { viewModel.backAnimation.toggle(); HapticManager.shared.trigger(.lightImpact) };
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                    dismissAllPopups()
                                                    presentationMode.wrappedValue.dismiss()
                                                }
                                            })//.keyboardShortcut(.delete, modifiers: .command)
                                            .buttonStyle(CircleButtonStyle(imageName: "arrow.backward", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.backAnimation))
                                        }
                                    }
                                }
                                ToolbarItemGroup(placement: .topBarTrailing) {
                                    HStack {
                                        
                                        Button("", action: { viewModel.syncAnimation = true; synchronizationManager.startupProcess(synchronizing: true) })//.keyboardShortcut("s", modifiers: .command)
                                            .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $viewModel.dataStore.synchronized, lastTime: $viewModel.dataStore.lastTime))
                                            .padding(.leading, viewModel.territoryData == nil || dataStore.synchronized ? 0 : 50)//.animation(.spring(), value: viewModel.dataStore.synchronized)
                                        if viewModel.territoryData == nil || dataStore.synchronized {
                                            if viewModel.territoryIdToScrollTo == nil {
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
                                                }).scaleEffect(viewModel.territoryData == nil || dataStore.synchronized ? 1 : 0)
                                                    .buttonStyle(CircleButtonStyle(imageName: "magnifyingglass", background: .white.opacity(0), width: !isCircleExpanded ? 40 : proxy.size.width * 4, height: !isCircleExpanded ? 40 : proxy.size.height * 4, progress: $viewModel.progress, animation: $viewModel.backAnimation)).transition(.scale).padding(.top, isCircleExpanded ? 1000 : 0)
                                                    .animation(.spring(), value: isCircleExpanded)
                                            }
                                        }
                                    }
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
                            .onChange(of: viewModel.territoryIdToScrollTo) { id in
                                if let id = id {
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation {
                                            scrollViewProxy.scrollTo(id, anchor: .center)
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                highlightedTerritoryId = id // Highlight after scrolling
                                                HapticManager.shared.trigger(.selectionChanged)
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                highlightedTerritoryId = nil
                                            }
                                        }
                                    }
                                    
                                }
                            }
                            .onChange(of: viewModel.dataStore.synchronized) { value in
                                if value {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        viewModel.getTerritories()
                                    }
                                }
                            }
                        
                    }
                    
                    if AuthorizationLevelManager().existsAdminCredentials() {
                        MainButton(imageName: "plus", colorHex: "#1e6794", width: 60) {
                            self.viewModel.presentSheet = true
                        }
                        .offset(y: hideFloatingButton ? 100 : 0)
                        .animation(.spring(), value: hideFloatingButton)
                        .vSpacing(.bottom).hSpacing(.trailing)
                        .padding()
                    }
                    
                }
            }
        }
    }
    
    @ViewBuilder
    func territoryHeader(dataWithKeys: TerritoryDataWithKeys) -> some View {
        if !dataWithKeys.keys.isEmpty {
            Text(self.viewModel.processData(dataWithKeys: dataWithKeys))
                .font(.title2)
                .lineLimit(2)
                .foregroundColor(.primary)
                .fontWeight(.bold)
                .hSpacing(.leading)
                .padding(5)
                .padding(.horizontal, 10)
        } else {
            Spacer()
                .frame(height: 20)
        }
    }
    
    //MARK: - Territory Cell
    
    @ViewBuilder
    func territoryCell(dataWithKeys: TerritoryDataWithKeys, territoryData: TerritoryData, mainViewSize: CGSize) -> some View {
        LazyVStack {
            SwipeView {
                NavigationLink(destination: NavigationLazyView(TerritoryAddressView(territory: territoryData.territory).installToast(position: .bottom))) {
                    CellView(territory: territoryData.territory, houseQuantity: territoryData.housesQuantity, mainWindowSize: mainViewSize)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16) // Same shape as the cell
                                .fill(highlightedTerritoryId == territoryData.territory.id ? Color.gray.opacity(0.5) : Color.clear)
                                .animation(.default, value: highlightedTerritoryId == territoryData.territory.id)
                        )
                    //.padding(.bottom, 2)
                        .optionalViewModifier { content in
                            if AuthorizationLevelManager().existsAdminCredentials() {
                                content
                                    .contextMenu {
                                        Button(action: {
                                            copyToClipboard(text: territoryData.territory.description)
                                        }) {
                                            HStack {
                                                Image(systemName: "doc.on.doc")
                                                Text("Copy Address")
                                                    .padding()
                                                    .background(Color.green)
                                                    .foregroundColor(.white)
                                                    .cornerRadius(8)
                                            }
                                        }
                                        
                                        Button {
                                            HapticManager.shared.trigger(.lightImpact)
                                            self.viewModel.territoryToDelete = (territoryData.territory.id, String(territoryData.territory.number))
                                            CentrePopup_DeleteTerritoryAlert(viewModel: viewModel){
                                                let toast = ToastValue(
                                                    icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                                    message: NSLocalizedString("Territory Deleted", comment: "")
                                                )
                                                presentToast(toast)
                                            }.present()
                                        } label: {
                                            HStack {
                                                Image(systemName: "trash")
                                                Text("Delete Territory")
                                            }
                                        }
                                        
                                        Button {
                                            HapticManager.shared.trigger(.lightImpact)
                                            self.viewModel.currentTerritory = territoryData.territory
                                            self.viewModel.presentSheet = true
                                        } label: {
                                            HStack {
                                                Image(systemName: "pencil")
                                                Text("Edit Territory")
                                            }
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .circular))
                            } else {
                                content
                            }
                        }
                }
                .onTapHaptic(.lightImpact)
            } trailingActions: { context in
                if territoryData.accessLevel == .Admin {
                    SwipeAction(
                        systemImage: "trash",
                        backgroundColor: .red
                    ) {
                        HapticManager.shared.trigger(.lightImpact)
                        context.state.wrappedValue = .closed
                        self.viewModel.territoryToDelete = (territoryData.territory.id, String(territoryData.territory.number))
                        CentrePopup_DeleteTerritoryAlert(viewModel: viewModel){
                            let toast = ToastValue(
                                icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                message: NSLocalizedString("Territory Deleted", comment: "")
                            )
                            presentToast(toast)
                        }.present()
                    }
                    .font(.title.weight(.semibold))
                    .foregroundColor(.white)
                }
                
                if territoryData.accessLevel == .Moderator || territoryData.accessLevel == .Admin {
                    SwipeAction(
                        systemImage: "pencil",
                        backgroundColor: Color.teal
                    ) {
                        HapticManager.shared.trigger(.lightImpact)
                        context.state.wrappedValue = .closed
                        self.viewModel.currentTerritory = territoryData.territory
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
            .swipeMinimumDistance(territoryData.accessLevel != .User ? 25 : 1000)
        }
        .padding(.horizontal, 15)
    }
    
}

//MARK: - Main Button

struct MainButton: View {
    
    var imageName: String
    var colorHex: String
    var width: CGFloat = 50
    var action: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        ZStack {
            ZStack {
                Color(hex: colorHex)
                    .frame(width: width, height: width)
                    .cornerRadius(width / 2)
                    .shadow(color: Color(hex: colorHex).opacity(0.3), radius: 15, x: 0, y: 15)
                Image(systemName: imageName)
                    .foregroundColor(.white)
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.2), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        HapticManager.shared.trigger(.lightImpact)
                        isPressed = true
                    }
                    .onEnded { _ in
                        isPressed = false
                        action()
                    }
            )
        }
    }
}

//MARK: - Delete Territory Popup

struct CentrePopup_DeleteTerritoryAlert: CentrePopup {
    @ObservedObject var viewModel: TerritoryViewModel
    var onDone: () -> Void
    
    init(viewModel: TerritoryViewModel, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDone = onDone
    }
    
    var body: some View {
        createContent()
    }
    
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
                                //self.viewModel.showAlert = false
                                dismissLastPopup()
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
                                    DispatchQueue.main.async {
                                        //viewModel.getTerritories()
                                    }
                                    withAnimation {
                                        
                                        withAnimation {
                                            self.viewModel.loading = false
                                        }
                                        
                                        self.viewModel.territoryToDelete = (nil,nil)
                                        self.viewModel.showToast = true
                                        dismissLastPopup()
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
    }
    
    func configurePopup(config: CentrePopupConfig) -> CentrePopupConfig {
        config
            .popupHorizontalPadding(24)
        
        
    }
}

//MARK: - Custom Disclosure Group

struct CustomDisclosureGroup<Item: Identifiable & Equatable, Content: View>: View {
    let title: String
    let items: [Item]
    let content: (Item) -> Content
    
    // Unique storage key based on title
    private var storageKey: String {
        if title == "Other Territories" {
            return "expanded_OtherTerritories" // Static key for consistency
        }
        return "expanded_\(title.hashValue)"
    }
    
    @State private var isExpanded: Bool
    @State private var expandProgress: CGFloat
    
    init(
        title: String,
        items: [Item],
        isInitiallyExpanded: Bool? = nil, // Optional initial state
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.title = title
        self.items = items
        self.content = content
        
        // Check if a stored state exists in UserDefaults
        if title == "Other Territories" {
            // Special case for "Other Territories" with a static key
            if let storedState = UserDefaults.standard.object(forKey: "expanded_OtherTerritories") as? Bool {
                // Use stored state if it exists
                _isExpanded = State(initialValue: storedState)
                _expandProgress = State(initialValue: storedState ? 1 : 0)
            } else {
                // Otherwise, default to `isInitiallyExpanded` or true
                let initialState = isInitiallyExpanded ?? true
                _isExpanded = State(initialValue: initialState)
                _expandProgress = State(initialValue: initialState ? 1 : 0)
            }
        } else {
            // General case for dynamically generated groups
            if let storedState = UserDefaults.standard.object(forKey: "expanded_\(title.hashValue)") as? Bool {
                // Use stored state if it exists
                _isExpanded = State(initialValue: storedState)
                _expandProgress = State(initialValue: storedState ? 1 : 0)
            } else {
                // Otherwise, default to `isInitiallyExpanded` or true
                let initialState = isInitiallyExpanded ?? true
                _isExpanded = State(initialValue: initialState)
                _expandProgress = State(initialValue: initialState ? 1 : 0)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.sophisticated) {
                    isExpanded.toggle()
                    expandProgress = isExpanded ? 1 : 0
                    
                    // Persist state
                    UserDefaults.standard.set(isExpanded, forKey: storageKey)
                }
            }) {
                HStack {
                    Text(title)
                        .font(.title2)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .fontWeight(.bold)
                        .hSpacing(.leading)
                    //.padding(5)
                        .padding(.horizontal, 10)
                    
                    Spacer()
                    
                    // Animated Chevron
                    Image(systemName: "chevron.right")
                        .foregroundColor(.primary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .scaleEffect(1 + (0.2 * sin(expandProgress * .pi)))
                        .padding(.trailing, 15)
                }
                //.padding(5)
                .contentShape(Rectangle()) // Makes the entire HStack tappable
            }
            .buttonStyle(PlainButtonStyle())
            .modifier(ScrollTransitionModifier())
            
            // Expandable Content
            if isExpanded {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(items) { item in
                        content(item)
                            .transition(
                                .asymmetric(
                                    insertion: AnyTransition.scale(scale: 0.9)
                                        .combined(with: .opacity)
                                        .animation(.spring(response: 0.5, dampingFraction: 0.6).speed(0.8)),
                                    removal: AnyTransition.scale(scale: 0.9)
                                        .combined(with: .opacity)
                                        .animation(.spring(response: 0.5, dampingFraction: 0.6).speed(0.8))
                                )
                            )
                            .transition(.customBackInsertion)
                            .animation(.spring(), value: items)
                            .opacity(expandProgress)
                            .scaleEffect(0.95 + (0.05 * expandProgress), anchor: .top)
                            .offset(y: 10 * (1 - expandProgress))
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8)
                                .delay(Double(items.firstIndex(where: { $0.id == item.id }) ?? 0) * 0.08),
                                value: expandProgress
                            )
                            .id(item.id)
                        
                    }
                }
                .transition(
                    .asymmetric(
                        insertion: AnyTransition.scale(scale: 0.9)
                            .combined(with: .opacity)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7)),
                        removal: AnyTransition.scale(scale: 0.9)
                            .combined(with: .opacity)
                            .animation(.spring(response: 0.5, dampingFraction: 1))
                    )
                )
                .padding(.top, 4)
            }
        }
        .clipped()
    }
}
