//
//  HousesView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/28/23.
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

//MARK: - HousesView

struct HousesView: View {
    var address: TerritoryAddress
    
    //MARK: - Environment
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.presentToast) var presentToast
    
    //MARK: - Dependencies
    
    @StateObject var viewModel: HousesViewModel
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var preferencesViewModel = ColumnViewModel()
    
    //MARK: - Properties
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    @State var showFab = true
    @State var scrollOffset: CGFloat = 0.00
    
    
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    let minimumOffset: CGFloat = 60
    
    @State var highlightedHouseId: String?
    
    //MARK: - Initializers
    
    init(address: TerritoryAddress, houseIdToScrollTo: String? = nil) {
        self.address = address
        let initialViewModel = HousesViewModel(territoryAddress: address, houseIdToScrollTo: houseIdToScrollTo)
        _viewModel = StateObject(wrappedValue: initialViewModel)
        
    }
    
    //MARK: - Body
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ScrollViewReader { scrollViewProxy in
                    ScrollView {
                        LazyVStack {
                            if viewModel.houseData == nil && !dataStore.synchronized {
                                Group {
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
                                }
                                .transition(.opacity)
                                .id("loadingView")
                            } else {
                                if let data = viewModel.houseData {
                                    if data.isEmpty {
                                        Group {
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
                                        .transition(.opacity)
                                        .id("emptyView")
                                    } else {
                                        SwipeViewGroup {
                                            if UIDevice().userInterfaceIdiom == .pad && proxy.size.width > 400 && preferencesViewModel.isColumnViewEnabled {
                                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                                    let proxy = CGSize(width: proxy.size.width / 2 - 16, height: proxy.size.height)
                                                    ForEach(viewModel.houseData!, id: \.house.id) { houseData in
                                                        houseCellView(houseData: houseData, mainWindowSize: proxy)
                                                            .id(houseData.house.id)
                                                            .modifier(ScrollTransitionModifier())
                                                            .transition(.customBackInsertion)
                                                    }.modifier(ScrollTransitionModifier())
                                                }
                                            } else {
                                                LazyVGrid(columns: [GridItem(.flexible())]) {
                                                    ForEach(viewModel.houseData!, id: \.house.id) { houseData in
                                                        houseCellView(houseData: houseData, mainWindowSize: proxy.size)
                                                            .id(houseData.house.id)
                                                            .modifier(ScrollTransitionModifier())
                                                            .transition(.customBackInsertion)
                                                    }.modifier(ScrollTransitionModifier())
                                                }
                                            }
                                        }
                                        .animation(.spring(), value: viewModel.houseData!)
                                        .padding()
                                        .transition(.opacity)
                                        .id("listView")
                                    }
                                }
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: viewModel.houseData)
                        .background(GeometryReader {
                            Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                        })
                        .onPreferenceChange(ViewOffsetKey.self) { currentOffset in
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
                        .animation(.easeInOut(duration: 0.25), value: viewModel.houseData == nil || viewModel.houseData != nil)
                        .onChange(of: viewModel.presentSheet) { value in
                            if value {
                                Task {
                                    await CenterPopup_AddHouse(viewModel: viewModel, address: address){
                                        let toast = ToastValue(
                                            icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green),
                                            message: "House Added"
                                        )
                                        presentToast(toast)
                                    }.present()
                                }
                            }
                        }
                        .navigationBarTitle(address.address, displayMode: .automatic)
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
                            // MARK: - Trailing – iOS 26+ broken into 2 groups
                            if #available(iOS 26.0, *) {
                                
                                // LEFT PART of trailing: Sync pill
                                ToolbarItemGroup(placement: .primaryAction) {
                                    SyncPillButton(
                                        synced: dataStore.synchronized,
                                        lastTime: dataStore.lastTime
                                    ) {
                                        HapticManager.shared.trigger(.lightImpact)
                                        synchronizationManager.startupProcess(synchronizing: true)
                                    }
                                }
                                
                                // SPACE between pill and filter menu
                                ToolbarSpacer(.flexible, placement: .primaryAction)
                                
                                // RIGHT PART of trailing: Filter Menu
                                ToolbarItemGroup(placement: .primaryAction) {
                                    Menu {
                                        Button {
                                            HapticManager.shared.trigger(.lightImpact)
                                            Task {
                                                await  CenterPopup_FilterInfo().present()
                                            }
                                        } label: {
                                            Label {
                                                Text("Info")
                                            } icon: {
                                                Image(systemName: "questionmark.circle")
                                            }
                                        }
                                        
                                        Picker(selection: $viewModel.sortPredicate) {
                                            ForEach(HouseSortPredicate.allCases, id: \.self) { option in
                                                Text(option.localized)
                                            }
                                        } label: {
                                            Label {
                                                Text("Sort by Order")
                                            } icon: {
                                                Image(systemName: "arrow.up.arrow.down.circle")
                                            }
                                        }
                                        .pickerStyle(.menu)

                                        Picker(selection: $viewModel.filterPredicate) {
                                            ForEach(HouseFilterPredicate.allCases, id: \.self) { option in
                                                Text(option.localized)
                                            }
                                        } label: {
                                            Label {
                                                Text("Sort by Grouping")
                                            } icon: {
                                                Image(systemName: "rectangle.3.group.bubble.left")
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        
                                        Divider()
                                        
                                        Text("Filter by Symbol").font(.headline)
                                        
                                        let orderedSymbols: [Symbols] = [
                                            .NC, .NT, .V,
                                            .H, .M, .N,
                                            .OV, .MV, .HV,
                                            .none
                                        ]

                                        let symbolGroups = orderedSymbols.chunked(into: 3)

                                        ForEach(symbolGroups, id: \.self) { group in
                                            ControlGroup {
                                                ForEach(group) { symbol in
                                                    Button {
                                                        if viewModel.selectedSymbols.contains(symbol) {
                                                            viewModel.selectedSymbols.remove(symbol)
                                                        } else {
                                                            viewModel.selectedSymbols.insert(symbol)
                                                        }
                                                        viewModel.getHouses()
                                                    } label: {
                                                        Label(symbol.legend, systemImage: viewModel.selectedSymbols.contains(symbol) ? "checkmark.circle.fill" : "circle")
                                                    }
                                                }
                                            }
                                        }
                                        
                                        Button("Clear Symbols") {
                                            viewModel.selectedSymbols.removeAll()
                                            viewModel.getHouses()
                                        }
                                    } label: {
                                        Image(systemName: "line.3.horizontal.decrease")
                                    }
                                }
                            } else {
                                // iOS 25 and below: Single ToolbarItemGroup with HStack
                                ToolbarItemGroup(placement: .topBarTrailing) {
                                    HStack {
                                        Button("", action: { viewModel.syncAnimation = true; synchronizationManager.startupProcess(synchronizing: true) })
                                            .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $dataStore.synchronized, lastTime: $dataStore.lastTime))
                                        
                                        Menu {
                                            Button {
                                                HapticManager.shared.trigger(.lightImpact)
                                                Task {
                                                    await  CenterPopup_FilterInfo().present()
                                                }
                                            } label: {
                                                Label {
                                                    Text("Info")
                                                } icon: {
                                                    Image(systemName: "questionmark.circle")
                                                }
                                            }
                                            
                                            Picker(selection: $viewModel.sortPredicate) {
                                                ForEach(HouseSortPredicate.allCases, id: \.self) { option in
                                                    Text(option.localized)
                                                }
                                            } label: {
                                                Label {
                                                    Text("Sort by Order")
                                                } icon: {
                                                    Image(systemName: "arrow.up.arrow.down.circle")
                                                }
                                            }
                                            .pickerStyle(.menu)

                                            Picker(selection: $viewModel.filterPredicate) {
                                                ForEach(HouseFilterPredicate.allCases, id: \.self) { option in
                                                    Text(option.localized)
                                                }
                                            } label: {
                                                Label {
                                                    Text("Sort by Grouping")
                                                } icon: {
                                                    Image(systemName: "rectangle.3.group.bubble.left")
                                                }
                                            }
                                            .pickerStyle(.menu)
                                            
                                            Divider()
                                            
                                            Text("Filter by Symbol").font(.headline)
                                            
                                            let orderedSymbols: [Symbols] = [
                                                .NC, .NT, .V,
                                                .H, .M, .N,
                                                .OV, .MV, .HV,
                                                .none
                                            ]

                                            let symbolGroups = orderedSymbols.chunked(into: 3)

                                            ForEach(symbolGroups, id: \.self) { group in
                                                ControlGroup {
                                                    ForEach(group) { symbol in
                                                        Button {
                                                            if viewModel.selectedSymbols.contains(symbol) {
                                                                viewModel.selectedSymbols.remove(symbol)
                                                            } else {
                                                                viewModel.selectedSymbols.insert(symbol)
                                                            }
                                                            viewModel.getHouses()
                                                        } label: {
                                                            Label(symbol.legend, systemImage: viewModel.selectedSymbols.contains(symbol) ? "checkmark.circle.fill" : "circle")
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            Button("Clear Symbols") {
                                                viewModel.selectedSymbols.removeAll()
                                                viewModel.getHouses()
                                            }
                                        } label: {
                                            Button("", action: {
                                                viewModel.optionsAnimation.toggle()
                                                HapticManager.shared.trigger(.lightImpact)
                                                viewModel.presentSheet.toggle()
                                            })
                                            .buttonStyle(CircleButtonStyle(
                                                imageName: "line.3.horizontal.decrease",
                                                background: .white.opacity(0),
                                                width: 40,
                                                height: 40,
                                                progress: $viewModel.progress,
                                                animation: $viewModel.optionsAnimation
                                            ))
                                        }
                                    }
                                }
                            }
                        }
                        .navigationTransition(viewModel.presentSheet || viewModel.houseIdToScrollTo != nil ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
                        .navigationViewStyle(StackNavigationViewStyle())
                    }.coordinateSpace(name: "scroll")
                        .scrollIndicators(.never)
                        .refreshable {
                            synchronizationManager.startupProcess(synchronizing: true)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                hideFloatingButton = false
                            }
                        }
                        .onChange(of: viewModel.houseIdToScrollTo) { id in
                            if let id = id {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        scrollViewProxy.scrollTo(id, anchor: .center)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            HapticManager.shared.trigger(.selectionChanged)
                                            highlightedHouseId = id // Highlight after scrolling
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            highlightedHouseId = nil
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
                    .fabImplode(isHidden: hideFloatingButton)
                    .vSpacing(.bottom).hSpacing(.trailing)
                    .padding()
                }
                
            }
        }
    }
    
    //MARK: - House Cell View
    
    @ViewBuilder
    func houseCellView(houseData: HouseData, mainWindowSize: CGSize) -> some View {
        SwipeView {
            NavigationLink(destination: NavigationLazyView(VisitsView(house: houseData.house).installToast(position: .bottom))) {
                HouseCell(house: houseData, mainWindowSize: mainWindowSize)
                    .padding(.bottom, 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16) // Same shape as the cell
                            .fill(highlightedHouseId == houseData.house.id ? Color.gray.opacity(0.5) : Color.clear).animation(.default, value: highlightedHouseId == houseData.house.id) // Fill with transparent gray if highlighted
                    )
                    .optionalViewModifier { content in
                        if AuthorizationLevelManager().existsAdminCredentials() {
                            content
                                .contextMenu {
                                    Button {
                                        HapticManager.shared.trigger(.lightImpact)
                                        DispatchQueue.main.async {
                                            self.viewModel.houseToDelete = (houseData.house.id, houseData.house.number)
                                            //self.showAlert = true
                                            if viewModel.houseToDelete.0 != nil && viewModel.houseToDelete.1 != nil {
                                                Task {
                                                    await CenterPopup_DeleteHouse(viewModel: viewModel) {
                                                        Task {
                                                            await dismissLastPopup()
                                                        }
                                                        let toast = ToastValue(
                                                            icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                                            message: NSLocalizedString("House Deleted", comment: "")
                                                        )
                                                        presentToast(toast)
                                                    }.present()
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "trash")
                                            Text("Delete House")
                                        }
                                    }
                                    //TODO Trash and Pencil only if admin
                                }.clipShape(RoundedRectangle(cornerRadius: 16, style: .circular))
                        } else {
                            content
                        }
                    }
                
            }.onTapHaptic(.lightImpact)
        } leadingActions: { context in
            SwipeAction(
                systemImage: "pencil.tip.crop.circle.badge.plus.fill",
                backgroundColor: .green
            ) {
                HapticManager.shared.trigger(.lightImpact)
                DispatchQueue.main.async {
                    context.state.wrappedValue = .closed
                    Task {
                        await CenterPopup_AddVisit(viewModel: VisitsViewModel(house: houseData.house), house: houseData.house
                        ) {
                            let toast = ToastValue(
                                icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green),
                                message: "Visit Added"
                            )
                            presentToast(toast)
                        }.present()
                    }
                }
            }
            .allowSwipeToTrigger()
            .font(.title.weight(.semibold))
            .foregroundColor(.white)
        } trailingActions: { context in
            if houseData.accessLevel == .Admin {
                SwipeAction(
                    systemImage: "trash",
                    backgroundColor: .red
                ) {
                    HapticManager.shared.trigger(.lightImpact)
                    DispatchQueue.main.async {
                        context.state.wrappedValue = .closed
                        self.viewModel.houseToDelete = (houseData.house.id, houseData.house.number)
                        //self.showAlert = true
                        if viewModel.houseToDelete.0 != nil && viewModel.houseToDelete.1 != nil {
                            Task {
                                await CenterPopup_DeleteHouse(viewModel: viewModel){
                                    Task {
                                        await dismissLastPopup()
                                    }
                                    let toast = ToastValue(
                                        icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                        message: NSLocalizedString("House Deleted", comment: "")
                                    )
                                    presentToast(toast)
                                }.present()
                            }
                        }
                    }
                }
                .font(.title.weight(.semibold))
                .foregroundColor(.white)
            }
        }
        .swipeActionCornerRadius(16)
        .swipeSpacing(5)
        .swipeOffsetCloseAnimation(stiffness: 500, damping: 100)
        .swipeOffsetExpandAnimation(stiffness: 500, damping: 100)
        .swipeOffsetTriggerAnimation(stiffness: 500, damping: 100)
        .swipeMinimumDistance(25)
        
    }
}

