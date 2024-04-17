//
//  AccessView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/7/23.
//

import SwiftUI
import SwipeActions
import NavigationTransitions

struct AccessView: View {
    @ObservedObject var viewModel = AccessViewModel()
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var databaseManager = RealmManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ZStack {
                    LazyVStack {
                        ForEach(databaseManager.tokensFlow) { token in
                            SwipeView {
                                TokenCell(token: token)
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
                                    viewModel.currentToken = token
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
                            //.padding(.bottom)
                        }
                    }
                    .padding()
                    
                }
                
            }
                .scrollIndicators(.hidden)
                .navigationBarTitle("Keys", displayMode: .automatic)
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
        
            
        }
        .navigationTransition(viewModel.presentSheet ? .zoom.combined(with: .fade(.in)) : .slide.combined(with: .fade(.in)))
        //.navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    AccessView()
}
