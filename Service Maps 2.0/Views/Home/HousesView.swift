//
//  HousesView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/28/23.
//

import SwiftUI
import ScalingHeaderScrollView
import SwipeActions

struct HousesView: View {
    var territory: Territory
    
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: HousesViewModel
    
    init(territory: Territory) {
        self.territory = territory
        let initialViewModel = HousesViewModel(territory: territory)
        _viewModel = StateObject(wrappedValue: initialViewModel)
    }
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Visit.date, ascending: false)],
        animation: .default)
    private var visits: FetchedResults<Visit>
    
    var body: some View {
        ZStack {
            ScalingHeaderScrollView() {
                ZStack {
                    Color(UIColor.secondarySystemBackground).ignoresSafeArea(.all)
                    viewModel.largeHeader(progress: viewModel.progress)
                }
            } content: {
                VStack {
                    VStack {
                        if viewModel.progress < 0.7 {
                            ZStack {
                                Color(UIColor.secondarySystemBackground).edgesIgnoringSafeArea(.horizontal)
                                VStack {
                                    viewModel.smallHeader
                                        .padding(.vertical)
                                }
                            }
                        }
                    }.animation(.default, value: viewModel.progress)
                    LazyVStack {
                        ForEach(viewModel.houses) { house in
                            SwipeView {
                                let filteredVisits = visits.filter { $0.house == house.id }
                                let latestVisit = filteredVisits.max {$0.date > $1.date }
                                
                                NavigationLink(destination: VisitsView(house: house)) {
                                    HouseCell(house: house, lastVisit: latestVisit)
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
                            .swipeOffsetCloseAnimation(stiffness: 160, damping: 70)
                            .swipeOffsetExpandAnimation(stiffness: 160, damping: 70)
                            .swipeOffsetTriggerAnimation(stiffness: 160, damping: 70)
                            .swipeMinimumDistance(40)
                        }
                    }
                    .padding(.horizontal)
                    .animation(.default, value: viewModel.houses)
                }
                
            }
            .height(min: 180, max: 350.0)
            .allowsHeaderGrowth()
            .allowsHeaderCollapse()
            .collapseProgress($viewModel.progress)
            
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
            Button("", action: { viewModel.optionsAnimation.toggle();  print("Info") })
            .buttonStyle(CircleButtonStyle(imageName: "ellipsis", background: .white.opacity(0), width: 40, height: 40, progress: $viewModel.progress, animation: $viewModel.optionsAnimation))
            )
    }
}

#Preview {
    TerritoryView()
        .environment(\.managedObjectContext, DataController.preview.container.viewContext)
}
