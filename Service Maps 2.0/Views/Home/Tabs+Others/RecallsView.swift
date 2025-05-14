//
//  RecallsView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/8/24.
//

import SwiftUI
import Combine
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
import UserNotifications

// MARK: - RecallsView

struct RecallsView: View {
    
    // MARK: - Environment
    
    @Environment(\.mainWindowSize) var mainWindowSize
    @Environment(\.presentToast) var presentToast
    
    // MARK: - Dependencies
    
    @StateObject private var viewModel = RecallViewModel()
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var preferencesViewModel = ColumnViewModel()
    
    
    @State var showNotificationCenter = false

    // MARK: - Body
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ScrollViewReader { scrollViewProxy in
                    ScrollView {
                        LazyVStack {
                            if viewModel.recalls == nil && viewModel.dataStore.synchronized == false {
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
                                if let data = viewModel.recalls {
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
                                        SwipeViewGroup {
                                            if UIDevice().userInterfaceIdiom == .pad && proxy.size.width > 400 && preferencesViewModel.isColumnViewEnabled {
                                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                                    ForEach(viewModel.recalls!, id: \.recall.id) { recall in
                                                        RecallRow(viewModel: viewModel, recall: recall, mainWindowSize: mainWindowSize).installToast(position: .bottom)
                                                            .id(recall.recall.id)
                                                    }
                                                }
                                            } else {
                                                LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                                                    ForEach(viewModel.recalls!, id: \.recall.id) { recall in
                                                        RecallRow(viewModel: viewModel, recall: recall, mainWindowSize: mainWindowSize).installToast(position: .bottom)
                                                            .id(recall.recall.id)
                                                    }
                                                }
                                            }
                                        }.animation(.spring(), value: viewModel.recalls!)
                                            .padding()
                                    }
                                }
                            }
                        }
                        .animation(.easeInOut(duration: 0.25), value: viewModel.recalls == nil || viewModel.recalls != nil)
                            .navigationBarTitle("Recalls", displayMode: .automatic)
                            .toolbar {
                                ToolbarItemGroup(placement: .topBarTrailing) {
                                    Button("", action: { viewModel.syncAnimation = true; synchronizationManager.startupProcess(synchronizing: true) })//.ke yboardShortcut("s", modifiers: .command)
                                        .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $viewModel.dataStore.synchronized, lastTime: $viewModel.dataStore.lastTime))
                                    
                                    Button("", action: {
                                        HapticManager.shared.trigger(.lightImpact)
                                        Task {
                                            await CenterPopup_NotificationList(isPresented: $showNotificationCenter).present()
                                        }
                                    })
                                    .buttonStyle(CircleButtonStyle(imageName: "bell.badge", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.optionsAnimation))
                                }
                            }
                            .navigationTransition(.slide.combined(with: .fade(.in)))
                            .navigationViewStyle(StackNavigationViewStyle())
                        
                    }.refreshable {
                        viewModel.synchronizationManager.startupProcess(synchronizing: true)
                    }
                    
                    
                }
            }
        }
    }
}

// MARK: - RecallViewModel

@MainActor
class RecallViewModel: ObservableObject {
    
    // MARK: - Dependencies
    
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    // MARK: - Properties
    
    @Published var recalls: Optional<[RecallData]> = nil
    @Published var syncAnimation = false
    @Published var syncAnimationprogress: CGFloat = 0.0
    @Published var recallToRemove: String?
    @Published var showAlert = false
    
    @Published var ifFailed = false
    
    @Published var loading = false
    @Published var progress: CGFloat = 0.0
    @Published var optionsAnimation = false
    
    
    @Published var showToast = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializers
    
    init() {
        getRecalls()
    }
    
    // MARK: - Methods
    
    func deleteRecall(id: Int64, user: String, house: String) async -> Result<Void, Error> {
        return await DataUploaderManager().deleteRecall(recall: Recalls(id: id, user: user, house: house))
    }
    
    func scheduleRecallReminder(for recall: RecallData) {
        // Cancel existing notification first
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [recall.recall.getId()])

        // Check last visit
        guard let lastVisitDate = recall.visit?.date else { return }

        let inactivityLimit: TimeInterval = 3 * 24 * 60 * 60 // 3 days
        let fireDate = Date(timeIntervalSince1970: TimeInterval(lastVisitDate / 1000) + inactivityLimit)
        
        if fireDate <= Date() { return } // Already expired

