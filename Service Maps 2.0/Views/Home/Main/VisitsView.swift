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
import SwiftTextRank
import Shimmer

//MARK: - VisitsView

struct VisitsView: View {
    
    //MARK: - Initializers
    
    init(house: House, visitIdToScrollTo: String? = nil) {
        self.house = house
        let initialViewModel = VisitsViewModel(house: house, visitIdToScrollTo: visitIdToScrollTo)
        _viewModel = StateObject(wrappedValue: initialViewModel)
    }
    
    var house: House
    
    //MARK: - Dependencies
    
    @StateObject var viewModel: VisitsViewModel
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var preferencesViewModel = ColumnViewModel()
    
    //MARK: - Environment
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.mainWindowSize) var mainWindowSize
    @Environment(\.presentToast) var presentToast
    
    //MARK: - Properties
    
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    @State var showFab = true
    @State var scrollOffset: CGFloat = 0.00
    @State private var isScrollingDown = false
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    @State var highlightedVisitId: String?
    @State private var isLoading = true
    @State private var hasRunAnimation = false
    
    let minimumOffset: CGFloat = 60
    @State private var visitSummary: String = ""
    //MARK: - Body
    
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
//                                        visitSummaryCard(visitSummary, isLoading: isLoading).padding(.top, 10)
//                                            .onAppear {
//                                                // Only run once per appearance
//                                                if !hasRunAnimation {
//                                                    hasRunAnimation = true
//                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
//                                                        withAnimation(.easeInOut(duration: 0.3)) {
//                                                            isLoading = false
//                                                        }
//                                                    }
//                                                }
//                                            }
                                        
                                        Divider()
                                            .padding(.horizontal)
                                            .padding(.top, 10)
                                            .padding(.bottom, -10)
                                        
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
                        .animation(.easeInOut(duration: 0.25), value: viewModel.visitData == nil || viewModel.visitData != nil)
                        //.scrollIndicators(.never)
                        .navigationBarTitle("House: \(viewModel.house.number)", displayMode: .automatic)
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarLeading) {
                                if #available(iOS 26.0, *) {
                                    Button(action: {
                                        viewModel.backAnimation.toggle(); HapticManager.shared.trigger(.lightImpact)
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
                                        Button("", action: { viewModel.backAnimation.toggle(); HapticManager.shared.trigger(.lightImpact) ;
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
                                        synced: viewModel.dataStore.synchronized,
                                        lastTime: viewModel.dataStore.lastTime
                                    ) {
                                        HapticManager.shared.trigger(.lightImpact)
                                        synchronizationManager.startupProcess(synchronizing: true)
                                    }
                                }
                                
                                // SPACE between pill and recall button
                                ToolbarSpacer(.flexible, placement: .primaryAction)
                                
                                // RIGHT PART of trailing: Recall Button
                                ToolbarItemGroup(placement: .primaryAction) {
                                    Button(action: {
                                        viewModel.revisitAnimation.toggle()
                                        if viewModel.recallAdded {
                                            Task {
                                                await CenterPopup_DeleteRecall(viewModel: viewModel, house: house.id) {
                                                    let toast = ToastValue(
                                                        icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                                        message: NSLocalizedString("Recall Deleted", comment: "")
                                                    )
                                                    presentToast(toast)
                                                }.present()
                                            }
                                        } else {
                                            Task {
                                                await CenterPopup_AddRecall(viewModel: viewModel, house: house.id) {
                                                    let toast = ToastValue(
                                                        icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green),
                                                        message: "Recall Added"
                                                    )
                                                    presentToast(toast)
                                                }.present()
                                            }
                                        }
                                    }) {
                                        Image(systemName: viewModel.recallAdded ? "person.fill.checkmark" : "person.badge.plus.fill")
                                    }
                                }
                            } else {
                                // iOS 25 and below: Single ToolbarItemGroup with HStack
                                ToolbarItemGroup(placement: .topBarTrailing) {
                                    HStack {
                                        Button("", action: { viewModel.syncAnimation = true;
                                            synchronizationManager.startupProcess(synchronizing: true) })
                                        .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $viewModel.dataStore.synchronized, lastTime: $viewModel.dataStore.lastTime))
                                        
                                        Button("", action: {
                                            viewModel.revisitAnimation.toggle()
                                            if viewModel.recallAdded {
                                                Task {
                                                    await CenterPopup_DeleteRecall(viewModel: viewModel, house: house.id) {
                                                        let toast = ToastValue(
                                                            icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                                            message: NSLocalizedString("Recall Deleted", comment: "")
                                                        )
                                                        presentToast(toast)
                                                    }.present()
                                                }
                                            } else {
                                                Task {
                                                    await CenterPopup_AddRecall(viewModel: viewModel, house: house.id) {
                                                        let toast = ToastValue(
                                                            icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green),
                                                            message: "Recall Added"
                                                        )
                                                        presentToast(toast)
                                                    }.present()
                                                }
                                            }
                                        })
                                        .buttonStyle(CircleButtonStyle(imageName: viewModel.recallAdded ? "person.fill.checkmark"  : "person.badge.plus.fill", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.revisitAnimationprogress, animation: $viewModel.revisitAnimation))
                                    }
                                }
                            }
                        }
                        .navigationTransition( viewModel.visitIdToScrollTo != nil ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
                        .navigationViewStyle(StackNavigationViewStyle())
                    }.coordinateSpace(name: "scroll")
                        .scrollIndicators(.never)
                        .refreshable {
                            viewModel.synchronizationManager.startupProcess(synchronizing: true)
                        }
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
                        .onAppear {
                            if visitSummary.isEmpty, let data = viewModel.visitData {
                                let notes = data.map { $0.visit.notes }
                                let dates = data.map { Date(timeIntervalSince1970: TimeInterval($0.visit.date) / 1000) }
                                let engine = VisitSummarizationEngineManager(notes: notes, visitDates: dates)
                                visitSummary = engine.generateActionOrientedNarrative()
                            }
                        }
                        .onChange(of: viewModel.visitData) { newData in
                            if let data = newData {
                                let notes = data.map { $0.visit.notes }
                                let dates = data.map { Date(timeIntervalSince1970: TimeInterval($0.visit.date) / 1000) }
                                let engine = VisitSummarizationEngineManager(notes: notes, visitDates: dates)
                                visitSummary = engine.generateActionOrientedNarrative()
                            }
                        }
                }
                MainButton(imageName: "plus", colorHex: "#1e6794", width: 60) {
                    self.viewModel.presentSheet = true
                    Task {
                        await CenterPopup_AddVisit(viewModel: viewModel, house: house
                        ) {
                            let toast = ToastValue(
                                icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green),
                                message: "Visit Added"
                            )
                            presentToast(toast)
                        }.present()
                    }
                }
                .offset(y: hideFloatingButton ? 200 : 0)
                .animation(.spring(), value: hideFloatingButton)
                .vSpacing(.bottom).hSpacing(.trailing)
                .padding()
            }
        }
    }
    
    //MARK: - Visit Cell View
    
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
                                    Task {
                                        await CenterPopup_AddVisit(viewModel: viewModel, house: house
                                        ) {
                                            let toast = ToastValue(
                                                icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green),
                                                message: "Visit Added"
                                            )
                                            presentToast(toast)
                                        }.present()
                                    }
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
                    //DispatchQueue.main.async {
                    self.viewModel.visitToDelete = visitData.visit.id
                    //self.viewModel.showAlert = true
                    Task {
                        await CenterPopup_DeleteVisit(viewModel: viewModel) {
                            Task {
                                await dismissLastPopup()
                            }
                            let toast = ToastValue(
                                icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                message: NSLocalizedString("Visit Deleted", comment: "")
                            )
                            presentToast(toast)
                        }.present()
                    }
                    //}
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
                    Task {
                        await CenterPopup_AddVisit(viewModel: viewModel, house: house
                        ) {
                            let toast = ToastValue(
                                icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green),
                                message: "Visit Added"
                            )
                            presentToast(toast)
                        }.present()
                    }
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
    
    @ViewBuilder
    func visitSummaryCard(_ summary: String, isLoading: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("Resumen inteligente")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                Spacer()
            }
            
            Text(summary)
                .font(.callout)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
            
            Divider()
                .padding(.top, 4)
            
            HStack(spacing: 12) {
                Label("Análisis de visitas", systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)
                Text("IA personalizada")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
        .modifier(ShimmerIfNeeded(active: isLoading))
    }
    
}

