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
    
    var body: some View {
        ZStack {
            ScrollView {
                    VStack {
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
                                            viewModel.territoryCell(dataWithKeys: dataWithKeys)
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
                    .animation(.easeInOut(duration: 0.25), value: viewModel.territoryData == nil)
                    .alert(isPresent: $viewModel.showToast, view: alertViewDeleted)
                    .alert(isPresent: $viewModel.showAddedToast, view: alertViewAdded)
                    .popup(isPresented: $viewModel.showAlert) {
                        if viewModel.territoryToDelete.0 != nil && viewModel.territoryToDelete.1 != nil {
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
                .navigationDestination(isPresented: $viewModel.presentSheet) {
                    AddTerritoryView(territory: viewModel.currentTerritory) {
                        synchronizationManager.startupProcess(synchronizing: true)
                        DispatchQueue.main.async {
                            viewModel.showAddedToast = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            viewModel.showAddedToast = false
                        }
                    }
                }
                
                //.scrollIndicators(.hidden)
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
                    MainButton(imageName: "plus", colorHex: "#00b2f6", width: 60) {
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
