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
import MijickPopupView

struct RecallsView: View {
    @StateObject private var viewModel = RecallViewModel()
    
    @Environment(\.mainWindowSize) var mainWindowSize
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var preferencesViewModel = ColumnViewModel()
    
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
                                                        RecallRow(viewModel: viewModel, recall: recall, mainWindowSize: mainWindowSize).id(recall.recall.id)
                                                    }
                                                }
                                            } else {
                                                LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                                                    ForEach(viewModel.recalls!, id: \.recall.id) { recall in
                                                        RecallRow(viewModel: viewModel, recall: recall, mainWindowSize: mainWindowSize).id(recall.recall.id)
                                                    }
                                                }
                                            }
                                        }.animation(.spring(), value: viewModel.recalls!)
                                            .padding()
                                    }
                                }
                            }
                        }.animation(.easeInOut(duration: 0.25), value: viewModel.recalls == nil || viewModel.recalls != nil)
                            .navigationBarTitle("Recalls", displayMode: .automatic)
                            .toolbar {
                                ToolbarItemGroup(placement: .topBarTrailing) {
                                    Button("", action: { viewModel.syncAnimation.toggle();  print("Syncing") ; viewModel.synchronizationManager.startupProcess(synchronizing: true) })//.ke yboardShortcut("s", modifiers: .command)
                                        .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $viewModel.dataStore.synchronized, lastTime: $viewModel.dataStore.lastTime))
                                }
                            }
                            .navigationTransition(.slide.combined(with: .fade(.in)))
                            .navigationViewStyle(StackNavigationViewStyle())
                        
                    }.refreshable {
                        viewModel.synchronizationManager.startupProcess(synchronizing: true)
                    }
                    .onChange(of: viewModel.dataStore.synchronized) { value in
                        if value {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                viewModel.getRecalls()
                            }
                        }
                    }
                    .onChange(of: RealtimeManager.shared.lastMessage) { value in
                        if value != nil {
                            viewModel.getRecalls()
                        }
                    }
                    
                    
                }
            }
        }
    }
}

@MainActor
class RecallViewModel: ObservableObject {
    @Published var recalls: Optional<[RecallData]> = nil
    @ObservedObject var dataStore = StorageManager.shared
    
    @Published var syncAnimation = false
    @Published var syncAnimationprogress: CGFloat = 0.0
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    @Published var recallToRemove: String?
    
    @Published var showAlert = false
    
    @Published var ifFailed = false
    
    @Published var loading = false
    
    @Published var showToast = false
    
    
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        getRecalls()
    }
    
    func deleteRecall(user: String, house: String) async -> Result<Bool, Error> {
        return await DataUploaderManager().deleteRecall(recall: Recall(id: Date.now.millisecondsSince1970, user: user, house: house, created_at: "", updated_at: ""))
    }
    
    @MainActor
    func getRecalls() {
        RealmManager.shared.getRecalls()
            .subscribe(on: DispatchQueue.main)
            .receive(on: DispatchQueue.main) // Update on main thread
            .sink { completion in
                if case .failure(let error) = completion {
                    // Handle errors here
                    print("Error retrieving visit data: \(error)")
                }
            } receiveValue: { recalls in
                self.recalls = recalls
            }
            .store(in: &cancellables)
    }
}

struct RecallData: Hashable, Equatable {
    var recall: Recall
    var territory: TerritoryModel
    var territoryAddress: TerritoryAddressModel
    var house: HouseModel
    var visit: VisitModel?
    
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
    var keys: [MyTokenModel]
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

struct RecallRow: View {
    @ObservedObject var viewModel: RecallViewModel
    var recall: RecallData
    var mainWindowSize: CGSize
    var revisitView: Bool = true
    
    var body: some View {
        
        VStack {
            Text(buildPath(territory: recall.territory, address: recall.territoryAddress, house: recall.house)).hSpacing(.leading).font(.headline).fontWeight(.heavy).modifier(ScrollTransitionModifier()).transition(.customBackInsertion)
            SwipeView {
                NavigationLink(destination: NavigationLazyView(VisitsView(house: recall.house)).implementPopupView()) {
                    HouseCell(revisitView: revisitView, house: HouseData(id: UUID(), house: recall.house, accessLevel: AuthorizationLevelManager().getAccessLevel(model: HouseObject().createHouseObject(from: recall.house)) ?? .User), mainWindowSize: mainWindowSize).modifier(ScrollTransitionModifier()).transition(.customBackInsertion)
                }.onTapHaptic(.lightImpact)
            } trailingActions: { context in
                SwipeAction(
                    systemImage: "person.fill.xmark",
                    backgroundColor: .red
                ) {
                    HapticManager.shared.trigger(.lightImpact)
                    context.state.wrappedValue = .closed
                    DispatchQueue.main.async {
                        // self.viewModel.visitToDelete = visitData.visit.id
                        //self.viewModel.showAlert = true
                        //CentrePopup_DeleteVisit(viewModel: viewModel).showAndStack()
                        self.viewModel.recallToRemove = recall.recall.house
                        CentrePopup_RemoveRecall(viewModel: viewModel, recall: recall).showAndStack()
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
    
    public func buildPath(territory: TerritoryModel?, address: TerritoryAddressModel?, house: HouseModel?) -> String {
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

struct CentrePopup_RemoveRecall: CentrePopup {
    @ObservedObject var viewModel: RecallViewModel
    @State var recall: RecallData
    
    func createContent() -> some View {
        ZStack {
            VStack {
                Text("Remove Recall")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                    .padding(.leading)
                Text("Are you sure you want to remove the selected recall?")
                    .font(.headline)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                    .padding(.leading)
                if viewModel.ifFailed {
                    Text("Error removing recall, please try again later")
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                //.vSpacing(.bottom)
                
                HStack {
                    if !viewModel.loading {
                        CustomBackButton() {
                            withAnimation {
                                //self.viewModel.showAlert = false
                                HapticManager.shared.trigger(.lightImpact)
                                dismiss()
                                self.viewModel.recallToRemove = nil
                            }
                        }
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: viewModel.loading, title: NSLocalizedString("Remove", comment: ""), color: .red) {
                        withAnimation {
                            self.viewModel.loading = true
                            HapticManager.shared.trigger(.lightImpact)
                        }
                        Task {
                            if self.viewModel.recallToRemove != nil{
                                switch await self.viewModel.deleteRecall(user: self.recall.recall.user, house: self.recall.recall.house) {
                                case .success(_):
                                    withAnimation {
                                        //self.viewModel.synchronizationManager.startupProcess(synchronizing: true)
                                        self.viewModel.getRecalls()
                                        self.viewModel.loading = false
                                        //self.showAlert = false
                                        dismiss()
                                        self.viewModel.ifFailed = false
                                        self.viewModel.recallToRemove = nil
                                        self.viewModel.showToast = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                            self.viewModel.showToast = false
                                        }
                                    }
                                    HapticManager.shared.trigger(.success)
                                case .failure(_):
                                    withAnimation {
                                        self.viewModel.loading = false
                                        self.viewModel.ifFailed = true
                                        HapticManager.shared.trigger(.error)
                                    }
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
    
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup
            .horizontalPadding(24)
            .cornerRadius(15)
            .backgroundColour(Color(UIColor.systemGray6).opacity(85))
    }
}



#Preview {
    RecallsView()
}
