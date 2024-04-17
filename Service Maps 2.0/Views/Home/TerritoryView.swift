//
//  Territory View.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/4/23.
//

import SwiftUI
import CoreData
import NavigationTransitions
import SwipeActions
import Combine
import UIKit


struct TerritoryView: View {
    
    @ObservedObject var viewModel = TerritoryViewModel()
    
    //@Environment(\.managedObjectContext) private var viewContext
 
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    @State var showFab = true
    @State var scrollOffset: CGFloat = 0.00
    @State private var isScrollingDown = false
    
    init() {

    }
    
    var body: some View {
            ScrollView {
                ZStack {
                    LazyVStack {
                        
                        if !viewModel.territoryData.moderatorData.isEmpty {
                            Text("Moderator Territories")
                                .font(.title2)
                                .fontWeight(.heavy)
                                .foregroundColor(.primary)
                                .hSpacing(.leading).padding(.leading)
                            SwipeViewGroup {
                                ForEach(viewModel.territoryData.moderatorData, id: \.self) { territoryData in
                                    viewModel.territoryCell(territoryData: territoryData)
                                }
                                .animation(.default, value: viewModel.territoryData.moderatorData)
                            }
                        }
                        
                        if !viewModel.territoryData.userData.isEmpty {
                            if !viewModel.territoryData.moderatorData.isEmpty {
                                Text("Other Territories")
                                    .font(.title2)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.primary)
                                    .hSpacing(.leading).padding(.leading)
                            }
                            SwipeViewGroup {
                                ForEach(viewModel.territoryData.userData, id: \.self) { territoryData in
                                    viewModel.territoryCell(territoryData: territoryData)
                                }
                                .animation(.default, value: viewModel.territoryData.userData)
                            }
                        }
                        
                        if viewModel.territoryData.moderatorData.isEmpty && viewModel.territoryData.userData.isEmpty {
                            //TODO SET LOTTIE ANIMATION NO DATA
                        }
                    }
                    .navigationDestination(isPresented: $viewModel.presentSheet) {
                        AddTerritoryView(territory: viewModel.currentTerritory)
                    }
                    .padding()
                }
            }
                .scrollIndicators(.hidden)
                .navigationBarTitle("Territories", displayMode: .automatic)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        HStack {
//                            Button(action: { viewModel.isAscending.toggle() }) {
//                                Image(systemName: viewModel.isAscending ? "arrow.up" : "arrow.down").animation(.spring)
//                            }
                            Button("", action: { viewModel.optionsAnimation.toggle();  print("Add") ; viewModel.presentSheet.toggle() })
                                .buttonStyle(CircleButtonStyle(imageName: "plus", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.optionsAnimation))
                        }
                    }
                }
        .navigationTransition(viewModel.presentSheet ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
}

//#Preview {
//    TerritoryView()
//        .environment(\.managedObjectContext, DataController.preview.container.viewContext)
//}

