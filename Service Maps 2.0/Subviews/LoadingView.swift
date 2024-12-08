//
//  LoginView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/3/23.
//

import SwiftUI
import ActivityIndicatorView
import NavigationTransitions
import Lottie

//MARK: - Loading View
struct LoadingView: View {
    //MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
    //MARK: - Dependencies
    @ObservedObject var storageManager = StorageManager.shared
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
    //MARK: - Properties
    @State var loading = true
    @State private var restartAnimation = false
    @State private var animationProgress: CGFloat = 0
    @State var text = ""
   
    //MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    LottieView(animation: .named("LoadingAnimation"))
                        .playing(loopMode: .loop)
                        .resizable()
                        .frame(width: 350, height: 350)
                    
                    Text("Loading")
                        .bold()
                        .font(.title3)
                        .padding(.top, -80)
                    
                    Text(text)
                        .bold()
                        .font(.title3)
                    //.padding(.top, -80)
                }
            }
        }
        .navigationTransition( .fade(.in))
        .onChange(of: storageManager.synchronized) { newValue in
            if newValue { Task { SynchronizationManager.shared.startupProcess(synchronizing: false) } }
        }
    }
}

#Preview {
    LoadingView()
}
