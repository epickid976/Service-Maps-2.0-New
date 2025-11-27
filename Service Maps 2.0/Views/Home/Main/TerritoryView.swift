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
import CryptoKit

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
    @State private var hasAnimatedRecent = false
    @State private var dominoStartDelay: Double? = 0.25
    @State private var viewAppeared = false
    
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
//                                                    GlassmorphicDailyTextCard()
//                                                            .padding(.top)
//                                                            .modifier(ScrollTransitionModifier())
                                                    
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
                                                            HStack(spacing: 12) {
                                                                ForEach(viewModel.recentTerritoryData!.enumerated().map({ $0 }), id: \.element.id) { index, territoryData in
                                                                    RecentTerritoryCellView(
                                                                        territoryData: territoryData,
                                                                        mainWindowSize: proxy.size,
                                                                        index: index,
                                                                        viewModel: viewModel,
                                                                        dominoStartDelay: dominoStartDelay
                                                                    )
                                                                }
                                                            }
                                                            .padding(.leading, 10)
                                                            .frame(height: 70)
                                                        }
                                                        .frame(height: 70)
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
                                    if #available(iOS 26.0, *) {
                                        if viewModel.territoryIdToScrollTo != nil {
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
                                        }
                                    } else {
                                        HStack {
                                            if viewModel.territoryIdToScrollTo != nil {
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
                                        Button("", action: { viewModel.syncAnimation = true; synchronizationManager.startupProcess(synchronizing: true) })
                                            .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $viewModel.dataStore.synchronized, lastTime: $viewModel.dataStore.lastTime))
                                            .padding(.leading, viewModel.territoryData == nil || dataStore.synchronized ? 0 : 50)
                                    }
                                }
                                ToolbarItemGroup(placement: .topBarTrailing) {
                                    if #available(iOS 26.0, *) {
                                        if viewModel.territoryData == nil || dataStore.synchronized {
                                            if viewModel.territoryIdToScrollTo == nil {
                                                Button(action: {
                                                    HapticManager.shared.trigger(.lightImpact)
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                                        withAnimation(.spring()) {
                                                            isCircleExpanded = true
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                                viewModel.backAnimation.toggle()
                                                                searchViewDestination = true
                                                            }
                                                        }
                                                    }
                                                }) {
                                                    Image(systemName: "magnifyingglass")
                                                }
                                            }
                                        }
                                    } else {
                                        if viewModel.territoryData == nil || dataStore.synchronized {
                                            if viewModel.territoryIdToScrollTo == nil {
                                                Button("", action: { HapticManager.shared.trigger(.lightImpact) ;
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
                                            Task {
                                                await CenterPopup_DeleteTerritoryAlert(viewModel: viewModel){
                                                    let toast = ToastValue(
                                                        icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                                        message: NSLocalizedString("Territory Deleted", comment: "")
                                                    )
                                                    presentToast(toast)
                                                }.present()
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
                        context.state.wrappedValue = .closed
                        self.viewModel.territoryToDelete = (territoryData.territory.id, String(territoryData.territory.number))
                        Task {
                            await CenterPopup_DeleteTerritoryAlert(viewModel: viewModel){
                                let toast = ToastValue(
                                    icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                    message: NSLocalizedString("Territory Deleted", comment: "")
                                )
                                presentToast(toast)
                            }.present()
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

//MARK: - Main Button

struct MainButton: View {
    
    var imageName: String
    var colorHex: String
    var width: CGFloat = 50
    var action: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        ZStack {
            if #available(iOS 26.0, *) {
                // iOS 26+ with glass effect and blue-teal gradient tint
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .teal]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ).opacity(0.3)
                        )
                        .frame(width: width, height: width)
                        .glassEffect(.regular.interactive())
                    Image(systemName: imageName)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .teal]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .font(.system(size: width * 0.4, weight: .semibold))
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
            } else {
                // iOS 25 and below with colored background
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
}

//MARK: - Delete Territory Popup

struct CenterPopup_DeleteTerritoryAlert: CenterPopup {
    @ObservedObject var viewModel: TerritoryViewModel
    var onDone: () -> Void

    init(viewModel: TerritoryViewModel, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        viewModel.loading = false
        self.onDone = onDone
    }

    var body: some View {
        createContent()
    }

    func createContent() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "map.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundColor(.red)

            Text("Delete Territory \(viewModel.territoryToDelete.1 ?? "0")")
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            Text("Are you sure you want to delete the selected territory?")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if viewModel.ifFailed {
                Text("Error deleting territory, please try again later")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                CustomBackButton(showImage: true, text: NSLocalizedString("Cancel", comment: "")) {
                    HapticManager.shared.trigger(.lightImpact)
                    withAnimation {
                        self.viewModel.territoryToDelete = (nil, nil)
                    }
                    Task {
                        await dismissLastPopup()
                    }
                }
                .frame(maxWidth: .infinity)

                CustomButton(
                    loading: viewModel.loading,
                    title: NSLocalizedString("Delete", comment: ""),
                    color: .red
                ) {
                    HapticManager.shared.trigger(.lightImpact)
                    withAnimation { self.viewModel.loading = true }

                    Task {
                        if let id = viewModel.territoryToDelete.0 {
                            switch await viewModel.deleteTerritory(territory: id) {
                            case .success:
                                HapticManager.shared.trigger(.success)
                                withAnimation {
                                    viewModel.removeTerritoryLocally(withId: id)
                                    viewModel.territoryToDelete = (nil, nil)
                                    viewModel.showToast = true
                                }
                                await dismissLastPopup()
                                onDone()
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

//MARK: - Custom Disclosure Group
struct CustomDisclosureGroup<Item: Identifiable & Equatable, Content: View>: View {
    let title: String
    let items: [Item]
    let content: (Item) -> Content

    private let storageKey: String
    @State private var isExpanded: Bool
    @State private var expandProgress: CGFloat

    init(
        title: String,
        items: [Item],
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.title = title
        self.items = items
        self.content = content

        // Create a stable hash (you could also just sanitize the title string directly)
        let hashedKey = title == "Other Territories"
            ? "expanded_OtherTerritories"
            : "expanded_" + title.replacingOccurrences(of: " ", with: "_")

        self.storageKey = hashedKey

        let saved = UserDefaults.standard.object(forKey: self.storageKey) as? Bool ?? true
        _isExpanded = State(initialValue: saved)
        _expandProgress = State(initialValue: saved ? 1 : 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: toggleExpansion) {
                HStack {
                    Text(title)
                        .font(.title2)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .fontWeight(.bold)
                        .hSpacing(.leading)
                        .padding(.horizontal, 10)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.primary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .scaleEffect(isExpanded ? 1.1 : 1.0)
                        .padding(.trailing, 15)
                        .animation(.interpolatingSpring(stiffness: 250, damping: 30), value: isExpanded)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .modifier(ScrollTransitionModifier())

            if isExpanded {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(items) { item in
                        content(item)
                            .transition(.scale.combined(with: .opacity))
                            .animation(
                                .interpolatingSpring(stiffness: 280, damping: 32)
                                    .delay(Double(items.firstIndex(where: { $0.id == item.id }) ?? 0) * 0.03),
                                value: items
                            )
                            .id(item.id)
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .clipped()
    }

    private func toggleExpansion() {
        withAnimation(.interpolatingSpring(stiffness: 250, damping: 30)) {
            isExpanded.toggle()
            expandProgress = isExpanded ? 1 : 0
            UserDefaults.standard.set(isExpanded, forKey: storageKey)
        }
    }
}

import SwiftUI
import Foundation
import SwiftSoup

// MARK: - Daily Text Fetcher

@MainActor
class DailyTextFetcher: ObservableObject {
    @Published var dailyText: String = "Loading..."
    @Published var fullExplanation: String = ""
    @Published var dateHeader: String = ""
    @Published var verseHeader: String = ""

    private(set) var currentDate: Date = Date()

    private struct LanguageConfig {
        let langCode: String  // URL language code
        let pubId: String     // Publication ID
        let lpCode: String    // Language publication code
    }

    private let supportedLanguages: [String: LanguageConfig] = [
        "en": LanguageConfig(langCode: "en", pubId: "r1", lpCode: "e"),
        "es": LanguageConfig(langCode: "es", pubId: "r4", lpCode: "s"),
        "fr": LanguageConfig(langCode: "fr", pubId: "r30", lpCode: "f")
    ]

    func fetch(for date: Date = Date()) {
        currentDate = date

        let languageIdentifier = Locale.current.languageCode ?? "en"
        let config = supportedLanguages[languageIdentifier] ?? supportedLanguages["en"]!

        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        let urlString = "https://wol.jw.org/\(config.langCode)/wol/dt/\(config.pubId)/lp-\(config.lpCode)/\(year)/\(month)/\(day)"
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL.")
            return
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                print("❌ Could not load or decode data.")
                return
            }

            do {
                let doc = try SwiftSoup.parse(html)

                let header = try doc.select("h2").first()?.text() ?? "Date not found"
                let verse = try doc.select("p.themeScrp").first()?.text() ?? "Verse not found"
                let explanation = try doc.select("div.bodyTxt p.sb").first()?.text() ?? "Explanation not found"

                DispatchQueue.main.async {
                    self.dateHeader = header
                    self.verseHeader = verse
                    self.fullExplanation = explanation
                    self.dailyText = "\(header)\n\(verse)"
                }
            } catch {
                print("❌ HTML parsing error: \(error)")
            }
        }.resume()
    }

    func fetchToday() {
        fetch(for: Date())
    }

    func fetchNextDay() {
        guard let next = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) else { return }
        fetch(for: next)
    }

    func fetchPreviousDay() {
        guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) else { return }
        fetch(for: prev)
    }
}

struct GlassmorphicDailyTextCard: View {
    @StateObject private var fetcher = DailyTextFetcher()
    @State private var showFullSheet = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(fetcher.dateHeader)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [.white, .white.opacity(0.8)]
                            : [.primary, .primary.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(fetcher.verseHeader)
                .font(.system(.callout, design: .serif))
                .italic()
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack {
                Spacer()
                Label("Tap to read more", systemImage: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(0.8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(glassMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(strokeColor, lineWidth: 0.8)
                )
                .shadow(
                    color: colorScheme == .dark
                        ? .black.opacity(0.25)
                        : .black.opacity(0.08),
                    radius: 10,
                    x: 0,
                    y: 4
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .onTapGesture {
            withAnimation(.spring()) {
                showFullSheet.toggle()
            }
        }
        .onAppear {
            fetcher.fetchToday()
        }
        .sheet(isPresented: $showFullSheet, onDismiss: {
            fetcher.fetchToday()
        }) {
            GlassmorphicTextDetailSheet(fetcher: fetcher)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .padding(.horizontal, 20)
    }

    private var glassMaterial: some ShapeStyle {
        colorScheme == .dark
            ? AnyShapeStyle(.ultraThinMaterial.opacity(0.8))
            : AnyShapeStyle(.regularMaterial.opacity(0.7))
    }

    private var strokeColor: Color {
        colorScheme == .dark
            ? .white.opacity(0.12)
            : .black.opacity(0.08)
    }
}

struct GlassmorphicTextDetailSheet: View {
    @ObservedObject var fetcher: DailyTextFetcher
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var scrollOffset: CGFloat = 0
    @State private var transitionOffset: CGFloat = 0

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    // Top Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Daily Reflection")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .tracking(1)

                            Text(fetcher.dateHeader)
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .foregroundStyle(titleGradient)
                        }

                        Spacer()

                        HStack(spacing: 12) {
                            Button(action: {
                                let direction: CGFloat = fetcher.currentDate < Date() ? -1 : 1
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    transitionOffset = direction * UIScreen.main.bounds.width
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    fetcher.fetchToday()
                                    transitionOffset = -direction * UIScreen.main.bounds.width
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        transitionOffset = 0
                                    }
                                }
                            }) {
                                Image(systemName: "calendar")
                            }

                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dismiss()
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(.title3, weight: .medium))
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        .frame(height: 32)
                        .padding(.horizontal, 4)
                        .background(Circle().fill(closeButtonBackground))
                    }
                    .padding(.top, 8)

                    // Verse
                    VStack(alignment: .leading, spacing: 12) {
                        Text(fetcher.verseHeader)
                            .font(.system(.title3, design: .serif, weight: .medium))
                            .italic()
                            .foregroundStyle(titleGradient)
                            .multilineTextAlignment(.leading)
                            .textSelection(.enabled) // ✅
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(strokeColor, lineWidth: 0.5)
                            )
                    )

                    // Explanation
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "quote.opening")
                                .font(.system(.caption, weight: .medium))
                                .foregroundColor(.secondary)

                            Text("Reflection")
                                .font(.system(.headline, design: .rounded, weight: .semibold))
                                .foregroundColor(.secondary)

                            Spacer()
                        }

                        Text(fetcher.fullExplanation)
                            .font(.system(.body, design: .default))
                            .foregroundColor(.primary.opacity(0.9))
                            .lineSpacing(4)
                            .multilineTextAlignment(.leading)
                            .textSelection(.enabled) // ✅
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(strokeColor, lineWidth: 0.5)
                            )
                    )

                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(key: ScrollOffsetPreferenceKey.self,
                                               value: geometry.frame(in: .named("scroll")).minY)
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height),
                              abs(value.translation.width) > 50 else { return }

                        let isLeftSwipe = value.translation.width < 0
                        let offset: CGFloat = isLeftSwipe ? -UIScreen.main.bounds.width : UIScreen.main.bounds.width

                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.25)) {
                            transitionOffset = offset
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            if isLeftSwipe {
                                fetcher.fetchNextDay()
                            } else {
                                fetcher.fetchPreviousDay()
                            }

                            transitionOffset = -offset
                            withAnimation(.easeInOut(duration: 0.25)) {
                                transitionOffset = 0
                            }
                        }
                    }
            )
        }
        .offset(x: transitionOffset)
    }

    // MARK: - Styling Helpers

    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color.black.opacity(0.9), Color.black.opacity(0.7)]
                : [Color(UIColor.systemBackground).opacity(0.95), Color.gray.opacity(0.1)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var titleGradient: some ShapeStyle {
        LinearGradient(
            colors: colorScheme == .dark
                ? [.white, .white.opacity(0.8)]
                : [.primary, .primary.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardBackground: some ShapeStyle {
        colorScheme == .dark
            ? AnyShapeStyle(.ultraThinMaterial.opacity(0.6))
            : AnyShapeStyle(.thinMaterial.opacity(0.8))
    }

    private var closeButtonBackground: some ShapeStyle {
        colorScheme == .dark
            ? AnyShapeStyle(.ultraThinMaterial.opacity(0.7))
            : AnyShapeStyle(.regularMaterial.opacity(0.8))
    }

    private var strokeColor: Color {
        colorScheme == .dark
            ? .white.opacity(0.12)
            : .black.opacity(0.08)
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
