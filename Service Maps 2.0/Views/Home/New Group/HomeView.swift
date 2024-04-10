////
////  HomeView.swift
////  Service Maps 2.0
////
////  Created by Jose Blanco on 9/11/23.
////
//
//import SwiftUI
//import NukeUI
//import SwipeActions
//
//struct HomeView: View {
//    var territory: Territory
//    var safeArea: EdgeInsets
//    var size: CGSize
//    @StateObject var viewModel: HousesViewModel
//    
//    @State var showFab = true
//    @State var scrollOffset: CGFloat = 0.00
//    
//    init(territory: Territory, safeArea: EdgeInsets, size: CGSize, viewModel: HousesViewModel) {
//        self.territory = territory
//        self.safeArea = safeArea
//        self.size = size
//        let initialViewModel = HousesViewModel(territory: territory)
//        _viewModel = StateObject(wrappedValue: initialViewModel)
//    }
//    
//    var body: some View {
//        ScrollView(.vertical, showsIndicators: false) {
//            LazyVStack {
//                //Mark: Image
//                ArtWork()
//                
//                GeometryReader { proxy in
//                    HStack(spacing: 12.0) {
//                        HStack {
//                            Image(systemName: "numbersign").imageScale(.large).fontWeight(.heavy)
//                                .foregroundColor(.primary).font(.title2)
//                            Text("\(territory.number)")
//                                .font(.largeTitle)
//                                .bold()
//                                .fontWeight(.heavy)
//                        }
//                        
//                        Divider()
//                            .frame(maxHeight: 75)
//                            .padding(.horizontal, -5)
//                        
//                        LazyImage(url: URL(string: territory.image ?? "https://www.google.com/url?sa=i&url=https%3A%2F%2Flottiefiles.com%2Fanimations%2Fno-data-bt8EDsKmcr&psig=AOvVaw2p2xZlutsRFWRoLRsg6LJ2&ust=1712619221457000&source=images&cd=vfe&opi=89978449&ved=0CBEQjRxqFwoTCPjeiPihsYUDFQAAAAAdAAAAABAE")) { state in
//                            if let image = state.image {
//                                image.resizable().aspectRatio(contentMode: .fill).frame(maxWidth: 75, maxHeight: 60)
//                            } else if state.error != nil {
//                                Color.red
//                            } else {
//                                ProgressView().progressViewStyle(.circular)
//                            }
//                        }
//                        .cornerRadius(10)
//                        .padding(.horizontal, 2)
//                        Text(territory.territoryDescription ?? "")
//                            .font(.body)
//                            .fontWeight(.heavy)
//                    }
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .padding(.horizontal)
//                }
//                .frame(height: 75)
//                
//                HousesListView()
//            }
//            
//        }
//    }
//    
//    @ViewBuilder
//    func ArtWork() -> some View {
//        let height = size.height * 0.45
//        GeometryReader { proxy in
//            let size = proxy.size
//            
//            LazyImage(url: URL(string: territory.image ?? "https://www.google.com/url?sa=i&url=https%3A%2F%2Flottiefiles.com%2Fanimations%2Fno-data-bt8EDsKmcr&psig=AOvVaw2p2xZlutsRFWRoLRsg6LJ2&ust=1712619221457000&source=images&cd=vfe&opi=89978449&ved=0CBEQjRxqFwoTCPjeiPihsYUDFQAAAAAdAAAAABAE")) { state in
//                if let image = state.image {
//                    image
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                        .frame(width: size.width, height: size.height)
//                        .clipped()
//                    //image.opacity(1 - progress)
//                    
//                } else if state.error != nil {
//                    Color.red
//                        .aspectRatio(contentMode: .fill)
//                        .frame(width: size.width, height: size.height)
//                        .clipped()
//                } else {
//                    ProgressView().progressViewStyle(.circular)
//                        .aspectRatio(contentMode: .fill)
//                        .frame(width: size.width, height: size.height)
//                        .clipped()
//                }
//            }
//        }
//        .frame(height: height + safeArea.top)
//    }
//    
//    @ViewBuilder
//    func HousesListView() -> some View {
//        LazyVStack {
//            LazyVStack {
//                ForEach(viewModel.housesList) { house in
//                    SwipeView {
//                        NavigationLink(destination: VisitsView(house: house)) {
//                            HouseCell(house: house, lastVisit: nil)
//                                .padding(.bottom, 2)
//                        }
//                    } trailingActions: { context in
//                        SwipeAction(
//                            systemImage: "trash",
//                            backgroundColor: .red
//                        ) {
//                            viewModel.deleteHouse(house: house)
//                        }
//                        .font(.title.weight(.semibold))
//                        .foregroundColor(.white)
//                        
//                        SwipeAction(
//                            systemImage: "pencil",
//                            backgroundColor: Color.teal
//                        ) {
//                            context.state.wrappedValue = .closed
//                            viewModel.currentHouse = house
//                            viewModel.presentSheet = true
//                        }
//                        .allowSwipeToTrigger()
//                        .font(.title.weight(.semibold))
//                        .foregroundColor(.white)
//                    }
//                    .swipeActionCornerRadius(16)
//                    .swipeSpacing(5)
//                    .swipeOffsetCloseAnimation(stiffness: 160, damping: 70)
//                    .swipeOffsetExpandAnimation(stiffness: 160, damping: 70)
//                    .swipeOffsetTriggerAnimation(stiffness: 160, damping: 70)
//                    .swipeMinimumDistance(40)
//                }
//            }
//            .padding(.horizontal)
//            .animation(.default, value: viewModel.housesList)
//        }
//        .padding(.bottom)
//    }
//}
//
//#Preview {
//    TerritoryView()
//        .environment(\.managedObjectContext, DataController.preview.container.viewContext)
//}
