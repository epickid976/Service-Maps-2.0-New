//
//  VisitsView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/5/23.
//
import SwiftUI
import CoreData
import NavigationTransitions
import SwipeActions
import Combine
import UIKit


struct VisitsView: View {
    
    @StateObject var viewModel: VisitsViewModel
    var house: House
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject var synchronizationManager = SynchronizationManager.shared
    
    @State var showFab = true
    @State var scrollOffset: CGFloat = 0.00
    @State private var isScrollingDown = false
    
    init(house: House) {
        self.house = house
        let initialViewModel = VisitsViewModel(house: house)
        _viewModel = StateObject(wrappedValue: initialViewModel)
    }
    
    var body: some View {
            ScrollView {
                ZStack {
                    LazyVStack {
                        ForEach(viewModel.visitsList) { visit in
                            SwipeView {
                                VisitCell(visit: visit)
                                        .padding(.bottom, 2)
                            } trailingActions: { context in
                                SwipeAction(
                                    systemImage: "trash",
                                    backgroundColor: .red
                                ) {
                                    //TODO DELETION LOGIC
                                }
                                .font(.title.weight(.semibold))
                                .foregroundColor(.white)
                                
                                SwipeAction(
                                    systemImage: "pencil",
                                    backgroundColor: Color.teal
                                ) {
                                    context.state.wrappedValue = .closed
                                    viewModel.currentVisit = visit
                                    viewModel.presentSheet = true
                                }
                                .allowSwipeToTrigger()
                                .font(.title.weight(.semibold))
                                .foregroundColor(.white)
                            }
                            .swipeActionCornerRadius(16)
                            .swipeSpacing(5)
                            .swipeOffsetCloseAnimation(stiffness: 1000, damping: 70)
                            .swipeOffsetExpandAnimation(stiffness: 1000, damping: 70)
                            .swipeOffsetTriggerAnimation(stiffness: 1000, damping: 70)
                            .swipeMinimumDistance(40)
                            .navigationDestination(isPresented: $viewModel.presentSheet) {
                                AddVisitView()
                            }
                            //.padding(.bottom, -55)
                        }
                    }
                    .padding()
                    
                }
                
            }
                .scrollIndicators(.hidden)
                .navigationBarTitle("House: \(house.number ?? "ERROR_NO_HOUSE")", displayMode: .automatic)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarLeading) {
                        HStack {
                            Button("", action: {withAnimation { viewModel.backAnimation.toggle() };
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    dismiss()
                                }
                            })
                                .buttonStyle(CircleButtonStyle(imageName: "arrow.backward", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.backAnimation))
                        }
                    }
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
        //.navigationViewStyle(StackNavigationViewStyle())
    }
    
}

#Preview {
    TerritoryView()
        .environment(\.managedObjectContext, DataController.preview.container.viewContext)
}


//#Preview {
//    VisitsView()
//}
