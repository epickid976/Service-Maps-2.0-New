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
import PopupView
import AlertKit
import MijickPopupView

struct AccessView: View {
    @ObservedObject var viewModel = AccessViewModel()
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var databaseManager = RealmManager.shared
    
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    
    let alertViewDeleted = AlertAppleMusic17View(title: "Key Deleted", subtitle: nil, icon: .custom(UIImage(systemName: "trash")!))
    let alertViewAdded = AlertAppleMusic17View(title: "Key Added", subtitle: nil, icon: .done)
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @Environment(\.mainWindowSize) var mainWindowSize
    @State private var hideFloatingButton = false
    @State var previousViewOffset: CGFloat = 0
    let minimumOffset: CGFloat = 40
    
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
                            if viewModel.keyData!.isEmpty {
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
                                        ForEach(viewModel.keyData!, id: \.self) { keyData in
                                            keyCell(keyData: keyData)
                                        }
                                        .animation(.default, value: viewModel.keyData!)
                                    }
                                }
                                .animation(.spring(), value: viewModel.keyData)
                                .padding()
                                
                                
                            }
                        }
                    }
                    .background(GeometryReader {
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
                    .animation(.easeInOut(duration: 0.25), value: viewModel.keyData == nil || viewModel.keyData != nil)
                    .alert(isPresent: $viewModel.showToast, view: alertViewDeleted)
                    .alert(isPresent: $viewModel.showAddedToast, view: alertViewAdded)
                    //                    .popup(isPresented: $viewModel.showAlert) {
                    //                        if viewModel.keyToDelete.0 != nil && viewModel.keyToDelete.1 != nil {
                    //                            viewModel.alert()
                    //                                .frame(width: 400, height: 230)
                    //                                .background(Material.thin).cornerRadius(16, corners: .allCorners)
                    //                        }
                    //                    } customize: {
                    //                        $0
                    //                            .type(.default)
                    //                            .closeOnTapOutside(false)
                    //                            .dragToDismiss(false)
                    //                            .isOpaque(true)
                    //                            .animation(.spring())
                    //                            .closeOnTap(false)
                    //                            .backgroundColor(.black.opacity(0.8))
                    //                    }
                    
                    .navigationDestination(isPresented: $viewModel.presentSheet) {
                        AddKeyView {
                            synchronizationManager.startupProcess(synchronizing: true)
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
                    .offset(y: hideFloatingButton ? 150 : 0)
                    .animation(.spring(), value: hideFloatingButton)
                    .vSpacing(.bottom).hSpacing(.trailing)
                    .padding()
                }
            }
        }
    }
    @ViewBuilder
    func keyCell(keyData: KeyData) -> some View {
        SwipeView {
            TokenCell(keyData: keyData)
                .padding(.bottom, 2)
        } trailingActions: { context in
            SwipeAction(
                systemImage: "trash",
                backgroundColor: .red
            ) {
                DispatchQueue.main.async {
                    self.viewModel.keyToDelete = (keyData.key.id, keyData.key.name)
                    //self.showAlert = true
                    CentrePopup_DeleteKey(viewModel: viewModel).showAndStack()
                }
            }
            .font(.title.weight(.semibold))
            .foregroundColor(.white)
            
            SwipeAction(
                systemImage: "square.and.arrow.up",
                backgroundColor: Color.green
            ) {
                context.state.wrappedValue = .closed
                let url = URL(string: getShareLink(id: keyData.key.id))
                let av = UIActivityViewController(activityItems: [url!], applicationActivities: nil)
                
                UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    av.popoverPresentationController?.sourceView = UIApplication.shared.windows.first
                    av.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2.1, y: UIScreen.main.bounds.height / 1.3, width: 200, height: 200)
                }
                
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

struct CentrePopup_DeleteKey: CentrePopup {
    @ObservedObject var viewModel: AccessViewModel
    
    
    func createContent() -> some View {
        ZStack {
            VStack {
                Text("Delete Key: \(viewModel.keyToDelete.1 ?? "0")")
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
                                self.viewModel.keyToDelete = (nil,nil)
                            }
                        }
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: viewModel.loading, title: "Delete", color: .red) {
                        withAnimation {
                            self.viewModel.loading = true
                        }
                        Task {
                            if self.viewModel.keyToDelete.0 != nil && self.viewModel.keyToDelete.1 != nil {
                                switch await self.viewModel.deleteKey(key: self.viewModel.keyToDelete.0 ?? "") {
                                case .success(_):
                                    withAnimation {
                                        withAnimation {
                                            self.viewModel.loading = false
                                            self.viewModel.getKeys()
                                        }
                                        //self.viewModel.showAlert = false
                                        dismiss()
                                        self.viewModel.keyToDelete = (nil,nil)
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
