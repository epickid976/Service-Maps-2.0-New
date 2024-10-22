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

struct AccessView: View {
    @StateObject var viewModel: AccessViewModel
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var databaseManager = GRDBManager.shared
    
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    
    let alertViewDeleted = AlertAppleMusic17View(title: "Key Deleted", subtitle: nil, icon: .custom(UIImage(systemName: "trash")!))
    let alertViewAdded = AlertAppleMusic17View(title: "Key Added/Edited", subtitle: nil, icon: .done)
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @Environment(\.mainWindowSize) var mainWindowSize
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    let minimumOffset: CGFloat = 40
    
    @State var keydataToEdit: KeyData?
    
    @State private var scrollDebounceCancellable: AnyCancellable?
    
    init() {
        let viewModel = AccessViewModel()
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    @ObservedObject var preferencesViewModel = ColumnViewModel()
    
    
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
                                                    NavigationLink(destination: NavigationLazyView(AccessViewUsersView(viewModel: viewModel, currentKey: keyData.key))) {
                                                        keyCell(keyData: keyData).id(keyData.id)
                                                            .transition(.customBackInsertion)
                                                    }
                                                }.modifier(ScrollTransitionModifier())
                                            }
                                        } else {
                                            LazyVGrid(columns: [GridItem(.flexible())]) {
                                                ForEach(viewModel.keyData!, id: \.key.id) { keyData in
                                                    NavigationLink(destination: NavigationLazyView(AccessViewUsersView(viewModel: viewModel, currentKey: keyData.key))) {
                                                        keyCell(keyData: keyData).id(keyData.key.id)
                                                            .transition(.customBackInsertion)
                                                    }.onTapHaptic(.lightImpact)
                                                }.modifier(ScrollTransitionModifier())
                                            }
                                        }
                                    }
                                    .animation(.spring(), value: viewModel.keyData)
                                    .padding()
                                    
                                    
                                }
                            }
                        }
                    }.hSpacing(.center)
//                        .background(GeometryReader {
//                            Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
//                        }).onPreferenceChange(ViewOffsetKey.self) { currentOffset in
//                            let offsetDifference: CGFloat = self.previousViewOffset - currentOffset
//                            if ( abs(offsetDifference) > minimumOffset) {
//                                if offsetDifference > 0 {
//                                    
//                                    debounceHideFloatingButton(false)
//                                } else {
//                                    
//                                    debounceHideFloatingButton(true)
//                                }
//                                self.previousViewOffset = currentOffset
//                            }
//                        }
                        .animation(.easeInOut(duration: 0.25), value: viewModel.keyData == nil || viewModel.keyData != nil)
                        .alert(isPresent: $viewModel.showToast, view: alertViewDeleted)
                        .alert(isPresent: $viewModel.showAddedToast, view: alertViewAdded)
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
                    
                    //.scrollIndicators(.never)
                        .navigationBarTitle("Keys", displayMode: .automatic)
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarTrailing) {
                                HStack {
                                    Button("", action: { viewModel.syncAnimation.toggle(); synchronizationManager.startupProcess(synchronizing: true) })//.keyboardShortcut("s", modifiers: .command)
                                        .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $viewModel.dataStore.synchronized, lastTime: $viewModel.dataStore.lastTime))
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
    