        let content = UNMutableNotificationContent()
        content.title = "Don't forget your recall"
        content.body = "You haven't added a visit for \(recall.house.number) recently."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fireDate.timeIntervalSinceNow, repeats: false)
        let request = UNNotificationRequest(identifier: recall.recall.getId(), content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Publisher
    
    @MainActor
    func getRecalls() {
        GRDBManager.shared.getRecalls()
            .subscribe(on: DispatchQueue.main)
            .receive(on: DispatchQueue.main) // Update on main thread
            .sink { completion in
                if case .failure(let error) = completion {
                    // Handle errors here
                    print(error)
                }
            } receiveValue: { recalls in
                DispatchQueue.main.async {
                    self.recalls = recalls
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - RecallData

struct RecallData: Hashable, Equatable {
    var recall: Recalls
    var territory: Territory
    var territoryAddress: TerritoryAddress
    var house: House
    var visit: Visit?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(recall)
        hasher.combine(territory)
        hasher.combine(territoryAddress)
        hasher.combine(house)
        hasher.combine(visit)
    }
    
    static func == (lhs: RecallData, rhs: RecallData) -> Bool {
        return lhs.recall == rhs.recall && lhs.territory == rhs.territory && lhs.territoryAddress == rhs.territoryAddress && lhs.house == rhs.house && lhs.visit == rhs.visit
    }
    
    static func != (lhs: RecallData, rhs: RecallData) -> Bool {
        return lhs.recall != rhs.recall || lhs.territory != rhs.territory || lhs.territoryAddress != rhs.territoryAddress || lhs.house != rhs.house || lhs.visit != rhs.visit
    }
}

struct RecallsWithKey: Hashable, Equatable {
    var keys: [Token]
    var recalls: [RecallData]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(keys)
        hasher.combine(recalls)
    }
    
    static func == (lhs: RecallsWithKey, rhs: RecallsWithKey) -> Bool {
        return lhs.keys == rhs.keys && lhs.recalls == rhs.recalls
    }
    
    static func != (lhs: RecallsWithKey, rhs: RecallsWithKey) -> Bool {
        return lhs.keys != rhs.keys || lhs.recalls != rhs.recalls
    }
    
}

// MARK: - RecallRow

struct RecallRow: View {
    @ObservedObject var viewModel: RecallViewModel
    var recall: RecallData
    var mainWindowSize: CGSize
    var revisitView: Bool = true
    @Environment(\.presentToast) var presentToast
    var body: some View {
        
        VStack {
            Text(buildPath(territory: recall.territory, address: recall.territoryAddress, house: recall.house)).hSpacing(.leading).font(.headline).fontWeight(.heavy).modifier(ScrollTransitionModifier()).transition(.customBackInsertion)
            SwipeView {
                NavigationLink(destination: NavigationLazyView(VisitsView(house: recall.house))) {
                    HouseCell(revisitView: revisitView, house: HouseData(id: UUID(), house: recall.house, accessLevel: AuthorizationLevelManager().getAccessLevel(model:  recall.house) ?? .User), mainWindowSize: mainWindowSize).modifier(ScrollTransitionModifier()).transition(.customBackInsertion)
                }.onTapHaptic(.lightImpact)
            } leadingActions: { context in
                SwipeAction(
                    systemImage: "bell.badge",
                    backgroundColor: .blue
                ) {
                    HapticManager.shared.trigger(.lightImpact)
                    context.state.wrappedValue = .closed
                    Task {
                        await ScheduleRecallPopup(recall: recall).present()
                    }
                }
                .allowSwipeToTrigger()
                .font(.title.weight(.semibold))
                .foregroundColor(.white)
                
            } trailingActions: { context in
                SwipeAction(
                    systemImage: "person.fill.xmark",
                    backgroundColor: .red
                ) {
                    HapticManager.shared.trigger(.lightImpact)
                    context.state.wrappedValue = .closed
                    Task {
                        // self.viewModel.visitToDelete = visitData.visit.id
                        //self.viewModel.showAlert = true
                        //CenterPopup_DeleteVisit(viewModel: viewModel).present()
                        self.viewModel.recallToRemove = recall.recall.house
                        await CenterPopup_RemoveRecall(viewModel: viewModel, recall: recall){
                            let toast = ToastValue(
                                icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                message: NSLocalizedString("Recall Removed", comment: "")
                            )
                            presentToast(toast)
                        }.present()
                    }
                }
                .font(.title.weight(.semibold))
                .foregroundColor(.white)
            }
            .swipeActionCornerRadius(16)
            .swipeSpacing(5)
            .swipeOffsetCloseAnimation(stiffness: 500, damping: 100)
            .swipeOffsetExpandAnimation(stiffness: 500, damping: 100)
            .swipeOffsetTriggerAnimation(stiffness: 500, damping: 100)
            .swipeMinimumDistance(25)
        }
        
    }
    
    public func buildPath(territory: Territory?, address: TerritoryAddress?, house: House?) -> String {
        let territoryString = "Territory \(territory?.number ?? 0)"
        let addressString: String? = {
            guard let address = address else { return nil }
            return "Address: \(address.address)"
        }()
        
        let houseString: String? = {
            guard let house = house else { return nil }
            return "House: \(house.number)"
        }()
        
        var finalString = territoryString
        
        if let addressString = addressString {
            finalString += " → \(addressString)"
        }
        
        if let houseString = houseString {
            finalString += " → \(houseString)"
        }
        
        return finalString
    }
}

// MARK: - Remove Recall Popup

struct CenterPopup_RemoveRecall: CenterPopup {
    @ObservedObject var viewModel: RecallViewModel
    @State var recall: RecallData
    var onDone: () -> Void

    init(viewModel: RecallViewModel, recall: RecallData, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.recall = recall
        self.onDone = onDone
    }

    var body: some View {
        createContent()
    }

    func createContent() -> some View {
        VStack(spacing: 16) {
            // MARK: - Icon
            Image(systemName: "trash.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundColor(.red)

            // MARK: - Title
            Text("Remove Recall")
                .font(.title2)
                .fontWeight(.heavy)
                .foregroundColor(.primary)

            // MARK: - Subtitle
            Text("Are you sure you want to remove the selected recall?")
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            // MARK: - Error Message
            if viewModel.ifFailed {
                Text("Error removing recall. Please try again later.")
                    .font(.footnote)
                    .foregroundColor(.red)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }

            // MARK: - Buttons
            HStack(spacing: 12) {
                if !viewModel.loading {
                    CustomBackButton(showImage: true, text: NSLocalizedString("Cancel", comment: "")) {
                        withAnimation {
                            HapticManager.shared.trigger(.lightImpact)
                            Task {
                                await dismissLastPopup()
                            }
                            self.viewModel.recallToRemove = nil
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                CustomButton(
                    loading: viewModel.loading,
                    title: NSLocalizedString("Remove", comment: ""),
                    color: .red
                ) {
                    withAnimation {
                        self.viewModel.loading = true
                        HapticManager.shared.trigger(.lightImpact)
                    }

                    Task {
                        if let _ = self.viewModel.recallToRemove {
                            let result = await self.viewModel.deleteRecall(
                                id: self.recall.recall.id,
                                user: self.recall.recall.user,
                                house: self.recall.recall.house
                            )

                            DispatchQueue.main.async {
                                switch result {
                                case .success(_):
                                    self.viewModel.loading = false
                                    self.viewModel.ifFailed = false
                                    self.viewModel.recallToRemove = nil
                                    onDone()
                                    HapticManager.shared.trigger(.success)
                                    Task { await dismissLastPopup() }
                                case .failure(_):
                                    self.viewModel.loading = false
                                    self.viewModel.ifFailed = true
                                    HapticManager.shared.trigger(.error)
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
        .ignoresSafeArea(.keyboard)
    }

    func configurePopup(config: CenterPopupConfig) -> CenterPopupConfig {
        config.popupHorizontalPadding(24)
    }
}

struct ScheduleRecallPopup: CenterPopup {
    var recall: RecallData? = nil
    var id: String? = nil
    var existingDate: Date? = nil
    var onDone: (() -> Void)? = nil // 👈 New closure

    @State private var selectedDate: Date
    init(recall: RecallData? = nil, id: String? = nil, existingDate: Date? = nil, onDone: (() -> Void)? = nil) {
        self.recall = recall
        self.id = id
        self.existingDate = existingDate
        _selectedDate = State(initialValue: existingDate ?? Date().addingTimeInterval(60))
        self.onDone = onDone
    }
    @State private var isLoading = false
    @State private var showError = false

    var body: some View {
        createContent()
    }
    
    func createContent() -> some View {
        VStack(spacing: 16) {
            Text("Schedule Reminder")
                .font(.title3.bold())
                .hSpacing(.leading)

            DatePicker("Date", selection: $selectedDate, in: Date()..., displayedComponents: [.date])
                .datePickerStyle(.graphical)
            DatePicker("Time", selection: $selectedDate, displayedComponents: [.hourAndMinute])
                .datePickerStyle(.compact).padding(.horizontal)
            
            
            Text(
                "You will be reminded to revisit \(recall?.house.number ?? "-") at \(selectedDate.formatted(date: .long, time: .shortened))"
            )
                .font(.headline)
                .foregroundColor(.secondary)
            
            if showError {
                Text("Please choose a future time.")
                    .foregroundColor(.red)
                    .fontWeight(.bold)
            }

            HStack {
                if !isLoading {
                    CustomBackButton {
                        Task {
                            await dismissLastPopup()
                        }
                    }
                }

                CustomButton(loading: isLoading, title: "Schedule", color: .blue) {
                    if selectedDate < Date() {
                        showError = true
                        HapticManager.shared.trigger(.error)
                        return
                    }
                    withAnimation {
                        isLoading = true
                    }
                    
                    Task {
                        try? await Task
                            .sleep(nanoseconds: 400_000_000) // Simulate delay
                        let notificationId = id ?? "user-\(recall?.recall.getId() ?? "")"
                        NotificationManager.shared.cancelNotification(id: notificationId)
                        await NotificationManager.shared.scheduleNotification(
                            id: notificationId,
                            title: recall?.house.number != nil ? NSLocalizedString("Recall Reminder", comment: "") : NSLocalizedString("Reminder", comment: ""),
                            body: recall?.house.number != nil ? String(localized:"Time to revisit \(recall!.house.number)! Territory \(String(recall?.territory.number ?? 0000)), address: \(recall?.territoryAddress.address ?? ""). 🏠 ") : String(localized:"Time to revisit \(recall!.house.number)! Territory \(String(recall?.territory.number ?? 0000)), address: \(recall?.territoryAddress.address ?? ""). 🏠 "),
                            date: selectedDate,
                            deepLink: "servicemaps://openRecalls"
                        )

                        // UI work back on main thread
                        await MainActor.run {
                            isLoading = false
                            HapticManager.shared.trigger(.success)
                            onDone?() // 👈 Call completion if provided
                        }
                        Task {
                            await dismissLastPopup()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Material.ultraThick)
        .cornerRadius(20)
    }

    func configurePopup(config: CenterPopupConfig) -> CenterPopupConfig {
        config.popupHorizontalPadding(24)
            .tapOutsideToDismissPopup(true)
    }
}

struct CenterPopup_NotificationList: CenterPopup {
    @Binding var isPresented: Bool
    @State private var notifications: [NotificationData] = []

    var body: some View {
        createContent()
    }

    func createContent() -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Reminders")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                
                Spacer()

                Button(action: {
                    HapticManager.shared.trigger(.lightImpact)
                    Task {
                        await dismissLastPopup()
                    }
                    isPresented = false
                }) {
                    Label("Close", systemImage: "xmark")
                        .font(.subheadline.bold())
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)

            Divider().padding()

            ScrollView {
                VStack(spacing: 12) {
                    if notifications.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: "bell.slash")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("You have no scheduled reminders.")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .vSpacing(.center)
                    } else {
                        ForEach(notifications) { notification in
                            NotificationCell(
                                notification: notification,
                                onDelete: {
                                    UNUserNotificationCenter.current()
                                        .removePendingNotificationRequests(withIdentifiers: [notification.id])
                                    fetchNotifications()
                                },
                                onEdit: {
                                    fetchNotifications() // 👈 Called after editing
                                }
                            ).transition(.customBackInsertion)
                        }
                    }
                }
                .animation(.spring(), value: notifications)
                .padding()
            }
            .frame(maxHeight: 500)
            .task {
                fetchNotifications()
            }
        }
        .padding()
        .background(Material.ultraThick, in: RoundedRectangle(cornerRadius: 25, style: .continuous))
    }

    func configurePopup(config: CenterPopupConfig) -> CenterPopupConfig {
        config.popupHorizontalPadding(24)
            .tapOutsideToDismissPopup(true)
    }

    private func fetchNotifications() {
        Task.detached {
            let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
            let mapped: [NotificationData] = requests.map { req in
                NotificationData(
                    id: req.identifier,
                    title: req.content.title,
                    body: req.content.body,
                    triggerDate: req.triggerDate
                )
            }

            await MainActor.run {
                self.notifications = mapped.sorted { $0.triggerDate < $1.triggerDate }
            }
        }
    }
}

struct NotificationCell: View {
    let notification: NotificationData
    var onDelete: () -> Void
    var onEdit: () -> Void // 👈 Add this

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bell.fill")
                .font(.title2)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(notification.body)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Scheduled: \(notification.triggerDate.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(spacing: 8) {
                Button(action: {
                    HapticManager.shared.trigger(.lightImpact)
                    onDelete()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(6)
                        .background(.thinMaterial, in: Circle())
                }

                Button(action: {
                    HapticManager.shared.trigger(.lightImpact)
                    Task {
                        await ScheduleRecallPopup(
                            id: notification.id,
                            existingDate: notification.triggerDate,
                            onDone: {
                                onEdit() // 👈 Call the edit completion
                            }
                        ).present()
                    }
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                        .padding(6)
                        .background(.thinMaterial, in: Circle())
                }
            }
            .frame(width: 40)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

extension UNNotificationRequest {
    var triggerDate: Date {
        if let trigger = trigger as? UNCalendarNotificationTrigger {
            return Calendar.current.date(from: trigger.dateComponents) ?? Date.distantFuture
        } else if let trigger = trigger as? UNTimeIntervalNotificationTrigger {
            return trigger.nextTriggerDate() ?? Date.distantFuture
        } else {
            return Date.distantFuture
        }
    }
}

struct NotificationData: Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    let body: String
    let triggerDate: Date
}

// MARK: - Preview

#Preview {
    RecallsView()
}
