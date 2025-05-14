//
//  AccessView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/7/23.
//

import SwiftUI
import NavigationTransitions
import SwipeActions
import Combine
import UIKit
import Lottie
import AlertKit
import MijickPopups
import Toasts

// MARK: - AccessView

struct AccessView: View {
    
    // MARK: - Environment
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.presentToast) var presentToast
    @Environment(\.mainWindowSize) var mainWindowSize
    
    // MARK: - Dependencies
    
    @ObservedObject var viewModel: AccessViewModel
    @ObservedObject var databaseManager = GRDBManager.shared
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var preferencesViewModel = ColumnViewModel()
    
    // MARK: - Properties
    
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    let minimumOffset: CGFloat = 40
    
    @State var keydataToEdit: KeyData?
    
    @State private var scrollDebounceCancellable: AnyCancellable?
    
    // MARK: - Initializers
    
    init() {
        let viewModel = AccessViewModel()
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ScrollView {
                    VStack {
                        if viewModel.keyData == nil && viewModel.dataStore.synchronized == false {
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
                            if let data = viewModel.keyData {
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
                                    SwipeViewGroup {
                                        if UIDevice().userInterfaceIdiom == .pad && proxy.size.width > 400 && preferencesViewModel.isColumnViewEnabled {
                                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                                ForEach(viewModel.keyData!, id: \.key.id) { keyData in
                                                    if viewModel.isAdmin {
                                                        NavigationLink(destination: NavigationLazyView(AccessViewUsersView(viewModel: viewModel, currentKey: keyData.key).installToast(position: .bottom))) {
                                                            keyCell(keyData: keyData).id(keyData.id)
                                                                .transition(.customBackInsertion)
                                                        }.onTapHaptic(.lightImpact)
                                                    } else {
                                                        keyCell(keyData: keyData).id(keyData.id)
                                                    }
                                                }.modifier(ScrollTransitionModifier())
                                            }
                                        } else {
                                            LazyVGrid(columns: [GridItem(.flexible())]) {
                                                ForEach(viewModel.keyData!, id: \.key.id) { keyData in
                                                    if viewModel.isAdmin {
                                                        NavigationLink(destination: NavigationLazyView(AccessViewUsersView(viewModel: viewModel, currentKey: keyData.key).installToast(position: .bottom))) {
                                                            keyCell(keyData: keyData).id(keyData.id)
                                                                .transition(.customBackInsertion)
                                                        }.onTapHaptic(.lightImpact)
                                                    } else {
                                                        keyCell(keyData: keyData).id(keyData.id)
                                                    }
                                                }.modifier(ScrollTransitionModifier())
                                            }
                                        }
                                    }
                                    .animation(.spring(), value: viewModel.keyData)
                                    .padding()
                                    
                                    
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
                        .animation(.easeInOut(duration: 0.25), value: viewModel.keyData == nil || viewModel.keyData != nil)
                        
                        .navigationDestination(isPresented: $viewModel.presentSheet) {
                            AddKeyView(keyData: keydataToEdit) {
                                //synchronizationManager.startupProcess(synchronizing: true)
                               // viewModel.getKeys()
                                keydataToEdit = nil
                                DispatchQueue.main.async {
                                    viewModel.showAddedToast = true
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    viewModel.showAddedToast = false
                                }
                            }.environment(\.mainWindowSize, mainWindowSize)
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
                        .navigationBarTitle("Keys", displayMode: .automatic)
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarTrailing) {
                                HStack {
                                    Button("", action: { viewModel.syncAnimation = true; synchronizationManager.startupProcess(synchronizing: true) })//.keyboardShortcut("s", modifiers: .command)
                                        .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $dataStore.synchronized, lastTime: $dataStore.lastTime))
                                }
                            }
                        }
                        .navigationTransition(viewModel.presentSheet ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
                        .navigationViewStyle(StackNavigationViewStyle())
                }
                
                .coordinateSpace(name: "scroll")
                .scrollIndicators(.never)
                .refreshable {
                    synchronizationManager.startupProcess(synchronizing: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        hideFloatingButton = false
                    }
                }
                .onChange(of: viewModel.dataStore.synchronized) { value in
                    if value {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            viewModel.getKeys()
                            viewModel.getKeyUsers()
                        }
                    }
                }
                if viewModel.isAdmin {
                    
                    MainButton(imageName: "plus", colorHex: "#1e6794", width: 60) {
                        keydataToEdit = nil
                        self.viewModel.presentSheet = true
                    }
                    .offset(y: hideFloatingButton ? 150 : 0)
                    .animation(.spring(), value: hideFloatingButton)
                    .vSpacing(.bottom).hSpacing(.trailing)
                    .padding()
                    //.keyboardShortcut("+", modifiers: .command)
                }
            }
        }
    }
    
    //MARK: - Key Cell

    @ViewBuilder
    func keyCell(keyData: KeyData) -> some View {
        SwipeView {
            TokenCell(keyData: keyData, ipad: UIDevice().userInterfaceIdiom == .pad)
                .padding(.bottom, 2)
                .contextMenu {
                    Button {
                        HapticManager.shared.trigger(.lightImpact)
                        self.viewModel.keyToDelete = (keyData.key.id, keyData.key.name)
                        Task {
                            await CenterPopup_DeleteKey(viewModel: viewModel, keyToDelete: viewModel.keyToDelete){
                                let toast = ToastValue(
                                    icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                    message: NSLocalizedString("Key Deleted", comment: "")
                                )
                                presentToast(toast)
                            }.present()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Key")
                        }
                    }
                    if viewModel.isAdmin {
                        Button {
                            HapticManager.shared.trigger(.lightImpact)
                            DispatchQueue.main.async {
                                keydataToEdit = keyData
                                viewModel.presentSheet = true
                            }
                            
                        } label: {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit Key")
                            }
                        }
                    }
                    Button {
                        HapticManager.shared.trigger(.lightImpact)
                        let url = URL(string: getShareLink(id: keyData.key.id))
                        let territories = keyData.territories.map { String($0.number) }
                        let itemSource = CustomActivityItemSource(keyName: keyData.key.name, territories: territories, url: url!)

                        let av = UIActivityViewController(activityItems: [itemSource], applicationActivities: nil)

                        // Find the active UIWindowScene
                        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                            
                            rootVC.present(av, animated: true, completion: nil)
                            
                            if UIDevice.current.userInterfaceIdiom == .pad {
                                av.popoverPresentationController?.sourceView = windowScene.windows.first
                                av.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2.1, y: UIScreen.main.bounds.height / 1.3, width: 200, height: 200)
                            }
                        }
                        
                        
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Key")
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } trailingActions: { context in
            SwipeAction(
                systemImage: "trash",
                backgroundColor: .red
            ) {
                HapticManager.shared.trigger(.lightImpact)
                context.state.wrappedValue = .closed
                Task {
                    await CenterPopup_DeleteKey(viewModel: viewModel, keyToDelete: (keyData.key.id, keyData.key.name)){
                        let toast = ToastValue(
                            icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                            message: NSLocalizedString("Key Deleted", comment: "")
                        )
                        presentToast(toast)
                    }.present()
                }
            }
            .font(.title.weight(.semibold))
            .foregroundColor(.white)
            
            
            if viewModel.isAdmin {
                SwipeAction(
                    systemImage: "pencil",
                    backgroundColor: .teal
                ) {
                    HapticManager.shared.trigger(.lightImpact)
                    context.state.wrappedValue = .closed
                    keydataToEdit = keyData
                    viewModel.presentSheet = true
                    
                    
                }
                .font(.title.weight(.semibold))
                .foregroundColor(.white)
            }
            
            SwipeAction(
                systemImage: "square.and.arrow.up",
                backgroundColor: Color.green
            ) {
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    HapticManager.shared.trigger(.lightImpact)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    HapticManager.shared.trigger(.lightImpact)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    HapticManager.shared.trigger(.lightImpact)
                }
                
                let url = URL(string: getShareLink(id: keyData.key.id))
                let territories = keyData.territories.map { String($0.number) }
                
                let itemSource = CustomActivityItemSource(keyName: keyData.key.name, territories: territories, url: url!)
                
                let av = UIActivityViewController(activityItems: [itemSource], applicationActivities: nil)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
                    HapticManager.shared.trigger(.lightImpact)
                    
                    // Find the active UIWindowScene
                    if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                       let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                        
                        rootVC.present(av, animated: true, completion: nil)
                        
                        if UIDevice.current.userInterfaceIdiom == .pad {
                            av.popoverPresentationController?.sourceView = windowScene.windows.first
                            av.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2.1, y: UIScreen.main.bounds.height / 1.3, width: 200, height: 200)
                        }
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) {
                    HapticManager.shared.trigger(.lightImpact)
                }
                
                context.state.wrappedValue = .closed
            }
            .allowSwipeToTrigger()
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

