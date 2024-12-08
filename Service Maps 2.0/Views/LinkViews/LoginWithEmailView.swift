//
//  LoginWithEmailView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/9/24.
//

import Foundation
import SwiftUI
import Lottie
import NavigationTransitions

//MARK: - LoginWithEmailView

struct LoginWithEmailView: View {
    
    //MARK: - Dependencies
    
    @StateObject var viewModel: LoginViewModel
    
    //MARK: - Init
    
    init() {
        _viewModel = StateObject(wrappedValue: LoginViewModel(username: "", password: ""))
        
    }
    
    //MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" {
                    LottieView(animation: .named("LoadingAnimation"))
                        .playing()
                        .resizable()
                        .looping()
                        .frame(width: 250, height: 250)
                } else {
                    LottieView(animation: .named("LoadingAnimation"))
                        .playing()
                        .resizable()
                        .looping()
                        .frame(width: 350, height: 350)
                }
                
                Text(viewModel.loginError ? "Error logging in..." : "Logging in...")
                    .bold()
                    .font(.title3)
                
                Spacer()
                Spacer()
                
                Text("\(viewModel.loginErrorText)")
                    .bold()
                    .font(.title3)
                    .foregroundStyle(.red)
                
                HStack {
                    
                    CustomBackButton(showImage: true, text: "Cancel") {
                        HapticManager.shared.trigger(.lightImpact)
                        withAnimation {
                            UniversalLinksManager.shared.resetLink()
                        }
                    }.hSpacing(.trailing)
                    CustomButton(loading: viewModel.loading, alwaysExpanded: true, title: "Retry", action: {
                        HapticManager.shared.trigger(.lightImpact)
                        withAnimation { self.viewModel.loading = true }
                        Task {
                            await self.viewModel.loginWithEmail(token: UniversalLinksManager.shared.dataFromUrl ?? "")
                        }
                    })
                    .hSpacing(.trailing)
                    //.frame(width: 100)
                }
            }
        }
        .navigationBarTitle("Activating Account", displayMode: .automatic)
        .navigationBarBackButtonHidden(true)
        .navigationTransition(.zoom.combined(with: .fade(.in)))
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            HapticManager.shared.trigger(.impact)
            Task {
                viewModel.loading = true
                await self.viewModel.loginWithEmail(token: UniversalLinksManager.shared.dataFromUrl ?? "")
                SynchronizationManager.shared.startupProcess(synchronizing: false)
            }
        }
    }
}
