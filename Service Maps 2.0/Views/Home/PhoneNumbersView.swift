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

struct PhoneNumbersView: View {
    var territory: PhoneTerritoryModel
    
    @StateObject var viewModel: NumbersViewModel
    init(territory: PhoneTerritoryModel) {
        self.territory = territory
        
        let initialViewModel = NumbersViewModel(territory: territory)
        _viewModel = StateObject(wrappedValue: initialViewModel)
    }
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    @State var isLoading = false
    
    let alertViewDeleted = AlertAppleMusic17View(title: "Number Deleted", subtitle: nil, icon: .custom(UIImage(systemName: "trash")!))
    let alertViewAdded = AlertAppleMusic17View(title: "Number Added", subtitle: nil, icon: .done)
    
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    let minimumOffset: CGFloat = 40
    
    var body: some View {
        ZStack {
            ScalingHeaderScrollView {
                ZStack {
                    Color(UIColor.secondarySystemBackground).ignoresSafeArea(.all)
                    viewModel.largeHeader(progress: viewModel.progress)
                }
            } content: {
                VStack {
                    if viewModel.phoneNumbersData == nil || viewModel.dataStore.synchronized == false {
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
                        if viewModel.phoneNumbersData!.isEmpty {
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
                                    ForEach(viewModel.phoneNumbersData!, id: \.self) { numbersData in
                                        viewModel.numbersCell(numbersData: numbersData)
                                            .padding(.bottom, 2)
                                    }
                                    .animation(.default, value: viewModel.phoneNumbersData)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top)
                            .padding(.bottom)
                            
                            
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
                .alert(isPresent: $viewModel.showToast, view: alertViewDeleted)
                .alert(isPresent: $viewModel.showAddedToast, view: alertViewAdded)
                .popup(isPresented: $viewModel.showAlert) {
                    if viewModel.numberToDelete.0 != nil && viewModel.numberToDelete.1 != nil {
                        viewModel.alert()
                            .frame(width: 400, height: 230)
                            .background(Material.thin).cornerRadius(16, corners: .allCorners)
                    }
                } customize: {
                    $0
                        .type(.default)
                        .closeOnTapOutside(false)
                        .dragToDismiss(false)
                        .isOpaque(true)
                        .animation(.spring())
                        .closeOnTap(false)
                        .backgroundColor(.black.opacity(0.8))
                }
                .popup(isPresented: $viewModel.presentSheet) {
                    AddPhoneNumberScreen(territory: territory, number: viewModel.currentNumber, onDone: {
                        DispatchQueue.main.async {
                            viewModel.presentSheet = false
                            synchronizationManager.startupProcess(synchronizing: true)
                            viewModel.getNumbers()
                            viewModel.showAddedToast = true
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                viewModel.showAddedToast = false
                            }
                        }
                    }, onDismiss: {
                        viewModel.presentSheet = false
                    })
                    .frame(width: 400, height: 400)
                    .background(Material.thin).cornerRadius(16, corners: .allCorners)
                } customize: {
                    $0
                        .type(.default)
                        .closeOnTapOutside(false)
                        .dragToDismiss(false)
                        .isOpaque(true)
                        .animation(.spring())
                        .closeOnTap(false)
                        .backgroundColor(.black.opacity(0.8))
                }
                .animation(.easeInOut(duration: 0.25), value: viewModel.phoneNumbersData == nil)
            }
            .height(min: 180, max: 350.0)
            .allowsHeaderGrowth()
            .collapseProgress($viewModel.progress)
            .pullToRefresh(isLoading: $viewModel.dataStore.synchronized.not) {
                synchronizationManager.startupProcess(synchronizing: true)
            }
            .scrollIndicators(.hidden)
            .coordinateSpace(name: "scroll")
            if AuthorizationLevelManager().existsAdminCredentials() {
                    MainButton(imageName: "plus", colorHex: "#00b2f6", width: 60) {
                        self.viewModel.presentSheet = true
                    }
                    .offset(y: hideFloatingButton ? 100 : -25)
                        .animation(.spring(), value: hideFloatingButton)
                        .vSpacing(.bottom).hSpacing(.trailing)
                        .padding()
                }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden()
        .navigationBarTitle("Numbers", displayMode: .inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                HStack {
                    Button("", action: {withAnimation { viewModel.backAnimation.toggle() };
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    })
                    .buttonStyle(CircleButtonStyle(imageName: "arrow.backward", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.backAnimation))
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                HStack {
                    Button("", action: { viewModel.syncAnimation.toggle();  print("Syncing") ; synchronizationManager.startupProcess(synchronizing: true) })
                        .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $viewModel.dataStore.synchronized, lastTime: $viewModel.dataStore.lastTime))
//                    if viewModel.isAdmin {
//                        Button("", action: { viewModel.optionsAnimation.toggle();  print("Add") ; viewModel.presentSheet.toggle() })
//                            .buttonStyle(CircleButtonStyle(imageName: "plus", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.optionsAnimation))
//                    }
                }
            }
        }
        .navigationTransition(viewModel.presentSheet ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
    }
}

@MainActor
class NumbersViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    @ObservedObject var databaseManager = RealmManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var dataUploaderManager = DataUploaderManager()
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    @Published var phoneNumbersData: Optional<[PhoneNumbersData]> = nil
    
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    
    @Published var currentNumber: PhoneNumberModel?
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
    
