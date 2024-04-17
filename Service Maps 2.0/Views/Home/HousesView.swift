//
//  HousesView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/28/23.
//

import SwiftUI
import NukeUI
import SwipeActions
import ScalingHeaderScrollView
import NavigationTransitions

struct HousesView: View {
    var territory: TerritoryModel
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: HousesViewModel
    
    @State var showFab = true
    @State var scrollOffset: CGFloat = 0.00
    
    init(territory: TerritoryModel) {
        self.territory = territory
        let initialViewModel = HousesViewModel(territory: territory)
        _viewModel = ObservedObject(wrappedValue: initialViewModel)
    }
    
    var body: some View {
        ZStack {
            ScalingHeaderScrollView {
                ZStack {
                    Color(UIColor.secondarySystemBackground).ignoresSafeArea(.all)
                    viewModel.largeHeader(progress: viewModel.progress)
                    
                    
                }
            } content: {
                LazyVStack {
                    ForEach(viewModel.houses) { house in
                        SwipeView {
                            NavigationLink(destination: VisitsView(house: house)) {
                                HouseCell(house: house, lastVisit: nil)
                                    .padding(.bottom, 2)
                            }
                            
                        } trailingActions: { context in
                            SwipeAction(
                                systemImage: "trash",
                                backgroundColor: .red
                            ) {
                                viewModel.deleteHouse(house: house)
                            }
                            .font(.title.weight(.semibold))
                            .foregroundColor(.white)
                            
                            SwipeAction(
                                systemImage: "pencil",
                                backgroundColor: Color.teal
                            ) {
                                context.state.wrappedValue = .closed
                                viewModel.currentHouse = house
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
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom)
                .animation(.default, value: viewModel.houses)
                
            }
            .height(min: 180, max: 350.0)
            //.allowsHeaderCollapse()
            .allowsHeaderGrowth()
            //.headerIsClipped()
            //.scrollOffset($scrollOffset)
            .collapseProgress($viewModel.progress)
            .scrollIndicators(.hidden)
            .navigationDestination(isPresented: $viewModel.presentSheet) {
                AddHouseView(house: viewModel.currentHouse)
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden()
        .navigationBarTitle("Houses", displayMode: .inline)
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
//                    Button(action: { viewModel.presentSheet.toggle() }) {
//                        Image(systemName: "plus").animation(.spring)
//                    }
                    Button("", action: { viewModel.optionsAnimation.toggle();  print("Add") ; viewModel.presentSheet.toggle() })
                        .buttonStyle(CircleButtonStyle(imageName: "plus", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.optionsAnimation))
                }
            }
        }
        .navigationTransition(viewModel.presentSheet ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
        
    }
    
    
}


