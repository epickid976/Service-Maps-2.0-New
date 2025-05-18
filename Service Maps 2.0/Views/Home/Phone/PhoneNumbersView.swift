//
//  PhoneNumbersView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 5/1/24.
//

import Foundation
import SwiftUI
import SwipeActions
import Combine
import NukeUI
import ScalingHeaderScrollView
import Nuke
import Lottie
import AlertKit
import MijickPopups
import Toasts

//MARK: - PhoneNumbersView

struct PhoneNumbersView: View {
    
    var territory: PhoneTerritory
    
    //MARK: - Initializers
    
    init(territory: PhoneTerritory, phoneNumberToScrollTo: String? = nil) {
        self.territory = territory
        
        let initialViewModel = NumbersViewModel(territory: territory, phoneNumberToScrollTo: phoneNumberToScrollTo)
        _viewModel = StateObject(wrappedValue: initialViewModel)
    }
    
    //MARK: - Environment
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.presentToast) var presentToast
    @Environment(\.mainWindowSize) var mainWindowSize
    
    //MARK: - Dependencies
    
    @StateObject var viewModel: NumbersViewModel
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var preferencesViewModel = ColumnViewModel()
    
    //MARK: - Properties
    
    @State var highlightedNumberId: String?
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    @State var isLoading = false
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    
    let minimumOffset: CGFloat = 60
    
    //MARK: - Body
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ScrollViewReader { scrollViewProxy in
                    ScalingHeaderScrollView {
                        ZStack {
                            Color(UIColor.secondarySystemBackground).ignoresSafeArea(.all)
                            if viewModel.noImage {
                                viewModel.smallHeader.vSpacing(.bottom).padding()
                            } else {
                                viewModel.largeHeader(progress: viewModel.progress, mainWindowSize: proxy.size)
                            }
                        }
                    } content: {
                        LazyVStack {
                            if viewModel.phoneNumbersData == nil && viewModel.dataStore.synchronized == false {
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
                                if let data = viewModel.phoneNumbersData {
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
                                        LazyVStack {
                                            SwipeViewGroup {
                                                if UIDevice().userInterfaceIdiom == .pad && proxy.size.width > 400 && preferencesViewModel.isColumnViewEnabled {
                                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                                        ForEach(viewModel.phoneNumbersData!, id: \.phoneNumber.id) { numbersData in
                                                            let proxy = CGSize(width: proxy.size.width / 2 - 16, height: proxy.size.height)
                                                            numbersCell(numbersData: numbersData, mainWindowSize: proxy).id(numbersData.phoneNumber.id).transition(.customBackInsertion)
                                                                .padding(.bottom, 2)
                                                        }.modifier(ScrollTransitionModifier())
                                                    }
                                                } else {
                                                    LazyVGrid(columns: [GridItem(.flexible())]) {
                                                        ForEach(viewModel.phoneNumbersData!, id: \.phoneNumber.id) { numbersData in
                                                            numbersCell(numbersData: numbersData, mainWindowSize: proxy.size).id(numbersData.phoneNumber.id).transition(.customBackInsertion)
                                                                .padding(.bottom, 2)
                                                        }.modifier(ScrollTransitionModifier())
                                                    }
                                                }
                                            }
                                        }
                                        
                                        .padding(.horizontal)
                                        .padding(.top)
                                        .padding(.bottom)
                                        .animation(.spring(), value: viewModel.phoneNumbersData)
                                        
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
                        .onChange(of: viewModel.presentSheet) { value in
                            if value {
                                Task {
                                    await CenterPopup_AddNumber(viewModel: viewModel, territory: territory){
                                        let toast = ToastValue(
                                            icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green),
                                            message: "Number Added"
                                        )
                                        presentToast(toast)
                                    }.present()
                                }
                            }
                        }
                        .animation(.easeInOut(duration: 0.25), value: viewModel.phoneNumbersData == nil || viewModel.phoneNumbersData != nil)
                        .onChange(of: viewModel.phoneNumberToScrollTo) { id in
                            if let id = id {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        scrollViewProxy.scrollTo(id, anchor: .center)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            HapticManager.shared.trigger(.selectionChanged)
                                            highlightedNumberId = id // Highlight after scrolling
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            highlightedNumberId = nil
                                        }
                                    }
                                }
                                
                            }
                        }
                    }
                    .height(min: 180, max: viewModel.noImage ? 200 : 350.0)
                    .allowsHeaderGrowth()
                    .collapseProgress($viewModel.progress)
                    //                    .pullToRefresh(isLoading: $viewModel.dataStore.synchronized.not) {
                    //                        Task {
                    //                           synchronizationManager.startupProcess(synchronizing: true)
                    //                        }
                    //                    }
                    .scrollIndicators(.never)
                    .coordinateSpace(name: "scroll")
                }
                if AuthorizationLevelManager().existsAdminCredentials() {
                    MainButton(imageName: "plus", colorHex: "#1e6794", width: 60) {
                        self.viewModel.presentSheet = true
                    }
                    .offset(y: hideFloatingButton ? 100 : -25)
                    .animation(.spring(), value: hideFloatingButton)
                    .vSpacing(.bottom).hSpacing(.trailing)
                    .padding()
                    // //.keyboardShortcut("+", modifiers: .command)
                }
            }
            .ignoresSafeArea()
            .navigationBarBackButtonHidden()
            .navigationBarTitle("Numbers", displayMode: .inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    HStack {
                        Button("", action: {withAnimation { viewModel.backAnimation.toggle(); HapticManager.shared.trigger(.lightImpact) };
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                Task {
                                    await dismissAllPopups()
                                }
                                presentationMode.wrappedValue.dismiss()
                            }
                        })//.keyboardShortcut(.delete, modifiers: .command)
                        .buttonStyle(CircleButtonStyle(imageName: "arrow.backward", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.backAnimation))
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    HStack {
                        Button("", action: { viewModel.syncAnimation = true; synchronizationManager.startupProcess(synchronizing: true) })//.keyboardShortcut("s", modifiers: .command)
                            .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $viewModel.dataStore.synchronized, lastTime: $viewModel.dataStore.lastTime))
                    }
                }
            }
            .navigationTransition(viewModel.presentSheet || viewModel.phoneNumberToScrollTo != nil ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
        }
    }
    
    //MARK: - Numbers Cell
    
    @ViewBuilder
    func numbersCell(numbersData: PhoneNumbersData, mainWindowSize: CGSize) -> some View {
        SwipeView {
            NavigationLink(destination: NavigationLazyView(CallsView(phoneNumber: numbersData.phoneNumber))) {
                PhoneNumberCell(numbersData: numbersData, mainWindowSize: mainWindowSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16) // Same shape as the cell
                            .fill(highlightedNumberId == numbersData.phoneNumber.id ? Color.gray.opacity(0.5) : Color.clear).animation(.default, value: highlightedNumberId == numbersData.phoneNumber.id) // Fill with transparent gray if highlighted
                    )
                    .optionalViewModifier { content in
                        if AuthorizationLevelManager().existsAdminCredentials() {
                            content
                                .contextMenu {
                                    Button {
                                        DispatchQueue.main.async {
                                            self.viewModel.numberToDelete = (numbersData.phoneNumber.id, String(numbersData.phoneNumber.number))
                                            
                                            Task {
                                                await CenterPopup_DeletePhoneNumber(viewModel: viewModel){
                                                    let toast = ToastValue(
                                                        icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                                        message: NSLocalizedString("Number Deleted", comment: "")
                                                    )
                                                    presentToast(toast)
                                                }.present()
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "trash")
                                            Text("Delete Number")
                                        }
                                    }
                                    
                                    Button {
                                        self.viewModel.currentNumber = numbersData.phoneNumber
                                        self.viewModel.presentSheet = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "pencil")
                                            Text("Edit Number")
                                        }
                                    }
                                    //TODO Trash and Pencil only if admin
                                }.clipShape(RoundedRectangle(cornerRadius: 16, style: .circular))
                        } else if AuthorizationLevelManager().existsPhoneCredentials() {
                            content
                                .contextMenu {
                                    Button {
                                        self.viewModel.currentNumber = numbersData.phoneNumber
                                        self.viewModel.presentSheet = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "pencil")
                                            Text("Edit Number")
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
                        await CenterPopup_AddCall(
                            viewModel: CallsViewModel(phoneNumber: numbersData.phoneNumber), phoneNumber: numbersData.phoneNumber){
                                let toast = ToastValue(
                                    icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green),
                                    message: "Call Added"
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
            if self.viewModel.isAdmin {
                SwipeAction(
                    systemImage: "trash",
                    backgroundColor: .red
                ) {
                    HapticManager.shared.trigger(.lightImpact)
                    context.state.wrappedValue = .closed
                    DispatchQueue.main.async {
                        self.viewModel.numberToDelete = (numbersData.phoneNumber.id, String(numbersData.phoneNumber.number))
                        
                        Task {
                            await CenterPopup_DeletePhoneNumber(viewModel: viewModel){
                                let toast = ToastValue(
                                    icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                    message: NSLocalizedString("Number Deleted", comment: "")
                                )
                                presentToast(toast)
                            }.present()
                        }
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
                    self.viewModel.currentNumber = numbersData.phoneNumber
                    self.viewModel.presentSheet = true
                }
                .allowSwipeToTrigger()
                .font(.title.weight(.semibold))
                .foregroundColor(.white)
            }
        }
        .swipeActionCornerRadius(16)
        .swipeSpacing(5)
        .swipeOffsetCloseAnimation(stiffness: 1000, damping: 70)
        .swipeOffsetExpandAnimation(stiffness: 1000, damping: 70)
        .swipeOffsetTriggerAnimation(stiffness: 1000, damping: 70)
        .swipeMinimumDistance(self.viewModel.isAdmin ? 25:1000)
        
    }
}

//MARK: - PhoneNumber ViewModel

@MainActor
class NumbersViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    //MARK: - Dependencies
    
    @ObservedObject var databaseManager = GRDBManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var dataUploaderManager = DataUploaderManager()
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    //MARK: - Properties
    
    @Published var phoneNumbersData: Optional<[PhoneNumbersData]> = nil
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    
    @Published var currentNumber: PhoneNumber?
    @Published var numberToDelete: (String?,String?)
    
    @Published var presentSheet = false {
        didSet {
            if presentSheet == false {
                currentNumber = nil
            }
        }
    }
    
    @Published var progress: CGFloat = 0.0
    @Published var optionsAnimation = false
    
    @Published var syncAnimation = false
    @Published var syncAnimationprogress: CGFloat = 0.0
    
    @Published var backAnimation = false
    @Published var showAlert = false
    @Published var ifFailed = false
    @Published var loading = false
    @Published var noImage = false
    
    @Published var territory: PhoneTerritory
    
    @Published var phoneNumberToScrollTo: String? = nil
    
    @Published var showToast = false
    @Published var showAddedToast = false
    
    @Published var search: String = "" {
        didSet {
            getNumbers()
        }
    }
    
    //MARK: - Methods
    
    func deleteNumber(number: String) async -> Result<Void,Error> {
        return await dataUploaderManager.deletePhoneNumber(phoneNumberId: number)
    }
    
    
    //MARK: - Initializers
    init(territory: PhoneTerritory, phoneNumberToScrollTo: String? = nil) {
        self.territory = territory
        
        getNumbers(phoneNumberToScrollTo: phoneNumberToScrollTo)
    }
    
    
    //MARK: - Large Header
    @ViewBuilder
    func largeHeader(progress: CGFloat, mainWindowSize: CGSize) -> some View  {
        LazyVStack {
            ZStack {
                VStack {
                    LazyImage(url: URL(string: territory.getImageURL())) { state in
                        if let image = state.image {
                            image.resizable().aspectRatio(contentMode: .fill).frame(width: mainWindowSize.width, height: 350)
                            
                            //image.opacity(1 - progress)
                            
                        } else if state.isLoading  {
                            ProgressView().progressViewStyle(.circular)
                            
                        } else if state.error != nil {
                            ExecuteCode {
                                DispatchQueue.main.async {
                                    self.noImage = true
                                }
                            }
                            Image(uiImage: UIImage(named: "mapImage")!)
                                .resizable()
                                .frame(width: 100, height: 100)
                                .padding(.bottom, 125)
                        } else {
                            ExecuteCode {
                                DispatchQueue.main.async {
                                    self.noImage = true
                                }
                            }
                            Image(uiImage: UIImage(named: "mapImage")!)
                                .resizable()
                                .frame(width: 100, height: 100)
                                .padding(.bottom, 125)
                        }
                    }
                    .pipeline(ImagePipeline.shared)
                    .vSpacing(.bottom)
                    .cornerRadius(10)
                }
                .frame(width: mainWindowSize.width, height: 350, alignment: .center)
                VStack {
                    smallHeader
                    
                        .padding(.vertical)
                        .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
                    
                }.frame(height: 85)
                    .background(
                        Material.ultraThickMaterial
                    )
                    .vSpacing(.bottom)
            }
            .frame(width: mainWindowSize.width, height: 350)
        }
        
        .animation(.default, value: progress)
    }
    
    //MARK: - Small Header
    
    @ViewBuilder
    var smallHeader: some View {
        HStack(spacing: 16) {
            // Number and Title Section
            HStack(spacing: 8) {
                Text("№")
                    .font(.title2)
                    .bold()
                Text("\(territory.number)")
                    .font(.title)
                    .bold()
            }
            .foregroundColor(.primary)
            
            // Divider
            if !(progress < 0.98) { // Show image only if progress is sufficient
                Divider()
                    .frame(height: 40)
                    .padding(.horizontal, 4)
                
                // Image Section
                LazyImage(url: URL(string: territory.getImageURL())) { state in
                    if let image = state.image {
                        image.resizable().aspectRatio(contentMode: .fill).frame(maxWidth: 60, maxHeight: 60)
                    } else if state.error != nil {
                        Image(uiImage: UIImage(named: "mapImage")!)
                            .resizable()
                            .frame(width: 60, height: 60)
                        //.padding(.bottom, 125)
                    } else {
                        ProgressView().progressViewStyle(.circular)
                    }
                }
                .padding(.horizontal, 4)
            }
            
            // Description Section
            Text(territory.description)
                .font(.body)
                .bold()
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            // Spacer() // Push content to edges for a cleaner look
        }
        .padding(.horizontal)
        .frame(height: 60)
        .animation(.easeInOut(duration: 0.2), value: progress) // Smooth transition on progress change
        .hSpacing(.center)
    }
    
    
}

//MARK: - ViewModel Extension Publisher
@MainActor
extension NumbersViewModel {
    func getNumbers(phoneNumberToScrollTo: String? = nil) {
        databaseManager.getPhoneNumbersData(phoneTerritoryId: territory.id)
            .subscribe(on: DispatchQueue.main)
            .receive(on: DispatchQueue.main) // Update on main thread
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Handle errors here
                    print(error)
                }
            }, receiveValue: { phoneNumbersData in
                self.phoneNumbersData = phoneNumbersData
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let phoneNumberToScrollTo = phoneNumberToScrollTo {
                        self.phoneNumberToScrollTo = phoneNumberToScrollTo
                    }
                }
                
            })
            .store(in: &cancellables)
    }
}