    func deleteNumber(number: String) async -> Result<Bool,Error> {
        return await dataUploaderManager.deleteNumber(number: number)
    }
    
    @Published var territory: PhoneTerritoryModel
    
    init(territory: PhoneTerritoryModel) {
        self.territory = territory
        
        getNumbers()
    }
    
    @Published var showToast = false
    @Published var showAddedToast = false
    
    @ViewBuilder
    func numbersCell(numbersData: PhoneNumbersData) -> some View {
        LazyVStack {
            SwipeView {
                NavigationLink(destination: NavigationLazyView(CallsView(phoneNumber: numbersData.phoneNumber))) {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(numbersData.phoneNumber.number.formatPhoneNumber())")
                                .font(.headline)
                                .fontWeight(.heavy)
                                .foregroundColor(.primary)
                                .hSpacing(.leading)
                            Text("House: \(numbersData.phoneNumber.house ?? "N/A")")
                                .font(.body)
                                .lineLimit(5)
                                .foregroundColor(.primary)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.leading)
                                .hSpacing(.leading)
                            VStack {
                                HStack {
                                    if let call = numbersData.phoneCall  {
                                            Text("Note: \(call.notes)")
                                                .font(.headline)
                                                .lineLimit(2)
                                                .foregroundColor(.primary)
                                                .fontWeight(.bold)
                                                .multilineTextAlignment(.leading)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .hSpacing(.leading)
                                        
                                    } else {
                                        Text("Note: N/A")
                                            .font(.headline)
                                            .lineLimit(2)
                                            .foregroundColor(.primary)
                                            .fontWeight(.bold)
                                            .multilineTextAlignment(.leading)
                                            .hSpacing(.leading)
                                        
                                    }
                                }
                            }
                            .frame(maxWidth: UIScreen.screenWidth * 0.95, maxHeight: 75)
                        }
                        .frame(maxWidth: UIScreen.screenWidth * 0.90)
                    }
                    //.id(territory.id)
                    .padding(10)
                    .frame(minWidth: UIScreen.main.bounds.width * 0.95)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            } trailingActions: { context in
                if self.isAdmin {
                    SwipeAction(
                        systemImage: "trash",
                        backgroundColor: .red
                    ) {
                        DispatchQueue.main.async {
                            self.numberToDelete = (numbersData.phoneNumber.id, String(numbersData.phoneNumber.number))
                            self.showAlert = true
                        }
                    }
                    .font(.title.weight(.semibold))
                    .foregroundColor(.white)
                    SwipeAction(
                        systemImage: "pencil",
                        backgroundColor: Color.teal
                    ) {
                        context.state.wrappedValue = .closed
                        self.currentNumber = numbersData.phoneNumber
                        self.presentSheet = true
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
            .swipeMinimumDistance(self.isAdmin ? 25:1000)
        }
    }
    
    @ViewBuilder
    func largeHeader(progress: CGFloat) -> some View  {
        LazyVStack {
            ZStack {
                VStack {
                    LazyImage(url: URL(string: territory.getImageURL())) { state in
                        if let image = state.image {
                            image.resizable().aspectRatio(contentMode: .fill).frame(width: UIScreen.screenWidth, height: 350)
                            
                            //image.opacity(1 - progress)
                            
                        } else if state.isLoading  {
                            ProgressView().progressViewStyle(.circular)
                            
                        } else if state.error != nil {
                            Image(uiImage: UIImage(named: "mapImage")!)
                                .resizable()
                                .frame(width: 100, height: 100)
                                .padding(.bottom, 125)
                        } else {
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
                .frame(width: UIScreen.screenSize.width, height: 350, alignment: .center)
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
            .frame(width: UIScreen.screenWidth, height: 350)
        }
        
        .animation(.default, value: progress)
    }
    
    @ViewBuilder
    var smallHeader: some View {
        HStack(spacing: 12.0) {
            HStack {
                Image(systemName: "numbersign").imageScale(.large).fontWeight(.heavy)
                    .foregroundColor(.primary).font(.title2)
                Text("\(territory.number)")
                    .font(.largeTitle)
                    .bold()
                    .fontWeight(.heavy)
            }
            
            Divider()
                .frame(maxHeight: 75)
                .padding(.horizontal, -5)
            if !(progress < 0.98) {
                LazyImage(url: URL(string: territory.getImageURL())) { state in
                    if let image = state.image {
                        image.resizable().aspectRatio(contentMode: .fill).frame(maxWidth: 75, maxHeight: 60)
                    } else if state.error != nil {
                        Image(uiImage: UIImage(named: "mapImage")!)
                            .resizable()
                            .frame(width: 75, height: 75)
                        //.padding(.bottom, 125)
                    } else {
                        ProgressView().progressViewStyle(.circular)
                    }
                }
                
                .cornerRadius(10)
                .padding(.horizontal, 2)
            }
            Text(territory.description)
                .font(.body)
                .fontWeight(.heavy)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxHeight: 75)
        .animation(.easeInOut(duration: 0.25), value: progress)
        .padding(.horizontal)
        .hSpacing(.center)
    }
    
    @ViewBuilder
    func alert() -> some View {
        ZStack {
            VStack {
                Text("Delete Number: \(numberToDelete.1 ?? "0")")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                    .padding(.leading)
                Text("Are you sure you want to delete the selected number?")
                    .font(.headline)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                    .padding(.leading)
                if ifFailed {
                    Text("Error deleting number, please try again later")
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                //.vSpacing(.bottom)
                
                HStack {
                    if !loading {
                        CustomBackButton() {
                            withAnimation {
                                self.showAlert = false
                                self.ifFailed = false
                                self.numberToDelete = (nil,nil)
                            }
                        }
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: loading, title: "Delete", color: .red) {
                        withAnimation {
                            self.loading = true
                        }
                        Task {
                            if self.numberToDelete.0 != nil && self.numberToDelete.1 != nil {
                                switch await self.deleteNumber(number: self.numberToDelete.0 ?? "") {
                                case .success(_):
                                    withAnimation {
                                        self.synchronizationManager.startupProcess(synchronizing: true)
                                        self.getNumbers()
                                        self.loading = false
                                        self.showAlert = false
                                        self.ifFailed = false
                                        self.numberToDelete = (nil,nil)
                                        self.showToast = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                            self.showToast = false
                                        }
                                    }
                                case .failure(_):
                                    withAnimation {
                                        self.loading = false
                                    }
                                    self.ifFailed = true
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
    }
}

@MainActor
extension NumbersViewModel {
    func getNumbers() {
        databaseManager.getPhoneNumbersData(phoneTerritoryId: territory.id)
            .receive(on: DispatchQueue.main) // Update on main thread
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Handle errors here
                    print("Error retrieving territory data: \(error)")
                }
            }, receiveValue: { phoneNumbersData in
                DispatchQueue.main.async {
                    self.phoneNumbersData = phoneNumbersData.sorted { $0.phoneNumber.number < $1.phoneNumber.number }
                }
            })
            .store(in: &cancellables)
    }
}

extension Binding where Value == Bool {
    // nagative bool binding same as `!Value`
    var not: Binding<Value> {
        Binding<Value> (
            get: { !self.wrappedValue },
            set: { self.wrappedValue = $0}
        )
    }
}

struct NavigationLazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}