//MARK: - Delete Visit Popup

struct CenterPopup_DeleteVisit: CenterPopup {
    @ObservedObject var viewModel: VisitsViewModel
    var onDone: () -> Void

    init(viewModel: VisitsViewModel, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        viewModel.loading = false
        self.onDone = onDone
    }

    var body: some View {
        createContent()
    }

    func createContent() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.minus")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundColor(.red)

            Text("Delete Visit")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text("Are you sure you want to delete the selected visit?")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if viewModel.ifFailed {
                Text("Error deleting visit, please try again later")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }

            HStack(spacing: 12) {
                if !viewModel.loading {
                    CustomBackButton(showImage: true, text: NSLocalizedString("Cancel", comment: "")) {
                        viewModel.visitToDelete = nil
                        Task { await dismissLastPopup() }
                    }
                }

                CustomButton(loading: viewModel.loading, title: "Delete", color: .red) {
                    HapticManager.shared.trigger(.lightImpact)
                    Task {
                        withAnimation { viewModel.loading = true }
                        if let visitId = viewModel.visitToDelete {
                            let result = await viewModel.deleteVisit(visit: visitId)
                            switch result {
                            case .success:
                                HapticManager.shared.trigger(.success)
                                viewModel.ifFailed = false
                                viewModel.visitToDelete = nil
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

//MARK: - Add Visit Popup

struct CenterPopup_AddVisit: CenterPopup {
    @ObservedObject var viewModel: VisitsViewModel
    var onDone: () -> Void
    var house: House

    init(viewModel: VisitsViewModel, house: House, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDone = onDone
        self.house = house
    }

    var body: some View {
        AddVisitView(visit: viewModel.currentVisit, house: house) {
            viewModel.presentSheet = false
            onDone()
            Task { await dismissLastPopup() }
        } onDismiss: {
            viewModel.presentSheet = false
            Task { await dismissLastPopup() }
        }
        .padding()
        .background(Material.thin)
        .cornerRadius(20)
        .ignoresSafeArea(.keyboard)
        .simultaneousGesture(
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

    func configurePopup(config: CenterPopupConfig) -> CenterPopupConfig {
        config.popupHorizontalPadding(24)
    }
}

//MARK: - Add Recall Popup

struct CenterPopup_AddRecall: CenterPopup {
    @ObservedObject var viewModel: VisitsViewModel
    let house: String
    let user = StorageManager.shared.userEmail
    var onDone: () -> Void

    init(viewModel: VisitsViewModel, house: String, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        viewModel.loading = false
        self.house = house
        self.onDone = onDone
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.badge.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundColor(.blue)

            Text("Add Recall")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("By adding this house as a recall, it will be displayed in the recalls tab and you will be able to access it more easily.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if viewModel.ifFailed {
                Text("Error adding recall, please try again later")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }

            HStack(spacing: 12) {
                if !viewModel.loading {
                    CustomBackButton(showImage: true, text: NSLocalizedString("Cancel", comment: "")) {
                        Task { await dismissLastPopup() }
                    }
                }

                CustomButton(loading: viewModel.loading, title: "Add") {
                    HapticManager.shared.trigger(.lightImpact)
                    withAnimation { viewModel.loading = true }

                    Task {
                        switch await viewModel.addRecall(user: user ?? "", house: house) {
                        case .success:
                            HapticManager.shared.trigger(.success)
                            viewModel.refreshRecallState()
                            await dismissLastPopup()
                            onDone()
                        case .failure:
                            HapticManager.shared.trigger(.error)
                            viewModel.ifFailed = true
                        }
                    }
                }
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

//MARK: - Delete Recall Popup

struct CenterPopup_DeleteRecall: CenterPopup {
    @ObservedObject var viewModel: VisitsViewModel
    let house: String
    let user = StorageManager.shared.userEmail
    var onDone: () -> Void

    init(viewModel: VisitsViewModel, house: String, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        viewModel.loading = false
        self.house = house
        self.onDone = onDone
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundColor(.red)

            Text("Remove Recall")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("By removing this house as a recall, it will be removed from the recalls tab.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if viewModel.ifFailed {
                Text("Error removing recall, please try again later")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }

            HStack(spacing: 12) {
                if !viewModel.loading {
                    CustomBackButton(showImage: true, text: NSLocalizedString("Cancel", comment: "")) {
                        Task { await dismissLastPopup() }
                    }
                }

                CustomButton(loading: viewModel.loading, title: "Remove", color: .red) {
                    HapticManager.shared.trigger(.lightImpact)
                    withAnimation { viewModel.loading = true }

                    Task {
                        let id = await viewModel.getRecallId(house: house) ?? Date().millisecondsSince1970
                        switch await viewModel.deleteRecall(id: id, user: user ?? "", house: house) {
                        case .success:
                            HapticManager.shared.trigger(.success)
                            viewModel.refreshRecallState()
                            await dismissLastPopup()
                            onDone()
                        case .failure:
                            HapticManager.shared.trigger(.error)
                            viewModel.ifFailed = true
                        }
                    }
                }
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


struct ShimmerIfNeeded: ViewModifier {
    let active: Bool
    
    func body(content: Content) -> some View {
        if active {
            content
                .redacted(reason: .placeholder)
                .shimmering()
        } else {
            content
        }
    }
}
