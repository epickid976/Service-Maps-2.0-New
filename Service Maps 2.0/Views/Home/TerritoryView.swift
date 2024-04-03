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
    
    @StateObject var viewModel = TerritoryViewModel()
    
    @Environment(\.managedObjectContext) private var viewContext
 
    @StateObject var synchronizationManager = SynchronizationManager.shared
    
    @State var showFab = true
    @State var scrollOffset: CGFloat = 0.00
    @State private var isScrollingDown = false
    
    
    var body: some View {
        NavigationStack {
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
                    .background(GeometryReader {
                        return Color.clear.preference(key: ViewOffsetKey.self,
                                                      value: -$0.frame(in: .named("scroll")).origin.y)
                    })
                    .navigationDestination(isPresented: $viewModel.presentSheet) {
                        AddTerritoryView(territory: viewModel.currentTerritory)
                    }
                    .padding()
                }
            }.coordinateSpace(name: "scroll")
                    .overlay(
                        showFab && viewModel.isAdmin ?
                        viewModel.createFab()
                        : nil
                        , alignment: Alignment.bottomTrailing)
                    .onPreferenceChange(ViewOffsetKey.self) { offset in
                        withAnimation {
                            showFab = offset <= 50 || (offset < scrollOffset && !isScrollingDown)
                        }
                        scrollOffset = offset

                        // Track scroll direction accurately:
                        isScrollingDown = offset > scrollOffset && scrollOffset > 0
                    }
                .scrollIndicators(.hidden)
                .navigationBarTitle("Territories", displayMode: .automatic)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        HStack {
                            Button(action: { viewModel.isAscending.toggle() }) {
                                Image(systemName: viewModel.isAscending ? "arrow.up" : "arrow.down").animation(.spring)
                            }
                        }
                    }
                }
        
            
        }
        .navigationTransition(viewModel.presentSheet ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

#Preview {
    TerritoryView()
        .environment(\.managedObjectContext, DataController.preview.container.viewContext)
}

