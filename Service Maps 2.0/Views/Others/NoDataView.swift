//
//  NoDataView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/8/23.
//

import SwiftUI
import NavigationTransitions
import MijickPopups

struct NoDataView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var restartAnimation = false
    @State private var animationProgress: CGFloat = 0
    @State var loading = false
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    @State var goToAdminLogin = false
    @State var goToPhoneLogin = false
    
    @Environment(\.sizeCategory) var sizeCategory
    
    @State var backAnimation = false
    @State var progress: CGFloat = 0.0
    
    var body: some View {
            NavigationStack {
                VStack {
                    Text("No Data")
                        .frame(alignment:.leading)
                        .font(sizeCategory == .large || sizeCategory == .extraLarge ? .largeTitle : .title2)
                        .fontWeight(.black)
                        .multilineTextAlignment(.leading)
                        .hSpacing(.leading)
                        .padding(.bottom)
                        .padding(.horizontal, 5)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("You successfully logged in, but it seems like you do not have access to any territories. Contact your group leader for access and then click refresh. If you are an administrator, click the button below.")
                        .font(sizeCategory == .large || sizeCategory == .extraLarge ? .headline : .system(size: 17))
                        .fontWeight(.bold)
                    //.padding(.bottom, -50)
                    
                    if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" || UIDevice.isSimulatorCompactPhone{
                        LottieAnimationUIView(animationName: "NoDataAnimation", shouldLoop: true, shouldRestartAnimation: $restartAnimation, animationProgress: $animationProgress)
                            .frame(width: 300, height: 250)
                        //.padding(.bottom, -50)
                    } else {
                        LottieAnimationUIView(animationName: "NoDataAnimation", shouldLoop: true, shouldRestartAnimation: $restartAnimation, animationProgress: $animationProgress)
                            .frame(width: 400, height: 300)
                        //.padding(.bottom, -50)
                    }
                    
                    Spacer()
                    VStack(spacing: 20) {
                        CustomButton(loading: loading, title: "Reload") {
                            withAnimation { loading = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                Task {
                                    synchronizationManager.startupProcess(synchronizing: true)
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        Task {
                            synchronizationManager.startupProcess(synchronizing: true)
                        }
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        NavigationLink(destination: NavigationLazyView(SettingsView(showBackButton: true))) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 20))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }//.keyboardShortcut(.delete, modifiers: .command)
                        
                    }
                }
            }
        .navigationTransition(
            .slide.combined(with: .fade(.in))
        )
        .navigationViewStyle(StackNavigationViewStyle())
        
    }
}

#Preview {
    NoDataView()
}