//MARK: - Delete Phone Number Popup

struct CenterPopup_DeletePhoneNumber: CenterPopup {
    @ObservedObject var viewModel: NumbersViewModel
    var onDone: () -> Void
    
    init(viewModel: NumbersViewModel, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDone = onDone
    }

    var body: some View {
        createContent()
    }

    func createContent() -> some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: "phone.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundColor(.red)

            // Title
            Text("Delete Number: \(viewModel.numberToDelete.1 ?? "0")")
                .font(.title3)
                .fontWeight(.heavy)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            // Subtitle
            Text("Are you sure you want to delete the selected number?")
                .font(.headline)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            // Error
            if viewModel.ifFailed {
                Text("Error deleting number, please try again later")
                    .font(.footnote)
                    .foregroundColor(.red)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
            }

            // Actions
            HStack(spacing: 12) {
                if !viewModel.loading {
                    CustomBackButton(showImage: true, text: NSLocalizedString("Cancel", comment: "")) {
                        HapticManager.shared.trigger(.lightImpact)
                        withAnimation {
                            viewModel.ifFailed = false
                            viewModel.numberToDelete = (nil, nil)
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
                    withAnimation {
                        viewModel.loading = true
                    }

                    Task {
                        if let id = viewModel.numberToDelete.0 {
                            switch await viewModel.deleteNumber(number: id) {
                            case .success:
                                HapticManager.shared.trigger(.success)
                                withAnimation {
                                    viewModel.loading = false
                                    viewModel.ifFailed = false
                                    viewModel.numberToDelete = (nil, nil)
                                    onDone()
                                }
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

//MARK: - Add Number Popup

struct CenterPopup_AddNumber: CenterPopup {
    @ObservedObject var viewModel: NumbersViewModel
    @State var territory: PhoneTerritory
    var onDone: () -> Void

    init(viewModel: NumbersViewModel, territory: PhoneTerritory, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.territory = territory
        self.onDone = onDone
    }

    var body: some View {
        createContent()
    }

    func createContent() -> some View {
        AddPhoneNumberScreen(
            territory: territory,
            number: viewModel.currentNumber,
            onDone: {
                viewModel.presentSheet = false
                Task {
                    await dismissLastPopup()
                }
                onDone()
            },
            onDismiss: {
                viewModel.presentSheet = false
                Task {
                    await dismissLastPopup()
                }
            }
        )
        .background(Material.thin)
        .cornerRadius(20)
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

//MARK: - Phone Number Cell

struct PhoneNumberCell: View {
    @StateObject var callViewModel: CallsViewModel
    @State var numbersData: PhoneNumbersData
    var mainWindowSize: CGSize
    @State private var cancellable: AnyCancellable?
    
    init(numbersData: PhoneNumbersData, mainWindowSize: CGSize) {
        self._callViewModel = StateObject(
            wrappedValue: CallsViewModel(phoneNumber: numbersData.phoneNumber)
        )
        self.numbersData = numbersData
        self.mainWindowSize = mainWindowSize
    }
    
    private var isIpad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad && mainWindowSize.width > 400
    }
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                // — Phone number & house
                Text(numbersData.phoneNumber.number.formatPhoneNumber())
                    .font(.headline).fontWeight(.heavy)
                    .foregroundColor(.primary)
                
                Text("House: \(numbersData.phoneNumber.house ?? "N/A")")
                    .font(.footnote).fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                // — Call preview or “no notes” box
                Group {
                    if let call = numbersData.phoneCall {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(formattedDate(
                                date: Date(timeIntervalSince1970: Double(call.date)/1_000)
                            ))
                            .font(.caption).fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            
                            Text(call.notes)
                                .font(.body).fontWeight(.medium)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                            
                            HStack {
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "person.circle")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(call.user)
                                        .font(.caption).fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "text.bubble")
                                .foregroundColor(.secondary)
                            Text("No notes available.")
                                .font(.body).fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity)     // ← fills full width
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)                            // glass
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 0.6)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
            }
            .padding(10)
            .frame(maxWidth: mainWindowSize.width * 0.90, alignment: .leading)
        }
        .onAppear {
            callViewModel.getCalls()
            cancellable = callViewModel.latestCallUpdatePublisher
                .receive(on: DispatchQueue.main)
                .sink { newCall in
                    if let newCall = newCall,
                       newCall.phonenumber == numbersData.phoneNumber.id,
                       newCall != numbersData.phoneCall {
                        numbersData.phoneCall = newCall
                    } else if newCall == nil {
                        numbersData.phoneCall = nil
                    }
                }
        }
        .onDisappear { cancellable?.cancel() }
        .frame(minWidth: mainWindowSize.width * 0.95)
        .background(.ultraThinMaterial)   // outer glass cell
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .optionalViewModifier { content in
            if isIpad {
                content.frame(maxHeight: .infinity)
            } else {
                content
            }
        }
    }
}
