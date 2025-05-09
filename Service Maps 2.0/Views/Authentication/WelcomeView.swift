//
//  LoginView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/2/23.
//

import SwiftUI
import NavigationTransitions

// MARK: - Welcome View

struct WelcomeView: View {
    // MARK: - OnDone
    
    var onDone: () -> Void
    
    // MARK: - Initializer
    
    init(onDone: @escaping () -> Void) {
        self.onDone = onDone
        
    }
    
    // MARK: - Environment
    
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Dependencies
    
    @StateObject var synchronizationManager = SynchronizationManager.shared
    
    // MARK: - Properties
    
    @State private var restartAnimation = false
    @State private var animationProgress: CGFloat = 0
    
    // MARK: - Body
    
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
                if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" || UIDevice.isSimulatorCompactPhone {
                    LottieAnimationUIView(animationName: "WelcomeAnimation", shouldLoop: false, shouldRestartAnimation: $restartAnimation, animationProgress: $animationProgress)
                        .frame(width: 150, height: 150)
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
                
                NavigationLink(destination: LoginDefaultScreen(onDone: onDone)) {
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

// MARK: - Preview

#Preview {
    WelcomeView() {
        
    }
}
