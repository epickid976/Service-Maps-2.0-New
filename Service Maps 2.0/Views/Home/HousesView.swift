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
    var territory: Territory
    
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: HousesViewModel
    
    @State var showFab = true
    @State var scrollOffset: CGFloat = 0.00
    
    init(territory: Territory) {
        self.territory = territory
        let initialViewModel = HousesViewModel(territory: territory)
        _viewModel = StateObject(wrappedValue: initialViewModel)
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
                    ForEach(viewModel.housesList) { house in
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
                .animation(.default, value: viewModel.housesList)
                
            }
            .height(min: 180, max: 350.0)
            //.allowsHeaderCollapse()
            .allowsHeaderGrowth()
            //.headerIsClipped()
            //.scrollOffset($scrollOffset)
            .collapseProgress($viewModel.progress)
            .scrollIndicators(.hidden)
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden()
        .navigationBarTitle("Houses", displayMode: .inline)
        .navigationBarItems(leading: Button("", action: {withAnimation { viewModel.backAnimation.toggle() };
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                dismiss()
            }
        })
            .buttonStyle(CircleButtonStyle(imageName: "arrow.backward", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.backAnimation))
                            , trailing:
                                HStack {
            Button("", action: { viewModel.optionsAnimation.toggle();  print("Info") })
                .buttonStyle(CircleButtonStyle(imageName: "ellipsis", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.optionsAnimation))
            Button("", action: { viewModel.optionsAnimation.toggle();  print("Add") ; DispatchQueue.main.async { viewModel.presentSheet.toggle() }})
                .buttonStyle(CircleButtonStyle(imageName: "plus", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.optionsAnimation))
        }
        )
        .navigationTransition(viewModel.presentSheet ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
        .navigationDestination(isPresented: $viewModel.presentSheet) {
            AddHouseView(house: viewModel.currentHouse)
        }
    }
    
    
}

#Preview {
    TerritoryView()
        .environment(\.managedObjectContext, DataController.preview.container.viewContext)
}
