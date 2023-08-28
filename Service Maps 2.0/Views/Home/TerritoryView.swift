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
    
    @StateObject var viewModel: TerritoryViewModel
    
    init() {
        let initialViewModel = TerritoryViewModel()
        _viewModel = StateObject(wrappedValue: initialViewModel)
    }
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Territory.number, ascending: true)],
        animation: .default)
    private var territories: FetchedResults<Territory>
    
    @StateObject var synchronizationManager = SynchronizationManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    SwipeViewGroup {
                        ForEach(territories, id: \.id) { territory in
                            SwipeView {
                                CellView(territory: territory, isAscending: $viewModel.isAscending)
                                    .padding(.bottom, 2)
                            } trailingActions: { context in
                                SwipeAction(
                                    systemImage: "trash",
                                    backgroundColor: .red
                                ) {
                                    
                                }
                                .font(.title.weight(.semibold))
                                .foregroundColor(.white)
                                
                                SwipeAction(
                                    systemImage: "pencil",
                                    backgroundColor: Color.teal
                                ) {
                                    context.state.wrappedValue = .closed
                                    viewModel.currentTerritory = territory
                                    viewModel.presentSheet = true
                                }
                                .allowSwipeToTrigger()
                                .font(.title.weight(.semibold))
                                .foregroundColor(.white)
                            }
                            .swipeActionCornerRadius(16)
                            .swipeSpacing(5)
                            .swipeOffsetCloseAnimation(stiffness: 160, damping: 70)
                            .swipeOffsetExpandAnimation(stiffness: 160, damping: 70)
                            .swipeOffsetTriggerAnimation(stiffness: 160, damping: 70)
                            .swipeMinimumDistance(20)
                        }
                    }
                }
                .padding()
                
            }
            .sheet(isPresented: $viewModel.presentSheet) {
                AddTerritoryView(territory: viewModel.currentTerritory)
                            .presentationDetents([.large])
                            .presentationDragIndicator(.visible)
                            .optionalViewModifier { contentView in
                                if #available(iOS 16.4, *) {
                                    contentView
                                    .presentationCornerRadius(25)
                                } else {
                                    // Fallback on earlier versions
                                }
                            }
                
            
                    }
            .toolbar{
                ToolbarItemGroup(placement: .keyboard){
                    Spacer()
                    Button {
                        DispatchQueue.main.async {
                            hideKeyboard()
                        }
                    } label: {
                        Text("Done")
                            .tint(.primary)
                            .fontWeight(.bold)
                            .font(.body)
                    }
                }
            }
            .navigationBarTitle("Territories", displayMode: .automatic)
            .navigationBarBackButtonHidden(true)
            .font(.title)
            .bold()
            .navigationBarItems(trailing: Button(action: {
                // Toggle the sorting order when the button is tapped
                //withAnimation(.spring(duration: 1.0)) {
                    viewModel.isAscending.toggle()
                //}
            }) {
                Image(systemName: viewModel.isAscending ? "arrow.up" : "arrow.down").animation(.spring)
            })
        }
        .navigationTransition(
            .slide.combined(with: .fade(.in))
        )
        .onChange(of: viewModel.isAscending) { newValue in
            DispatchQueue.main.async {
                territories.nsSortDescriptors = viewModel.sortDescriptors
            }
        }
    }
}

#Preview {
    TerritoryView()
        .environment(\.managedObjectContext, DataController.preview.container.viewContext)
}