//MARK: - Delete House Popup

struct CenterPopup_DeleteHouse: CenterPopup {
    @ObservedObject var viewModel: HousesViewModel
    var onDone: () -> Void

    init(viewModel: HousesViewModel, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        viewModel.loading = false
        self.onDone = onDone
    }

    var body: some View {
        createContent()
    }

    func createContent() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "house.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundColor(.red)

            Text("Delete House \(viewModel.houseToDelete.1 ?? "0")")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text("Are you sure you want to delete the selected house?")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if viewModel.ifFailed {
                Text("Error deleting house, please try again later")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                if !viewModel.loading {
                    CustomBackButton(showImage: true, text: NSLocalizedString("Cancel", comment: "")) {
                        HapticManager.shared.trigger(.lightImpact)
                        withAnimation {
                            viewModel.houseToDelete = (nil, nil)
                        }
                        Task { await dismissLastPopup() }
                    }
                    .frame(maxWidth: .infinity)
                }

                CustomButton(loading: viewModel.loading, title: NSLocalizedString("Delete", comment: ""), color: .red) {
                    HapticManager.shared.trigger(.lightImpact)
                    withAnimation { viewModel.loading = true }

                    Task {
                        if let id = viewModel.houseToDelete.0 {
                            switch await viewModel.deleteHouse(house: id) {
                            case .success:
                                HapticManager.shared.trigger(.success)
                                viewModel.ifFailed = false
                                viewModel.houseToDelete = (nil, nil)
                                onDone()
                                await dismissLastPopup()
                            case .failure:
                                HapticManager.shared.trigger(.error)
                                viewModel.loading = false
                                viewModel.ifFailed = true
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

//MARK: - Add House Popup

struct CenterPopup_AddHouse: CenterPopup {
    @ObservedObject var viewModel: HousesViewModel
    @State var address: TerritoryAddress
    var onDone: () -> Void

    init(viewModel: HousesViewModel, address: TerritoryAddress, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.address = address
        self.onDone = onDone
    }

    var body: some View {
        AddHouseView(
            house: viewModel.currentHouse,
            address: address,
            onDone: {
                viewModel.presentSheet = false
                onDone()
                Task { await dismissLastPopup() }
            },
            onDismiss: {
                viewModel.presentSheet = false
                Task { await dismissLastPopup() }
            }
        )
        .padding()
        .background(Material.thin)
        .cornerRadius(20)
        .ignoresSafeArea(.keyboard)
        .simultaneousGesture(
            DragGesture().onChanged { _ in
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        )
    }

    func configurePopup(config: CenterPopupConfig) -> CenterPopupConfig {
        config.popupHorizontalPadding(24)
    }
}

// MARK: - Filter Info Popup

struct CenterPopup_FilterInfo: CenterPopup {
    @State var loading = false
    
    func configurePopup(config: CenterPopupConfig) -> CenterPopupConfig {
        config.popupHorizontalPadding(24)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filter Options Info")
                .font(.title2.bold())
            
            Group {
                Text("• Sort by Order – Sorts houses in increasing or decreasing order based on address number.")
                Text("• Sort by Grouping – Displays houses in normal order or groups them (e.g., odd numbers first, even numbers second).")
            }
            .font(.body)
            .fixedSize(horizontal: false, vertical: true)
            
            Divider().padding(.vertical, 8)
            
            Text("**Symbol Meanings**").font(.headline)
            
            LazyVGrid(columns: [GridItem(.fixed(50)), GridItem(.flexible()), GridItem(.fixed(50)), GridItem(.flexible())], spacing: 10) {
                let symbols = Symbols.allCases.filter { $0 != .none }
                
                ForEach(0..<symbols.count/2, id: \.self) { index in
                    let left = symbols[index]
                    let right = symbols[index + symbols.count/2]
                    
                    Group {
                        Text(left.localizedString)
                            .bold()
                            .frame(width: 50, alignment: .leading)
                        Text(left.legend)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(right.localizedString)
                            .bold()
                            .frame(width: 50, alignment: .leading)
                        Text(right.legend)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            HStack {
                Spacer()
                CustomButton(
                    loading: loading,
                    title: NSLocalizedString("Close", comment: ""),
                    color: .blue
                ) {
                    HapticManager.shared.trigger(.lightImpact)
                    Task {
                        await dismissLastPopup()
                    }
                }
            }
        }
        .padding()
        .background(Material.thin)
        .cornerRadius(15)
        .ignoresSafeArea(.keyboard)
    }
}
