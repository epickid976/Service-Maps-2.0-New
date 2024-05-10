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
import PopupView
import AlertKit
import Nuke
import FloatingButton
import MijickPopupView

struct TerritoryView: View {
    
    
    @ObservedObject var viewModel = TerritoryViewModel()
    
    //@Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    @Environment(\.presentationMode) var presentationMode
    
    
    init() {
        
    }
    
    let alertViewDeleted = AlertAppleMusic17View(title: "Territory Deleted", subtitle: nil, icon: .custom(UIImage(systemName: "trash")!))
    let alertViewAdded = AlertAppleMusic17View(title: "Territory Added", subtitle: nil, icon: .done)
    
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    let minimumOffset: CGFloat = 40
    
    //@Environment(\.mainWindowSize) var mainWindowSize
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ScrollView {
                    LazyVStack {
                        if viewModel.territoryData == nil || viewModel.dataStore.synchronized == false {
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
                            if viewModel.territoryData!.isEmpty {
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
                                LazyVStack {
                                    SwipeViewGroup {
                                        ForEach(viewModel.territoryData!, id: \.self) { dataWithKeys in
                                            territoryCell(dataWithKeys: dataWithKeys, mainViewSize: proxy.size)
                                        }
                                        .animation(.default, value: viewModel.territoryData!)
                                    }
                                    
                                }
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
                    .animation(.easeInOut(duration: 0.25), value: viewModel.territoryData == nil || viewModel.territoryData != nil)
                    .alert(isPresent: $viewModel.showToast, view: alertViewDeleted)
                    .alert(isPresent: $viewModel.showAddedToast, view: alertViewAdded)
                    .navigationDestination(isPresented: $viewModel.presentSheet) {
                        AddTerritoryView(territory: viewModel.currentTerritory) {
                            synchronizationManager.startupProcess(synchronizing: true)
                            DispatchQueue.main.async {
                                viewModel.showAddedToast = true
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                viewModel.showAddedToast = false
                            }
                        }.simultaneousGesture(
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
                    //                    .popup(isPresented: $viewModel.showAlert) {
                    //                        if viewModel.territoryToDelete.0 != nil && viewModel.territoryToDelete.1 != nil {
                    //                            viewModel.alert()
                    //                                .frame(width: 400, height: 230)
                    //                                .background(Material.thin).cornerRadius(16, corners: .allCorners)
                    //                        }
                    //                    } customize: {
                    //                        $0
                    //                            .type(.default, screenSize: mainWindowSize)
                    //                            .closeOnTapOutside(false)
                    //                            .dragToDismiss(false)
                    //                            .isOpaque(true)
                    //                            .animation(.spring())
                    //                            .closeOnTap(false)
                    //                            .backgroundColor(.black.opacity(0.8))
                    //                            .position(.center)
                    //                    }
                    
                    .navigationBarTitle("Territories", displayMode: .automatic)
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            HStack {
                                Button("", action: { viewModel.syncAnimation.toggle();  print("Syncing") ; synchronizationManager.startupProcess(synchronizing: true) })
                                    .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $viewModel.dataStore.synchronized, lastTime: $viewModel.dataStore.lastTime))
                                //                            if viewModel.isAdmin {
                                //                                Button("", action: { viewModel.optionsAnimation.toggle();  print("Add") ; viewModel.presentSheet.toggle() })
                                //                                    .buttonStyle(CircleButtonStyle(imageName: "plus", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.optionsAnimation))
                                //                            }
                            }
                        }
                    }
                    .navigationTransition(viewModel.presentSheet ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
                    .navigationViewStyle(StackNavigationViewStyle())
                }.coordinateSpace(name: "scroll")
                    .scrollIndicators(.hidden)
                    .refreshable {
                        synchronizationManager.startupProcess(synchronizing: true)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            hideFloatingButton = false
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
    
    @ViewBuilder
    func territoryCell(dataWithKeys: TerritoryDataWithKeys, mainViewSize: CGSize) -> some View {
        
        LazyVStack {
            if !dataWithKeys.keys.isEmpty {
                Text(self.viewModel.processData(dataWithKeys: dataWithKeys))
                    .font(.title2)
                    .lineLimit(1)
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
        // Loop through territoryData here (replace with your TerritoryItemView implementation)
        LazyVStack {
            ForEach(dataWithKeys.territoriesData, id: \.territory.id) { territoryData in
                SwipeView {
                    NavigationLink(destination: NavigationLazyView( TerritoryAddressView(territory: territoryData.territory).implementPopupView()).implementPopupView()) {
                        CellView(territory: territoryData.territory, houseQuantity: territoryData.housesQuantity, mainWindowSize: mainViewSize)
                            .padding(.bottom, 2)
                        
                    }
                } trailingActions: { context in
                    if territoryData.accessLevel == .Admin {
                        SwipeAction(
                            systemImage: "trash",
                            backgroundColor: .red
                        ) {
                            DispatchQueue.main.async {
                                self.viewModel.territoryToDelete = (territoryData.territory.id, String(territoryData.territory.number))
                                //self.showAlert = true
                                CentrePopup_DeleteTerritoryAlert(viewModel: viewModel).showAndStack()
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
                .swipeMinimumDistance(territoryData.accessLevel != .User ? 25:1000)
            }
        }.padding(.horizontal, 15)
        
    }
}


struct MainButton: View {
    
    var imageName: String
    var colorHex: String
    var width: CGFloat = 50
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                Color(hex: colorHex)
                    .frame(width: width, height: width)
                    .cornerRadius(width / 2)
                    .shadow(color: Color(hex: colorHex).opacity(0.3), radius: 15, x: 0, y: 15)
                Image(systemName: imageName)
                    .foregroundColor(.white)
            }
        }
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
struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct CentrePopup_DeleteTerritoryAlert: CentrePopup {
    @ObservedObject var viewModel: TerritoryViewModel
    
    
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
                            withAnimation {
                                //self.viewModel.showAlert = false
                                dismiss()
                                self.viewModel.territoryToDelete = (nil,nil)
                            }
                        }
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: viewModel.loading, title: "Delete", color: .red) {
                        withAnimation {
                            self.viewModel.loading = true
                        }
                        Task {
                            if self.viewModel.territoryToDelete.0 != nil && self.viewModel.territoryToDelete.1 != nil {
                                switch await self.viewModel.deleteTerritory(territory: self.viewModel.territoryToDelete.0 ?? "") {
                                case .success(_):
                                    withAnimation {
                                        withAnimation {
                                            self.viewModel.loading = false
                                        }
                                        //self.showAlert = false
                                        dismiss()
                                        self.viewModel.territoryToDelete = (nil,nil)
                                        self.viewModel.showToast = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                            self.viewModel.showToast = false
                                        }
                                    }
                                case .failure(_):
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
    
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup
            .horizontalPadding(24)
            .cornerRadius(15)
            .backgroundColour(Color(UIColor.systemGray6).opacity(85))
    }
}