//    private func debounceHideFloatingButton(_ hide: Bool) {
//        scrollDebounceCancellable?.cancel()
//        scrollDebounceCancellable = Just(hide)
//            .throttle(for: .milliseconds(0), scheduler: RunLoop.main, latest: true)
//            .sink { shouldHide in
//                //withAnimation {
//                    self.hideFloatingButton = shouldHide
//                //}
//            }
//    }
//    
    @ViewBuilder
    func keyCell(keyData: KeyData) -> some View {
        SwipeView {
            TokenCell(keyData: keyData, ipad: UIDevice().userInterfaceIdiom == .pad)
                .padding(.bottom, 2)
                .contextMenu {
                    Button {
                        HapticManager.shared.trigger(.lightImpact)
                        self.viewModel.keyToDelete = (keyData.key.id, keyData.key.name)
                        CentrePopup_DeleteKey(viewModel: viewModel).present()
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
                        
                        UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                        
                        if UIDevice.current.userInterfaceIdiom == .pad {
                            av.popoverPresentationController?.sourceView = UIApplication.shared.windows.first
                            av.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2.1, y: UIScreen.main.bounds.height / 1.3, width: 200, height: 200)
                        }
                        
                        
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Key")
                        }
                    }
                    //TODO Trash and Pencil only if admin
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } trailingActions: { context in
            SwipeAction(
                systemImage: "trash",
                backgroundColor: .red
            ) {
                HapticManager.shared.trigger(.lightImpact)
                context.state.wrappedValue = .closed
                CentrePopup_DeleteKey(viewModel: viewModel, keyToDelete: (keyData.key.id, keyData.key.name)).present()
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
                    UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                    
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        av.popoverPresentationController?.sourceView = UIApplication.shared.windows.first
                        av.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2.1, y: UIScreen.main.bounds.height / 1.3, width: 200, height: 200)
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

struct AccessViewUsersView: View {
    
    @StateObject var viewModel = AccessViewModel()
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var databaseManager = GRDBManager.shared
    
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    
    let alertViewDeleted = AlertAppleMusic17View(title: "User Deleted", subtitle: nil, icon: .custom(UIImage(systemName: "trash")!))
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @Environment(\.mainWindowSize) var mainWindowSize
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    let minimumOffset: CGFloat = 60
    @State var currentKey: Token
    
    init(viewModel: AccessViewModel, currentKey: Token) {
        self.currentKey = currentKey
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    let alertViewBlocked = AlertAppleMusic17View(title: "User Blocked", subtitle: nil, icon: .custom(UIImage(systemName: "nosign")!))
    let alertViewUnblocked = AlertAppleMusic17View(title: "User Unblocked", subtitle: nil, icon: .custom(UIImage(systemName: "checkmark")!))
    
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
                                                                        CentrePopup_DeleteUser(viewModel: viewModel).present()
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
                                                                self.viewModel.blockUnblockAction = UserAction(id: keyData.id, isBlocked: keyData.blocked)
                                                                CentrePopup_BlockOrUnblockUser(viewModel: viewModel).present()
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
                                                                CentrePopup_DeleteUser(viewModel: viewModel).present()
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
                                                                                CentrePopup_DeleteUser(viewModel: viewModel).present()
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
                                                                        self.viewModel.blockUnblockAction = UserAction(id: keyData.id, isBlocked: keyData.blocked)
                                                                        CentrePopup_BlockOrUnblockUser(viewModel: viewModel).present()
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
                                                                        CentrePopup_DeleteUser(viewModel: viewModel).present()
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
                        .alert(isPresent: $viewModel.showToast, view: alertViewDeleted)
                        .alert(isPresent: $viewModel.showUserBlockAlert, view: alertViewBlocked)
                        .alert(isPresent: $viewModel.showUserUnblockAlert, view: alertViewUnblocked)
                        .navigationBarTitle("\(currentKey.name)", displayMode: .automatic)
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarLeading) {
                                HStack {
                                    Button("", action: {withAnimation { viewModel.backAnimation.toggle() };
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            dismissAllPopups()
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
    }
    
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
                            CentrePopup_DeleteUser(viewModel: viewModel).present()
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
                        CentrePopup_DeleteUser(viewModel: viewModel).present()
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

struct CentrePopup_DeleteKey: CentrePopup {
    @ObservedObject var viewModel: AccessViewModel
    var keyToDelete: (String?,String?)
    
    var body: some View {
        ZStack {
            VStack {
                Text("Delete Key: \(keyToDelete.1 ?? "0")")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                    .padding(.leading)
                Text("Are you sure you want to delete the selected key?")
                    .font(.headline)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                    .padding(.leading)
                if viewModel.ifFailed {
                    Text("Error deleting key, please try again later")
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                //.vSpacing(.bottom)
                
                HStack {
                    if !viewModel.loading {
                        CustomBackButton() {
                            HapticManager.shared.trigger(.lightImpact)
                            withAnimation {
                                self.viewModel.keyToDelete = (nil,nil)
                                dismissLastPopup()
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
                            try await Task.sleep(nanoseconds: 1_500_000_000)
                            if self.keyToDelete.0 != nil && self.keyToDelete.1 != nil {
                                switch await self.viewModel.deleteKey(key: self.keyToDelete.0 ?? "") {
                                case .success(_):
                                    HapticManager.shared.trigger(.success)
                                    withAnimation {
                                        self.viewModel.loading = false
                                    }
                                    dismissLastPopup()
                                    self.viewModel.keyToDelete = (nil,nil)
                                        //self.viewModel.showAlert = false
                                     self.viewModel.showToast = true
                                     DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        self.viewModel.showToast = false
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

struct CentrePopup_DeleteUser: CentrePopup {
    @ObservedObject var viewModel: AccessViewModel
    
    var body: some View {
        createContent()
    }
    
    func createContent() -> some View {
        ZStack {
            VStack {
                Text("Delete User: \(viewModel.userToDelete?.name ?? "0")")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                    .padding(.leading)
                
                Text("Are you sure you want to delete the selected user?")
                    .font(.headline)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                    .padding(.leading)
                
                if viewModel.ifFailed {
                    Text("Error deleting user, please try again later")
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                
                HStack {
                    if !viewModel.loading {
                        CustomBackButton() {
                            HapticManager.shared.trigger(.lightImpact)
                            withAnimation {
                                dismissLastPopup()
                                self.viewModel.userToDelete = (nil, nil)
                            }
                        }
                    }
                    
                    CustomButton(loading: viewModel.loading, title: NSLocalizedString("Delete", comment: ""), color: .red) {
                        HapticManager.shared.trigger(.lightImpact)
                        withAnimation {
                            self.viewModel.loading = true
                        }
                        
                        Task {
                            if let userId = self.viewModel.userToDelete?.id {
                                switch await self.viewModel.deleteUser(user: userId) {
                                case .success(_):
                                    HapticManager.shared.trigger(.success)
                                    withAnimation {
                                        self.viewModel.loading = false
                                        self.viewModel.getKeyUsers()
                                    }
                                    dismissLastPopup()
                                    self.viewModel.userToDelete = (nil, nil)
                                    self.viewModel.showToast = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        self.viewModel.showToast = false
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
            }
            .ignoresSafeArea(.keyboard)
        }
        .ignoresSafeArea(.keyboard)
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

struct CentrePopup_BlockOrUnblockUser: CentrePopup {
    @ObservedObject var viewModel: AccessViewModel
    
    var body: some View {
        createContent()
    }

    func createContent() -> some View {
        ZStack {
            VStack {
                Text("\(viewModel.blockUnblockAction?.isBlocked == true ? "Unblock" : "Block") User")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                    .padding(.leading)

                Text("Are you sure you want to \(viewModel.blockUnblockAction?.isBlocked == true ? "unblock" : "block") the selected user?")
                    .font(.headline)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                    .padding(.leading)

                if viewModel.ifFailed {
                    Text("Error \(viewModel.blockUnblockAction?.isBlocked == true ? "unblocking" : "blocking") user, please try again later")
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }

                HStack {
                    if !viewModel.loading {
                        CustomBackButton() {
                            HapticManager.shared.trigger(.lightImpact)
                            withAnimation {
                                dismissLastPopup()
                                self.viewModel.blockUnblockAction = nil
                                self.viewModel.ifFailed = false
                            }
                        }
                    }

                    CustomButton(loading: viewModel.loading, title: "\(viewModel.blockUnblockAction?.isBlocked == true ? "Unblock" : "Block")", color: viewModel.blockUnblockAction?.isBlocked == true ? .green : .red) {
                        HapticManager.shared.trigger(.lightImpact)
                        withAnimation {
                            self.viewModel.loading = true
                        }

                        Task {
                            if let userAction = self.viewModel.blockUnblockAction {
                                switch await self.viewModel.blockUnblockUserFromToken(user: userAction) {
                                case .success(_):
                                    HapticManager.shared.trigger(.success)
                                    withAnimation {
                                        self.viewModel.loading = false
                                        self.viewModel.getKeyUsers()  // Update the list of users after block/unblock
                                    }
                                    dismissLastPopup()
                                    if userAction.isBlocked {
                                        self.viewModel.showUserUnblockAlert = true
                                    } else {
                                        self.viewModel.showUserBlockAlert = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        self.viewModel.showUserBlockAlert = false
                                        self.viewModel.showUserUnblockAlert = false
                                    }
                                    self.viewModel.blockUnblockAction = nil
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
            }
            .ignoresSafeArea(.keyboard)
        }
        .ignoresSafeArea(.keyboard)
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