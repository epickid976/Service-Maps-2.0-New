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
import MijickPopupView

struct AccessView: View {
    @StateObject var viewModel: AccessViewModel
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var databaseManager = RealmManager.shared
    
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
    
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ScrollView {
                    VStack {
                        if viewModel.keyData == nil || viewModel.dataStore.synchronized == false {
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
                            if viewModel.keyData!.isEmpty {
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
                                        ForEach(viewModel.keyData!, id: \.id) { keyData in
                                            NavigationLink(destination: NavigationLazyView(AccessViewUsersView(viewModel: viewModel, currentKey: keyData.key))) {
                                                keyCell(keyData: keyData)
                                            }
                                        }.modifier(ScrollTransitionModifier())
                                    }
                                }
                                .animation(.spring(), value: viewModel.keyData)
                                .padding()
                                
                                
                            }
                        }
                    }.hSpacing(.center)
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    }).onPreferenceChange(ViewOffsetKey.self) { currentOffset in
                        let offsetDifference: CGFloat = self.previousViewOffset - currentOffset
                        if ( abs(offsetDifference) > minimumOffset) {
                            if offsetDifference > 0 {
                                print("Is scrolling up toward top.")
                               debounceHideFloatingButton(false)
                            } else {
                                print("Is scrolling down toward bottom.")
                                debounceHideFloatingButton(true)
                            }
                            self.previousViewOffset = currentOffset
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: viewModel.keyData == nil || viewModel.keyData != nil)
                    .alert(isPresent: $viewModel.showToast, view: alertViewDeleted)
                    .alert(isPresent: $viewModel.showAddedToast, view: alertViewAdded)
                    .navigationDestination(isPresented: $viewModel.presentSheet) {
                        AddKeyView(keyData: keydataToEdit) {
                            synchronizationManager.startupProcess(synchronizing: true)
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
                    
                    //.scrollIndicators(.hidden)
                    .navigationBarTitle("Keys", displayMode: .automatic)
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            HStack {
                                Button("", action: { viewModel.syncAnimation.toggle();  print("Syncing") ; synchronizationManager.startupProcess(synchronizing: true) }).keyboardShortcut("s", modifiers: .command)
                                    .buttonStyle(PillButtonStyle(imageName: "plus", background: .white.opacity(0), width: 100, height: 40, progress: $viewModel.syncAnimationprogress, animation: $viewModel.syncAnimation, synced: $viewModel.dataStore.synchronized, lastTime: $viewModel.dataStore.lastTime))
                            }
                        }
                    }
                    .navigationTransition(viewModel.presentSheet ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
                    .navigationViewStyle(StackNavigationViewStyle())
                }
                
                .coordinateSpace(name: "scroll")
                    .scrollIndicators(.hidden)
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
                        .animation(.spring(), value:hideFloatingButton)
                        .vSpacing(.bottom).hSpacing(.trailing)
                        .padding()
                        .keyboardShortcut("+", modifiers: .command)
                }
            }
        }
    }
    
    private func debounceHideFloatingButton(_ hide: Bool) {
            scrollDebounceCancellable?.cancel()
            scrollDebounceCancellable = Just(hide)
            .throttle(for: .milliseconds(0), scheduler: RunLoop.main, latest: true)
                .sink { shouldHide in
                    withAnimation {
                        self.hideFloatingButton = shouldHide
                    }
                }
        }
    
    @ViewBuilder
    func keyCell(keyData: KeyData) -> some View {
        SwipeView {
            TokenCell(keyData: keyData)
                .padding(.bottom, 2)
                .contextMenu {
                    Button {
                        self.viewModel.keyToDelete = (keyData.key.id, keyData.key.name)
                        CentrePopup_DeleteKey(viewModel: viewModel).showAndStack()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Key")
                        }
                    }
                    if viewModel.isAdmin {
                        Button {
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
                context.state.wrappedValue = .closed
                CentrePopup_DeleteKey(viewModel: viewModel, keyToDelete: (keyData.key.id, keyData.key.name)).showAndStack()
            }
            .font(.title.weight(.semibold))
            .foregroundColor(.white)
            
            
            if viewModel.isAdmin {
                SwipeAction(
                    systemImage: "pencil",
                    backgroundColor: .teal
                ) {
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
                
                
                
                let url = URL(string: getShareLink(id: keyData.key.id))
                let territories = keyData.territories.map { String($0.number) }
                
                let itemSource = CustomActivityItemSource(keyName: keyData.key.name, territories: territories, url: url!)
                
                let av = UIActivityViewController(activityItems: [itemSource], applicationActivities: nil)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
                    UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                    
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        av.popoverPresentationController?.sourceView = UIApplication.shared.windows.first
                        av.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2.1, y: UIScreen.main.bounds.height / 1.3, width: 200, height: 200)
                    }
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
    @ObservedObject var databaseManager = RealmManager.shared
    
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    
    let alertViewDeleted = AlertAppleMusic17View(title: "User Deleted", subtitle: nil, icon: .custom(UIImage(systemName: "trash")!))
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @Environment(\.mainWindowSize) var mainWindowSize
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    let minimumOffset: CGFloat = 60
    @State var currentKey: MyTokenModel
    
    init(viewModel: AccessViewModel, currentKey: MyTokenModel) {
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
                                                                    DispatchQueue.main.async {
                                                                        self.viewModel.userToDelete = (keyData.id, keyData.name)
                                                                        //self.showAlert = true
                                                                        CentrePopup_DeleteUser(viewModel: viewModel).showAndStack()
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
                                                            systemImage: "nosign",
                                                            backgroundColor: .pink.opacity(0.5)
                                                        ) {
                                                            DispatchQueue.main.async {
                                                                context.state.wrappedValue = .closed
                                                                self.viewModel.userToDelete = (keyData.userId, keyData.blocked ? "false" : "true")
                                                                //self.showAlert = true
                                                                CentrePopup_BlockOrUnblockUser(viewModel: viewModel).showAndStack()
                                                            }
                                                        }
                                                        .font(.title.weight(.semibold))
                                                        .foregroundColor(.white)
                                                        
                                                        SwipeAction(
                                                            systemImage: "trash",
                                                            backgroundColor: .red
                                                        ) {
                                                            DispatchQueue.main.async {
                                                                context.state.wrappedValue = .closed
                                                                self.viewModel.userToDelete = (keyData.id, keyData.name)
                                                                //self.showAlert = true
                                                                CentrePopup_DeleteUser(viewModel: viewModel).showAndStack()
                                                            }
                                                        }
                                                        .font(.title.weight(.semibold))
                                                        .foregroundColor(.white)
                                                    }
                                                }
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
                                                                            DispatchQueue.main.async {
                                                                                self.viewModel.userToDelete = (keyData.id, keyData.name)
                                                                                //self.showAlert = true
                                                                                CentrePopup_DeleteUser(viewModel: viewModel).showAndStack()
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
                                                                    systemImage: "arrowshape.turn.up.left.2",
                                                                    backgroundColor: .green.opacity(0.5)
                                                                ) {
                                                                    DispatchQueue.main.async {
                                                                        self.viewModel.userToDelete = (keyData.userId, keyData.blocked ? "false" : "true")
                                                                        //self.showAlert = true
                                                                        context.state.wrappedValue = .closed
                                                                        CentrePopup_BlockOrUnblockUser(viewModel: viewModel).showAndStack()
                                                                    }
                                                                }
                                                                .font(.title.weight(.semibold))
                                                                .foregroundColor(.white)
                                                                
                                                                SwipeAction(
                                                                    systemImage: "trash",
                                                                    backgroundColor: .red
                                                                ) {
                                                                    DispatchQueue.main.async {
                                                                        context.state.wrappedValue = .closed
                                                                        self.viewModel.userToDelete = (keyData.id, keyData.name)
                                                                        //self.showAlert = true
                                                                        CentrePopup_DeleteUser(viewModel: viewModel).showAndStack()
                                                                    }
                                                                }
                                                                .font(.title.weight(.semibold))
                                                                .foregroundColor(.white)
                                                            }
                                                        }
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
                        .navigationBarTitle("Users", displayMode: .automatic)
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarLeading) {
                                HStack {
                                    Button("", action: {withAnimation { viewModel.backAnimation.toggle() };
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            presentationMode.wrappedValue.dismiss()
                                        }
                                    }).keyboardShortcut(.delete, modifiers: .command)
                                        .buttonStyle(CircleButtonStyle(imageName: "arrow.backward", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.backAnimation))
                                }
                            }
                        }
                        .navigationTransition(viewModel.presentSheet ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
                        .navigationViewStyle(StackNavigationViewStyle())
                }
                .scrollIndicators(.hidden)
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
    func keyCell(keyData: UserTokenModel) -> some View {
        SwipeView {
            UserTokenCell(userKeyData: keyData)
                .padding(.bottom, 2)
                .contextMenu {
                    Button {
                        DispatchQueue.main.async {
                            self.viewModel.userToDelete = (keyData.id, keyData.name)
                            //self.showAlert = true
                            CentrePopup_DeleteUser(viewModel: viewModel).showAndStack()
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
                    DispatchQueue.main.async {
                        context.state.wrappedValue = .closed
                        self.viewModel.userToDelete = (keyData.id, keyData.name)
                        //self.showAlert = true
                        CentrePopup_DeleteUser(viewModel: viewModel).showAndStack()
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
    
    func createContent() -> some View {
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
                            withAnimation {
                                dismiss()
                                
                            }
                        }
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: viewModel.loading, title: "Delete", color: .red) {
                        withAnimation {
                            self.viewModel.loading = true
                        }
                        Task {
                            if self.keyToDelete.0 != nil && self.keyToDelete.1 != nil {
                                switch await self.viewModel.deleteKey(key: self.keyToDelete.0 ?? "") {
                                case .success(_):
                                    withAnimation {
                                        withAnimation {
                                            self.viewModel.loading = false
                                            self.viewModel.getKeys()
                                        }
                                        //self.viewModel.showAlert = false
                                        dismiss()
                                        
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

struct CentrePopup_DeleteUser: CentrePopup {
    @ObservedObject var viewModel: AccessViewModel
    
    
    
    func createContent() -> some View {
        ZStack {
            VStack {
                Text("Delete User: \(viewModel.userToDelete.1 ?? "0")")
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
                //.vSpacing(.bottom)
                
                HStack {
                    if !viewModel.loading {
                        CustomBackButton() {
                            withAnimation {
                                dismiss()
                                self.viewModel.userToDelete = (nil,nil)
                            }
                        }
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: viewModel.loading, title: "Delete", color: .red) {
                        withAnimation {
                            self.viewModel.loading = true
                        }
                        Task {
                            if self.viewModel.userToDelete.0 != nil && self.viewModel.userToDelete.1 != nil {
                                switch await self.viewModel.deleteUser(user: self.viewModel.userToDelete.0 ?? "") {
                                case .success(_):
                                    withAnimation {
                                        withAnimation {
                                            self.viewModel.loading = false
                                            self.viewModel.getKeyUsers()
                                        }
                                        //self.viewModel.showAlert = false
                                        dismiss()
                                        self.viewModel.userToDelete = (nil,nil)
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

struct CentrePopup_BlockOrUnblockUser: CentrePopup {
    @ObservedObject var viewModel: AccessViewModel
    
    
    
    func createContent() -> some View {
        ZStack {
            VStack {
                Text("\(viewModel.userToDelete.1 == "true" ? NSLocalizedString("Block", comment: "") : NSLocalizedString("Unblock", comment: "")) User")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                    .padding(.leading)
                Text("Are you sure you want to \(viewModel.userToDelete.1 == "true" ? NSLocalizedString("block", comment: "") : NSLocalizedString("unblock", comment: "")) the selected user?")
                    .font(.headline)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                    .padding(.leading)
                if viewModel.ifFailed {
                    Text("Error \(viewModel.userToDelete.1 == "true" ? NSLocalizedString("blocking",comment: "") : NSLocalizedString("unblocking", comment: "")) user, please try again later")
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                //.vSpacing(.bottom)
                
                HStack {
                    if !viewModel.loading {
                        CustomBackButton() {
                            withAnimation {
                                dismiss()
                                self.viewModel.userToDelete = (nil,nil)
                                self.viewModel.ifFailed = false
                            }
                        }
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: viewModel.loading, title: "\(viewModel.userToDelete.1 == "true" ? NSLocalizedString("Block", comment: "") : NSLocalizedString("Unblock", comment: ""))", color: viewModel.userToDelete.1 == "true" ? .red : .green) {
                        withAnimation {
                            self.viewModel.loading = true
                        }
                        Task {
                            if self.viewModel.userToDelete.0 != nil && self.viewModel.userToDelete.1 != nil {
                                switch await self.viewModel.blockUnblockUserFromToken() {
                                case .success(_):
                                    //SynchronizationManager.shared.startupProcess(synchronizing: true)
                                    withAnimation {
                                        
                                        withAnimation {
                                            self.viewModel.loading = false
                                            self.viewModel.getKeyUsers()
                                        }
                                        //self.viewModel.showAlert = false
                                        dismiss()
                                       
                                        if viewModel.userToDelete.1 == "true" {
                                            self.viewModel.showUserBlockAlert = true
                                        } else {
                                            
                                            self.viewModel.showUserUnblockAlert = true
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                            self.viewModel.showUserBlockAlert = false
                                            self.viewModel.showUserUnblockAlert = false
                                        }
                                        self.viewModel.userToDelete = (nil,nil)
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
