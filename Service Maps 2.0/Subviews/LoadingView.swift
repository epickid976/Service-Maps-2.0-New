//
//  LoginView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/3/23.
//

import SwiftUI
import ActivityIndicatorView
import NavigationTransitions

struct LoadingView: View {
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var storageManager = StorageManager.shared
    @State var loading = true
    @State private var restartAnimation = false
    @State private var animationProgress: CGFloat = 0
    @State var text = ""
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    LottieAnimationUIView(animationName: "LoadingAnimation", shouldLoop: true, shouldRestartAnimation: $restartAnimation, animationProgress: $animationProgress)
                        .frame(width: 350, height: 350)
                        
                    Text("Loading")
                        .bold()
                        .font(.title3)
                        .padding(.top, -80)
                        .onTapGesture {
                            text = "\(storageManager.synchronized) time: \(Date())"
                        }
                    
                    Text(text)
                        .bold()
                        .font(.title3)
                        //.padding(.top, -80)
                }
            }
        }
        .navigationTransition(
            .fade(.in)
        )
        .onChange(of: storageManager.synchronized) { newValue in
            if newValue {
                SynchronizationManager.shared.startupProcess(synchronizing: false)
            }
        }
    }
}

#Preview {
    LoadingView()
}
