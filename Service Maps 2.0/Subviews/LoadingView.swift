//
//  LoginView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/3/23.
//

import SwiftUI
import ActivityIndicatorView

struct LoadingView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State var loading = true
    
    @State private var restartAnimation = false
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        
        ZStack {
            VStack {
                LottieAnimationUIView(animationName: "LoadingAnimation", shouldLoop: true, shouldRestartAnimation: $restartAnimation, animationProgress: $animationProgress)
                    .frame(width: 350, height: 350)
                Text("Loading")
                    .bold()
                    .font(.title3)
                    .padding(.top, -80)
            }
        }
        
    }
}

#Preview {
    LoadingView()
}
