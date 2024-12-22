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
                        }.background(GeometryReader {
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
                                CentrePopup_AddNumber(viewModel: viewModel, territory: territory){
                                    let toast = ToastValue(
                                        icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green),
                                        message: "Number Added"
                                    )
                                    presentToast(toast)
                                }.present()
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
                                dismissAllPopups()
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
                                            
                                            CentrePopup_DeletePhoneNumber(viewModel: viewModel){
                                                let toast = ToastValue(
                                                    icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                                    message: NSLocalizedString("Number Deleted", comment: "")
                                                )
                                                presentToast(toast)
                                            }.present()
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
                        
                        CentrePopup_DeletePhoneNumber(viewModel: viewModel){
                            let toast = ToastValue(
                                icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                message: NSLocalizedString("Number Deleted", comment: "")
                            )
                            presentToast(toast)
                        }.present()
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

//MARK: - Delete Number Popup

struct CentrePopup_DeletePhoneNumber: CentrePopup {
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
        ZStack {
            VStack {
                Text("Delete Number: \(viewModel.numberToDelete.1 ?? "0")")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                    .padding(.leading)
                Text("Are you sure you want to delete the selected number?")
                    .font(.headline)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                    .padding(.leading)
                if viewModel.ifFailed {
                    Text("Error deleting number, please try again later")
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                //.vSpacing(.bottom)
                
                HStack {
                    if !viewModel.loading {
                        CustomBackButton() {
                            HapticManager.shared.trigger(.lightImpact)
                            withAnimation {
                                dismissLastPopup()
                                self.viewModel.ifFailed = false
                                self.viewModel.numberToDelete = (nil,nil)
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
                            if self.viewModel.numberToDelete.0 != nil && self.viewModel.numberToDelete.1 != nil {
                                switch await self.viewModel.deleteNumber(number: self.viewModel.numberToDelete.0 ?? "") {
                                case .success(_):
                                    HapticManager.shared.trigger(.success)
                                    withAnimation {
                                        //self.viewModel.synchronizationManager.startupProcess(synchronizing: true)
                                        //self.viewModel.getNumbers()
                                        self.viewModel.loading = false
                                        dismissLastPopup()
                                        self.viewModel.ifFailed = false
                                        self.viewModel.numberToDelete = (nil,nil)
                                        onDone()
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

//MARK: - Add Number Popup

struct CentrePopup_AddNumber: CentrePopup {
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
        AddPhoneNumberScreen(territory: territory, number: viewModel.currentNumber, onDone: {
            DispatchQueue.main.async {
                viewModel.presentSheet = false
                dismissLastPopup()
                onDone()
            }
        }, onDismiss: {
            viewModel.presentSheet = false
            dismissLastPopup()
        })
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

//MARK: - Phone Number Cell

struct PhoneNumberCell: View {
    @StateObject var callViewModel: CallsViewModel
    @State var numbersData: PhoneNumbersData
    var mainWindowSize: CGSize
    @State private var cancellable: AnyCancellable?
    
    init(numbersData: PhoneNumbersData, mainWindowSize: CGSize) {
        self._callViewModel = StateObject(wrappedValue: CallsViewModel(phoneNumber: numbersData.phoneNumber))
        self.numbersData = numbersData
        self.mainWindowSize = mainWindowSize
    }
    
    var isIpad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad && mainWindowSize.width > 400
    }
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(numbersData.phoneNumber.number.formatPhoneNumber())")
                    .font(.headline)
                    .fontWeight(.heavy)
                    .foregroundColor(.primary)
                    .hSpacing(.leading)
                    .padding(.leading, 5)
                Text("House: \(numbersData.phoneNumber.house ?? "N/A")")
                    .font(.footnote)
                    .lineLimit(5)
                    .foregroundColor(.secondaryLabel)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                    .hSpacing(.leading)
                    .padding(.leading, 5)
                if let call = numbersData.phoneCall {
                    VStack {
                        HStack {
                            Text("\(formattedDate(date: Date(timeIntervalSince1970: Double(call.date) / 1000)))")
                                .font(.footnote)
                                .lineLimit(2)
                                .foregroundColor(.secondaryLabel)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .hSpacing(.leading)
                        }
                        HStack {
                            Text("\(call.notes)")
                                .font(.body)
                                .lineLimit(2)
                                .foregroundColor(.secondaryLabel)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .hSpacing(.leading)
                        }
                    }
                    .frame(maxWidth: mainWindowSize.width * 0.95, maxHeight: 75)
                    .hSpacing(.leading).padding(10).background(Color.gray.opacity(0.2)) // Subtle background color
                    .cornerRadius(16)
                } else {
                    HStack {
                        Image(systemName: "text.word.spacing")
                            .resizable()
                            .imageScale(.medium)
                            .foregroundColor(.secondaryLabel)
                            .frame(width: 20, height: 20)
                        Text(NSLocalizedString("No notes available.", comment: ""))
                            .font(.body)
                            .lineLimit(2)
                            .foregroundColor(.secondaryLabel)
                            .fontWeight(.bold)
                        
                    }.hSpacing(.leading).padding(.leading, 5).padding(10).background(Color.gray.opacity(0.2)) // Subtle background color
                        .cornerRadius(16)
                }
            }
            .frame(maxWidth: mainWindowSize.width * 0.90)
        }
        .onAppear {
            callViewModel.getCalls()
            cancellable = callViewModel.latestCallUpdatePublisher
                .subscribe(on: DispatchQueue.main)
                .sink { newCall in
                    // Check if the update is for the correct house and if it's a new/different visit
                    if let newCall = newCall, newCall.phonenumber == self.numbersData.phoneNumber.id, newCall != numbersData.phoneCall {
                        numbersData.phoneCall = newCall
                    } else if newCall == nil {
                        numbersData.phoneCall = nil
                    }
                }
        }
        .onDisappear {
            cancellable?.cancel()
        }
        //.id(territory.id)
        .padding(10)
        .frame(minWidth: mainWindowSize.width * 0.95)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .optionalViewModifier { content in
            if isIpad {
                content
                    .frame(maxHeight: .infinity)
            } else {
                content
            }
        }
    }
}
