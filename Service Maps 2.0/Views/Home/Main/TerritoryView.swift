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


struct TerritoryView: View {
    @Environment(\.dismissSearch) private var dismissSearch
    
    @StateObject var viewModel: TerritoryViewModel
    
    //@Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    @Environment(\.presentationMode) var presentationMode
    
    @State var searchViewDestination = false
    
    init(territoryIdToScrollTo: String? = nil) {
        let viewModel = TerritoryViewModel(territoryIdToScrollTo: territoryIdToScrollTo)
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    let alertViewDeleted = AlertAppleMusic17View(title: "Territory Deleted", subtitle: nil, icon: .custom(UIImage(systemName: "trash")!))
    let alertViewAdded = AlertAppleMusic17View(title: "Territory Added", subtitle: nil, icon: .done)
    
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    let minimumOffset: CGFloat = 60
    
    @State private var highlightedTerritoryId: String?
    
    @ObservedObject var preferencesViewModel = ColumnViewModel()
    
    @State var isCircleExpanded = false
    //@Environment(\.mainWindowSize) var mainWindowSize
    var body: some View {
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
                                                                    NavigationLink(destination: NavigationLazyView(TerritoryAddressView(territory: territoryData.territory))) {
                                                                        recentCell(territoryData: territoryData, mainWindowSize: proxy.size).transition(.customBackInsertion)
                                                                    }.onTapHaptic(.lightImpact)
                                                                }
                                                            }
                                                        }.padding(.leading).scrollIndicators(.never)
                                                        
                                                    }.modifier(ScrollTransitionModifier())
                                                        .animation(.smooth, value: viewModel.recentTerritoryData == nil || viewModel.recentTerritoryData != nil)
                                                }
                                            }
                                            
                                            
                                            SwipeViewGroup {
                                                ForEach(viewModel.territoryData ?? [], id: \.id) { dataWithKeys in
                                                    if UIDevice().userInterfaceIdiom == .pad && proxy.size.width > 400 && preferencesViewModel.isColumnViewEnabled {
                                                        territoryHeader(dataWithKeys: dataWithKeys)
                                                            .modifier(ScrollTransitionModifier())
                                                        
                                                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                                            ForEach(dataWithKeys.territoriesData, id: \.territory.id) { territoryData in
                                                                territoryCell(dataWithKeys: dataWithKeys, territoryData: territoryData, mainViewSize: proxy.size)
                                                                    .id(territoryData.territory.id) // Ensure unique ID here
                                                                    .transition(.move(edge: .leading)) // Apply a move transition on the cell
                                                                    .animation(.spring(), value: dataWithKeys.territoriesData) // Only animate this specific cell's change
                                                            }
                                                        }
                                                    } else {
                                                        territoryHeader(dataWithKeys: dataWithKeys)
                                                            .modifier(ScrollTransitionModifier())
                                                        
                                                        LazyVGrid(columns: [GridItem(.flexible())]) {
                                                            ForEach(dataWithKeys.territoriesData, id: \.territory.id) { territoryData in
                                                                territoryCell(dataWithKeys: dataWithKeys, territoryData: territoryData, mainViewSize: proxy.size)
                                                                    .id(territoryData.territory.id) // Ensure unique ID here
                                                                    .transition(.move(edge: .leading)) // Apply a move transition
                                                                    .animation(.spring(), value: dataWithKeys.territoriesData) // Only animate this specific cell
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
                            .animation(.easeInOut(duration: 0.25), value: viewModel.territoryData == nil || viewModel.territoryData != nil)
                            .alert(isPresent: $viewModel.showToast, view: alertViewDeleted)
                            .alert(isPresent: $viewModel.showAddedToast, view: alertViewAdded)
                            .navigationDestination(isPresented: $viewModel.presentSheet) {
                                AddTerritoryView(territory: viewModel.currentTerritory) {
                                    DispatchQueue.main.async {
                                        // withAnimation {
                                        // viewModel.getTerritories()
                                        // }
                                    }
                                    DispatchQueue.main.async {
                                        viewModel.showAddedToast = true
                                    }
                                    
                                    
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
                                        
                                        Button("", action: { viewModel.syncAnimation.toggle(); synchronizationManager.startupProcess(synchronizing: true) })//.keyboardShortcut("s", modifiers: .command)
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
                                                    //}
                                                    
                                                }).scaleEffect(viewModel.territoryData == nil || dataStore.synchronized ? 1 : 0)
                                                    .buttonStyle(CircleButtonStyle(imageName: "magnifyingglass", background: .white.opacity(0), width: !isCircleExpanded ? 40 : proxy.size.width * 4, height: !isCircleExpanded ? 40 : proxy.size.height * 4, progress: $viewModel.progress, animation: $viewModel.backAnimation)).transition(.scale).padding(.top, isCircleExpanded ? 1000 : 0)
                                                    .animation(.spring(), value: isCircleExpanded)
                                                
                                                
                                                
                                            }
                                        }
                                    }.animation(.spring(), value: viewModel.territoryData == nil || viewModel.dataStore.synchronized)
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
                        //.keyboardShortcut("+", modifiers: .command)
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
    
    @ViewBuilder
    func territoryCell(dataWithKeys: TerritoryDataWithKeys, territoryData: TerritoryData, mainViewSize: CGSize) -> some View {
        LazyVStack {
            SwipeView {
                NavigationLink(destination: NavigationLazyView(TerritoryAddressView(territory: territoryData.territory))) {
                    CellView(territory: territoryData.territory, houseQuantity: territoryData.housesQuantity, mainWindowSize: mainViewSize)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16) // Same shape as the cell
                                .fill(highlightedTerritoryId == territoryData.territory.id ? Color.gray.opacity(0.5) : Color.clear)
                                .animation(.default, value: highlightedTerritoryId == territoryData.territory.id)
                        )
                        .padding(.bottom, 2)
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
                                            DispatchQueue.main.async {
                                                CentrePopup_DeleteTerritoryAlert(viewModel: viewModel).present()
                                            }
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
                        DispatchQueue.main.async {
                            context.state.wrappedValue = .closed
                            self.viewModel.territoryToDelete = (territoryData.territory.id, String(territoryData.territory.number))
                            CentrePopup_DeleteTerritoryAlert(viewModel: viewModel).present()
                        }
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


struct MainButton: View {
    
    var imageName: String
    var colorHex: String
    var width: CGFloat = 50
    var action: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        ZStack {
            //if StorageManager.shared.synchronized {
            
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
            //}
        }//.animation(.spring(), value: StorageManager.shared.synchronized)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ViewOffsetKey: PreferenceKey, Sendable {
    typealias Value = CGFloat
    static let defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct CentrePopup_DeleteTerritoryAlert: CentrePopup {
    @ObservedObject var viewModel: TerritoryViewModel
    
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
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                                            dismissLastPopup()
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
    }
    
    func configurePopup(config: CentrePopupConfig) -> CentrePopupConfig {
        config
            .popupHorizontalPadding(24)
            
            
    }
}

struct ScrollTransitionModifier: ViewModifier {
    @Environment(\.isScrollEnabled) var isScrollEnabled: Bool // Detect if scroll is active (iOS 16)
    @State private var opacity: Double = 1.0 // Local state for opacity (iOS 16)
    @State private var scale: CGFloat = 1.0 // Local state for scale (iOS 16)
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.scrollTransition { content, phase in
                content
                    .opacity(phase.isIdentity || phase == .bottomTrailing ? 1 : 0)
                    .scaleEffect(phase.isIdentity || phase == .bottomTrailing ? 1 : 0.75)
            }
        } else {
            content
        }
    }
}

extension AnyTransition {
    static var customBackInsertion: AnyTransition {
        AnyTransition.asymmetric(
            insertion: AnyTransition.opacity
                .combined(with: .scale(scale: 0.8, anchor: .center))
                .combined(with: .move(edge: .bottom)),
            removal: .opacity
        )
        .animation(.spring())
    }
}
