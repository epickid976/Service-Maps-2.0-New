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
    
    var body: some View {
        
        ZStack {
            VStack {
                Spacer()
                Spacer()
                Spacer()
                ActivityIndicatorView(isVisible: $loading, type: .growingArc(.primary, lineWidth: 1.0))
                    .frame(width: 50, height: 50)
                Text("Loading")
                    .bold()
                    .font(.title3)
                    .padding()
                
                
                LottieAnimationUIView(animationName: "LoadingAnimation", shouldLoop: true, shouldRestartAnimation: $restartAnimation)
                    .frame(width: 350, height: 350)
                    .padding(.top, -100)
                Spacer()
            }
        }
        
    }
}

#Preview {
    LoadingView()
}