//MARK: - CustomActivityItemSource

class CustomActivityItemSource: NSObject, UIActivityItemSource {
    var keyName: String
    var territories: [String]
    var url: URL
    
    init(keyName: String, territories: [String], url: URL) {
        self.keyName = keyName
        self.territories = territories
        self.url = url
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return url
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        if activityType == .airDrop {
            // For AirDrop, just share the URL
            return url
        } else {
            // For other types, share the formatted text
            let territoriesString = territories.joined(separator: ", ")
            return "\(keyName)\nTerritories: \(territoriesString)\n\n\(url.absoluteString)"
        }
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return keyName
    }
}

//MARK: - AccessViewUsersView

struct AccessViewUsersView: View {
    
    //MARK: - Environment
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.presentToast) var presentToast
    @Environment(\.mainWindowSize) var mainWindowSize
    
    //MARK: - Dependencies
    
    @StateObject var viewModel = AccessViewModel()
    @ObservedObject var databaseManager = GRDBManager.shared
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    //MARK: - Properties
    
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    let minimumOffset: CGFloat = 60
    @State var currentKey: Token
    
    //MARK: - Alert Views
    
    let alertViewDeleted = AlertAppleMusic17View(title: "User Deleted", subtitle: nil, icon: .custom(UIImage(systemName: "trash")!))
    let alertViewBlocked = AlertAppleMusic17View(title: "User Blocked", subtitle: nil, icon: .custom(UIImage(systemName: "nosign")!))
    let alertViewUnblocked = AlertAppleMusic17View(title: "User Unblocked", subtitle: nil, icon: .custom(UIImage(systemName: "checkmark")!))
    
    //MARK: - Initializers
    
    init(viewModel: AccessViewModel, currentKey: Token) {
        self.currentKey = currentKey
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ScrollView {
                    VStack {
                        if viewModel.keyUsers == nil || viewModel.dataStore.synchronized == false {
                            if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" {
                                LottieView(animation: .named("loadsimple"))
                                    .playing(loopMode: .loop)
                                    .resizable()
                                    .animationDidFinish { completed in
                                        self.animationDone = completed
                                    }
                                    .frame(width: 250, height: 250)
                            } else {
                                LottieView(animation: .named("loadsimple"))
                                    .playing(loopMode: .loop)
                                    .resizable()
                                    .animationDidFinish { completed in
                                        self.animationDone = completed
                                    }
                                    .frame(width: 350, height: 350)
                            }
                        } else {
                            if viewModel.keyUsers!.isEmpty {
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
                                        LazyVStack {
                                            ForEach(viewModel.keyUsers!, id: \.id) { keyData in
                                                SwipeView {
                                                    UserTokenCell(userKeyData: keyData)
                                                        .contextMenu {
                                                            if viewModel.isAdmin || AuthorizationLevelManager().existsModeratorAccess() {
                                                                Button {
                                                                    HapticManager.shared.trigger(.lightImpact)
                                                                    DispatchQueue.main.async {
                                                                        
                                                                        self.viewModel.userToDelete = (keyData.id, keyData.name)
                                                                        //self.showAlert = true
                                                                        Task {
                                                                            await CenterPopup_DeleteUser(viewModel: viewModel){
                                                                                let toast = ToastValue(
                                                                                    icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                                                                    message: NSLocalizedString("User Deleted", comment: "")
                                                                                )
                                                                                presentToast(toast)
                                                                            }.present()
                                                                        }
                                                                    }
                                                                } label: {
                                                                    HStack {
                                                                        Image(systemName: "trash")
                                                                        Text("Delete User")
                                                                    }
                                                                }
                                                            }
                                                        }.clipShape(RoundedRectangle(cornerRadius: 16, style: .circular))
                                                } trailingActions: { context in
                                                    if viewModel.isAdmin || AuthorizationLevelManager().existsModeratorAccess() {
                                                        SwipeAction(
                                                            systemImage: keyData.blocked ? "arrowshape.turn.up.left.2" : "nosign",
                                                            backgroundColor: keyData.blocked ? .green.opacity(0.5) : .pink.opacity(0.5)
                                                        ) {
                                                            HapticManager.shared.trigger(.lightImpact)
                                                            DispatchQueue.main.async {
                                                                context.state.wrappedValue = .closed
                                                                // Set the block/unblock action here with a UserAction object
                                                                self.viewModel.blockUnblockAction = UserAction(userToken: keyData, isBlocked: keyData.blocked)
                                                                Task {
                                                                    await CenterPopup_BlockOrUnblockUser(viewModel: viewModel).present()
                                                                }
                                                            }
                                                        }
                                                        .font(.title.weight(.semibold))
                                                        .foregroundColor(.white)
                                                        
                                                        SwipeAction(
                                                            systemImage: "trash",
                                                            backgroundColor: .red
                                                        ) {
                                                            HapticManager.shared.trigger(.lightImpact)
                                                            
                                                            DispatchQueue.main.async {
                                                                context.state.wrappedValue = .closed
                                                                self.viewModel.userToDelete = (keyData.id, keyData.name)  // Set userToDelete for deletion
                                                                Task {
                                                                    await CenterPopup_DeleteUser(viewModel: viewModel){
                                                                        let toast = ToastValue(
                                                                            icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                                                            message: NSLocalizedString("User Deleted", comment: "")
                                                                        )
                                                                        presentToast(toast)
                                                                    }.present()
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
                                                .swipeMinimumDistance(AuthorizationLevelManager().existsAdminCredentials() ? 25 : 1000)
                                            }.modifier(ScrollTransitionModifier())
                                        }
                                        .animation(.spring(), value: viewModel.keyUsers!)
                                        if !viewModel.blockedUsers!.isEmpty {
                                            Text("Blocked Users")
                                                .font(.title)
                                                .fontWeight(.bold)
                                                .padding()
                                            LazyVStack {
                                                ForEach(viewModel.blockedUsers!, id: \.id) { keyData in
                                                    if keyData.blocked {
                                                        SwipeView {
                                                            UserTokenCell(userKeyData: keyData)
                                                                .contextMenu {
                                                                    if viewModel.isAdmin || AuthorizationLevelManager().existsModeratorAccess() {
                                                                        Button {
                                                                            HapticManager.shared.trigger(.lightImpact)
                                                                            DispatchQueue.main.async {
                                                                                self.viewModel.userToDelete = (keyData.id, keyData.name)
                                                                                //self.showAlert = true
                                                                                Task {
                                                                                    await CenterPopup_DeleteUser(viewModel: viewModel){
                                                                                        let toast = ToastValue(
                                                                                            icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                                                                            message: NSLocalizedString("User Deleted", comment: "")
                                                                                        )
                                                                                        presentToast(toast)
                                                                                    }.present()
                                                                                }
                                                                            }
                                                                        } label: {
                                                                            HStack {
                                                                                Image(systemName: "trash")
                                                                                Text("Delete User")
                                                                            }
                                                                        }
                                                                    }
                                                                }.clipShape(RoundedRectangle(cornerRadius: 16, style: .circular))
                                                        } trailingActions: { context in
                                                            if viewModel.isAdmin || AuthorizationLevelManager().existsModeratorAccess() {
                                                                SwipeAction(
                                                                    systemImage: keyData.blocked ? "arrowshape.turn.up.left.2" : "nosign",
                                                                    backgroundColor: keyData.blocked ? .green.opacity(0.5) : .pink.opacity(0.5)
                                                                ) {
                                                                    HapticManager.shared.trigger(.lightImpact)
                                                                    DispatchQueue.main.async {
                                                                        context.state.wrappedValue = .closed
                                                                        // Set the block/unblock action here with a UserAction object
                                                                        self.viewModel.blockUnblockAction = UserAction(userToken: keyData, isBlocked: keyData.blocked)
                                                                        Task {
                                                                            await CenterPopup_BlockOrUnblockUser(viewModel: viewModel).present()
                                                                        }
                                                                    }
                                                                }
                                                                .font(.title.weight(.semibold))
                                                                .foregroundColor(.white)
                                                                
                                                                SwipeAction(
                                                                    systemImage: "trash",
                                                                    backgroundColor: .red
                                                                ) {
                                                                    HapticManager.shared.trigger(.lightImpact)
                                                                    DispatchQueue.main.async {
                                                                        context.state.wrappedValue = .closed
                                                                        self.viewModel.userToDelete = (keyData.id, keyData.name)
                                                                        //self.showAlert = true
                                                                        Task {
                                                                            await CenterPopup_DeleteUser(viewModel: viewModel){
                                                                                let toast = ToastValue(
                                                                                    icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                                                                    message: NSLocalizedString("User Deleted", comment: "")
                                                                                )
                                                                                presentToast(toast)
                                                                            }.present()
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
                                                        .swipeMinimumDistance(AuthorizationLevelManager().existsAdminCredentials() ? 25 : 1000)
                                                    }
                                                }
                                            }.animation(.spring(), value: viewModel.blockedUsers)
                                        }
                                    }
                                }
                                
                                .padding()
                                
                                
                            }
                        }
                    }.hSpacing(.center)
                        .animation(.easeInOut(duration: 0.25), value: viewModel.keyUsers == nil || viewModel.keyUsers != nil)
                        .navigationBarTitle("\(currentKey.name)", displayMode: .automatic)
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarLeading) {
                                HStack {
                                    Button("", action: {withAnimation { viewModel.backAnimation.toggle() };
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
                        }
                        .navigationTransition(viewModel.presentSheet ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
                        .navigationViewStyle(StackNavigationViewStyle())
                }
                .scrollIndicators(.never)
            }
        }
        .onAppear {
            viewModel.currentKey = currentKey
        }
        .onDisappear {
            viewModel.currentKey = nil
            viewModel.keyUsers = nil
        }
        .onChange(of: viewModel.showUserBlockAlert) { value in
            if value {
                let toast = ToastValue(
                    icon: Image(systemName: "exclamationmark.octagon.fill").foregroundStyle(.red),
                    message: "User Blocked"
                )
                presentToast(toast)
            }
        }
        .onChange(of: viewModel.showUserUnblockAlert) { value in
            if value {
                let toast = ToastValue(
                    icon: Image(systemName: "checkmark.diamond.fill").foregroundStyle(.green),
                    message: "User Unblocked"
                )
                presentToast(toast)
            }
        }
    }
    
    //MARK: - User Cell
    @ViewBuilder
    func keyCell(keyData: UserToken) -> some View {
        SwipeView {
            UserTokenCell(userKeyData: keyData)
                .padding(.bottom, 2)
                .contextMenu {
                    Button {
                        HapticManager.shared.trigger(.lightImpact)
                        DispatchQueue.main.async {
                            self.viewModel.userToDelete = (keyData.id, keyData.name)
                            //self.showAlert = true
                            Task {
                                await CenterPopup_DeleteUser(viewModel: viewModel){
                                    let toast = ToastValue(
                                        icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                        message: NSLocalizedString("User Deleted", comment: "")
                                    )
                                    presentToast(toast)
                                }.present()
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete User")
                        }
                    }
                }.clipShape(RoundedRectangle(cornerRadius: 16, style: .circular))
        } trailingActions: { context in
            if viewModel.isAdmin || AuthorizationLevelManager().existsModeratorAccess() {
                SwipeAction(
                    systemImage: "trash",
                    backgroundColor: .red
                ) {
                    HapticManager.shared.trigger(.lightImpact)
                    
                    DispatchQueue.main.async {
                        context.state.wrappedValue = .closed
                        self.viewModel.userToDelete = (keyData.id, keyData.name)
                        //self.showAlert = true
                        Task {
                            await CenterPopup_DeleteUser(viewModel: viewModel){
                                let toast = ToastValue(
                                    icon: Image(systemName: "trash.circle.fill").foregroundStyle(.red),
                                    message: NSLocalizedString("User Deleted", comment: "")
                                )
                                presentToast(toast)
                            }.present()
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

//MARK: - Delete Key Popup

struct CenterPopup_DeleteKey: CenterPopup {
    @ObservedObject var viewModel: AccessViewModel
    var keyToDelete: (String?, String?)
    var onDone: () -> Void

    init(viewModel: AccessViewModel, keyToDelete: (String?, String?), onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.keyToDelete = keyToDelete
        self.onDone = onDone
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "key.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundColor(.red)

            Text("Delete Key: \(keyToDelete.1 ?? "0")")
                .font(.title2)
                .fontWeight(.heavy)
                .multilineTextAlignment(.center)

            Text("Are you sure you want to delete the selected key?")
                .font(.body)
                .multilineTextAlignment(.center)

            if viewModel.ifFailed {
                Text("Error deleting key, please try again later.")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }

            HStack(spacing: 12) {
                if !viewModel.loading {
                    CustomBackButton(showImage: true, text: NSLocalizedString("Cancel", comment: "")) {
                        HapticManager.shared.trigger(.lightImpact)
                        withAnimation {
                            viewModel.keyToDelete = (nil, nil)
                        }
                        Task { await dismissLastPopup() }
                    }
                    .frame(maxWidth: .infinity)
                }

                CustomButton(loading: viewModel.loading, title: "Delete", color: .red) {
                    HapticManager.shared.trigger(.lightImpact)
                    withAnimation { viewModel.loading = true }

                    Task {
                        if let keyId = keyToDelete.0 {
                            let result = await viewModel.deleteKey(key: keyId)
                            DispatchQueue.main.async {
                                switch result {
                                case .success:
                                    HapticManager.shared.trigger(.success)
                                    viewModel.loading = false
                                    viewModel.keyToDelete = (nil, nil)
                                    onDone()
                                    Task { await dismissLastPopup() }
                                case .failure:
                                    HapticManager.shared.trigger(.error)
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

//MARK: - Delete User Popup

struct CenterPopup_DeleteUser: CenterPopup {
    @ObservedObject var viewModel: AccessViewModel
    var onDone: () -> Void

    init(viewModel: AccessViewModel, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDone = onDone
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.xmark")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundColor(.red)

            Text("Delete User: \(viewModel.userToDelete?.name ?? "0")")
                .font(.title2)
                .fontWeight(.heavy)
                .multilineTextAlignment(.center)

            Text("Are you sure you want to delete the selected user?")
                .font(.body)
                .multilineTextAlignment(.center)

            if viewModel.ifFailed {
                Text("Error deleting user, please try again later.")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }

            HStack(spacing: 12) {
                if !viewModel.loading {
                    CustomBackButton(showImage: true, text: NSLocalizedString("Cancel", comment: "")) {
                        HapticManager.shared.trigger(.lightImpact)
                        withAnimation { viewModel.userToDelete = (nil, nil) }
                        Task { await dismissLastPopup() }
                    }
                    .frame(maxWidth: .infinity)
                }

                CustomButton(loading: viewModel.loading, title: "Delete", color: .red) {
                    HapticManager.shared.trigger(.lightImpact)
                    withAnimation { viewModel.loading = true }

                    Task {
                        if let userId = viewModel.userToDelete?.id {
                            let result = await viewModel.deleteUser(user: userId)
                            DispatchQueue.main.async {
                                switch result {
                                case .success:
                                    HapticManager.shared.trigger(.success)
                                    viewModel.loading = false
                                    viewModel.userToDelete = (nil, nil)
                                    viewModel.getKeyUsers()
                                    onDone()
                                    Task { await dismissLastPopup() }
                                case .failure:
                                    HapticManager.shared.trigger(.error)
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

//MARK: - Block/Unblock User Popup

struct CenterPopup_BlockOrUnblockUser: CenterPopup {
    @ObservedObject var viewModel: AccessViewModel

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: viewModel.blockUnblockAction?.isBlocked == true ? "person.badge.shield.checkmark" : "person.badge.shield.exclamationmark")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundColor(viewModel.blockUnblockAction?.isBlocked == true ? .green : .red)

            Text("\(viewModel.blockUnblockAction?.isBlocked == true ? "Unblock" : "Block") User")
                .font(.title2)
                .fontWeight(.heavy)
                .multilineTextAlignment(.center)

            Text("Are you sure you want to \(viewModel.blockUnblockAction?.isBlocked == true ? "unblock" : "block") the selected user?")
                .font(.body)
                .multilineTextAlignment(.center)

            if viewModel.ifFailed {
                Text("Error \(viewModel.blockUnblockAction?.isBlocked == true ? "unblocking" : "blocking") user, please try again later.")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }

            HStack(spacing: 12) {
                if !viewModel.loading {
                    CustomBackButton(showImage: true, text: NSLocalizedString("Cancel", comment: "")) {
                        HapticManager.shared.trigger(.lightImpact)
                        withAnimation {
                            viewModel.blockUnblockAction = nil
                            viewModel.ifFailed = false
                        }
                        Task { await dismissLastPopup() }
                    }
                    .frame(maxWidth: .infinity)
                }

                CustomButton(
                    loading: viewModel.loading,
                    title: viewModel.blockUnblockAction?.isBlocked == true ? "Unblock" : "Block",
                    color: viewModel.blockUnblockAction?.isBlocked == true ? .green : .red
                ) {
                    HapticManager.shared.trigger(.lightImpact)
                    withAnimation { viewModel.loading = true }

                    Task {
                        if let userAction = viewModel.blockUnblockAction {
                            let result = await viewModel.blockUnblockUserFromToken(user: userAction)
                            DispatchQueue.main.async {
                                switch result {
                                case .success:
                                    HapticManager.shared.trigger(.success)
                                    viewModel.loading = false
                                    viewModel.blockUnblockAction = nil
                                    if userAction.isBlocked {
                                        viewModel.showUserUnblockAlert = true
                                    } else {
                                        viewModel.showUserBlockAlert = true
                                    }
                                    Task { await dismissLastPopup() }
                                case .failure:
                                    HapticManager.shared.trigger(.error)
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
