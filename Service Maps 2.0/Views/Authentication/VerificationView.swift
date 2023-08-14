//
//  VerificationView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/3/23.
//

import SwiftUI
import ActivityIndicatorView

struct VerificationView: View {
    var onDone: () -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: VerificationViewModel
    @State var loading = false
    @State var alwaysLoading = true
    @State private var restartAnimation = false
    @State private var animationProgress: CGFloat = 0
    @StateObject var synchronizationManager = SynchronizationManager.shared
    
    init(onDone: @escaping() -> Void) {
        let initialViewModel = VerificationViewModel()
        _viewModel = StateObject(wrappedValue: initialViewModel)
        
        self.onDone = onDone
    }
    
    var body: some View {
        NavigationStack {
            LazyVStack {
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
                
                if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" {
                    VStack {
                        LottieAnimationUIView(animationName: "VerificationAnimation", shouldLoop: false, shouldRestartAnimation: $restartAnimation, animationProgress: $animationProgress)
                            .frame(width: 200, height: 200)
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
                                switch result {
                                case .success(_):
                                    print("success sending verification email (VerificationView)")
                                case .failure(_):
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
                    CustomButton(loading: loading, title: "Already Verified") {
                        withAnimation { loading = true }
                        Task {
                            await viewModel.checkVerification { result in
                                switch result {
                                case .success(_):
                                    DispatchQueue.main.async { onDone() }
                                    withAnimation { loading = false }
                                case .failure(_):
                                    withAnimation { loading = false }
                                }
                            }
                        }
                    }
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("\(viewModel.alertTitle)"), message: Text("\(viewModel.alertMessage)"), dismissButton: .default(Text("OK")))
            }
            .padding()
            
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    VerificationView() {
        
    }
}
