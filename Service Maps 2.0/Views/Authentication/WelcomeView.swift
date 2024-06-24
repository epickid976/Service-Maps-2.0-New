//
//  LoginView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/2/23.
//

import SwiftUI
import NavigationTransitions

struct WelcomeView: View {
    var onDone: () -> Void
    
    init(onDone: @escaping () -> Void) {
        self.onDone = onDone
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var restartAnimation = false
    @State private var animationProgress: CGFloat = 0
    @StateObject var synchronizationManager = SynchronizationManager.shared
    
    var body: some View {
        NavigationStack {
            LazyVStack {
                
                Text("Welcome to \nService Maps!")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .multilineTextAlignment(.center)
                Text("Everything at the palm of your hand")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                    .frame(height: 30)
                if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" {
                    LottieAnimationUIView(animationName: "WelcomeAnimation", shouldLoop: false, shouldRestartAnimation: $restartAnimation, animationProgress: $animationProgress)
                        .frame(width: 250, height: 250)
                } else {
                    LottieAnimationUIView(animationName: "WelcomeAnimation", shouldLoop: false, shouldRestartAnimation: $restartAnimation, animationProgress: $animationProgress)
                        .frame(width: 350, height: 350)
                }
                Spacer()
                    .frame(height: 70)
                
                NavigationLink(destination: SignupView()) {
                    VStack {
                        Text("Sign Up")
                            .fontWeight(.heavy)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding()
                        
                    }
                    .frame(maxWidth: .infinity) // Apply the frame to the wrapping view
                    .background(
                        Capsule()
                            .stroke(Color.gray, lineWidth: 2)
                    )
                }.onTapHaptic(.lightImpact)
                
                .buttonStyle(.automatic)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .tint(colorScheme == .dark ? .black : .white)
                //.keyboardShortcut("s", modifiers: .command)
                //.padding([.bottom])
                
                NavigationLink(destination: LoginView(onDone: onDone)) {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.heavy)
                    
                }.onTapHaptic(.lightImpact)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                //.keyboardShortcut("l", modifiers: .command)
                
                
            }
            .padding()
            .navigationBarBackButtonHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationTransition(
            .slide.combined(with: .fade(.in))
        )
    }
}

#Preview {
    WelcomeView() {
        
    }
}
