//
//  VerificationView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/3/23.
//

import SwiftUI
import ActivityIndicatorView
import NavigationTransitions

// MARK: - Verification View

struct VerificationView: View {
    // MARK: - OnDone
    
    var onDone: () -> Void
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Dependencies
    
    @ObservedObject private var viewModel: VerificationViewModel
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var universalLinksManager = UniversalLinksManager.shared
    
    // MARK: - Properties
    
    @State var loading = false
    @State var alwaysLoading = true
    @State private var restartAnimation = false
    @State private var animationProgress: CGFloat = 0
    
    // MARK: - Initializer
    
    init(onDone: @escaping() -> Void) {
        let initialViewModel = VerificationViewModel()
        _viewModel = ObservedObject(wrappedValue: initialViewModel)
        
        self.onDone = onDone
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Verification")
                    .frame(alignment:.leading)
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .multilineTextAlignment(.leading)
                    .hSpacing(.leading)
                    .padding(.bottom)
                    .padding(.horizontal, 5)
                
                Text("An email was sent to verify your account. When you have verified, click the button below to continue to your account.")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" || UIDevice.isSimulatorCompactPhone {
                    VStack {
                        LottieAnimationUIView(animationName: "VerificationAnimation", shouldLoop: false, shouldRestartAnimation: $restartAnimation, animationProgress: $animationProgress)
                            .frame(width: 150, height: 150)
                            .padding(.bottom, -50)
                    }
                } else {
                    VStack {
                        LottieAnimationUIView(animationName: "VerificationAnimation", shouldLoop: true, shouldRestartAnimation: $restartAnimation, animationProgress: $animationProgress)
                            .frame(width: 400, height: 400)
                    }
                }
                
                Spacer()
                
                VStack {
                    Button {
                        Task {
                            await viewModel.resendEmail() { result in
                                HapticManager.shared.trigger(.lightImpact)
                                switch result {
                                case .success(_):
                                    HapticManager.shared.trigger(.success)
                                    print("success sending verification email (VerificationView)")
                                case .failure(_):
                                    HapticManager.shared.trigger(.error)
                                    print("Error sending verification email (VerificationView)")
                                }
                            }
                        }
                    } label: {
                        Text("Resend Verification")
                            .bold()
                    }
                }
                
                Spacer()
                    .frame(height: 20)
                VStack {
                    HStack {
                        CustomBackButton() {
                            HapticManager.shared.trigger(.lightImpact)
                            synchronizationManager.startupState = .Welcome
                        }
                        CustomButton(loading: loading, title: "Already Verified") {
                            HapticManager.shared.trigger(.lightImpact)
                            withAnimation { loading = true }
                            Task {
                                await viewModel.checkVerification { result in
                                    switch result {
                                    case .success(_):
                                        HapticManager.shared.trigger(.success)
                                        DispatchQueue.main.async { onDone() }
                                        withAnimation { loading = false }
                                    case .failure(_):
                                        HapticManager.shared.trigger(.error)
                                        withAnimation { loading = false }
                                    }
                                }
                            }
                        }
                    }.padding()
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("\(viewModel.alertTitle)"), message: Text("\(viewModel.alertMessage)"), dismissButton: .default(Text("OK")))
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationTransition(
            .slide.combined(with: .fade(.in))
        )
    }
}

