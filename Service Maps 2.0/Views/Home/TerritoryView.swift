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


struct TerritoryView: View {
    
    @ObservedObject var viewModel = TerritoryViewModel()
    
    @Environment(\.managedObjectContext) private var viewContext
 
    @StateObject var synchronizationManager = SynchronizationManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    
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
//                .onAppear {
//                    Task {
//                        viewModel.cdPublisher.getTerritories()
//                    }
//                }
            }
            .navigationBarTitle("Territories", displayMode: .automatic)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    HStack {
                        Button(action: { viewModel.isAscending.toggle() }) {
                            Image(systemName: viewModel.isAscending ? "arrow.up" : "arrow.down").animation(.spring)
                        }
                        if viewModel.isAdmin {
                            Button(action: { viewModel.presentSheet = true }) {
                                Image(systemName: "plus" )
                            }
                        }
                    }
                }
            }
            
            
        }
        .navigationTransition(
            viewModel.presentSheet ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in))
        )
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    
}

#Preview {
    TerritoryView()
        .environment(\.managedObjectContext, DataController.preview.container.viewContext)
}

