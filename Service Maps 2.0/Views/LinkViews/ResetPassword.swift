//
//  ResetPassword.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/12/23.
//

import SwiftUI
import Lottie

struct ResetPassword: View {
    @State private var restartAnimation = false
    @State private var animationProgress: CGFloat = 0.0
    
    @ObservedObject var viewModel: LoginViewModel
    @ObservedObject var universalLinksManager = UniversalLinksManager.shared
    @ObservedObject var authenticationManager = AuthenticationManager()
    @ObservedObject var dataStore = StorageManager.shared
    
    init() {
        let initialViewModel = LoginViewModel(username: "", password: "")
        _viewModel = ObservedObject(wrappedValue: initialViewModel)
        
    }
    
    
    @FocusState private var passwordFocus: Bool
    @FocusState private var passwordConfirmationFocus: Bool
    
    @State var loading = false
    
    var body: some View {
        ZStack {
            NavigationView {
                LazyVStack {
                    Text("Reset Password")
                        .frame(alignment:.leading)
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .multilineTextAlignment(.leading)
                        .hSpacing(.leading)
                        .padding([.leading, .trailing])
                        .padding(.bottom, -50)
                    
                    
                    LottieAnimationUIView(animationName: "LoginAnimation", shouldLoop: false, shouldRestartAnimation: $restartAnimation, animationProgress: $animationProgress)
                        .frame(width: 400, height: 400)
                        .padding(.bottom, -50)
                    
                    Text("Password")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .hSpacing(.leading)
                        .padding(.leading)
                        .keyboardType(.emailAddress)
                    CustomField(text: $viewModel.username, isFocused: $passwordFocus, textfield: false, placeholder: "****")
                    
                    Text("Password Confirmation")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .hSpacing(.leading)
                        .padding(.leading)
                    CustomField(text: $viewModel.password, isFocused: $passwordConfirmationFocus, textfield: false, placeholder: "****")
                    
                    Spacer()
                    
                    if viewModel.loginError {
                        Text(viewModel.loginErrorText)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    HStack {
                        if !loading {
                            CustomBackButton(showImage: true, text: "Cancel") {
                                HapticManager.shared.trigger(.lightImpact)
                                withAnimation {
                                    universalLinksManager.resetLink()
                                }
                            }.hSpacing(.trailing)
                        }
                        CustomButton(loading: loading, alwaysExpanded: true, title: "Reset") {
                            HapticManager.shared.trigger(.lightImpact)
                            withAnimation { loading = true }
                            let validation = viewModel.validate(forReset: true)
                            if validation {
                                Task {
                                    withAnimation { self.viewModel.loading = true }
                                    await viewModel.resetPassword(password: viewModel.username, token: universalLinksManager.dataFromUrl ?? "" )
                                    //await authenticationManager.login(logInForm: LoginForm(email: dataStore.userEmail ?? "", password: dataStore.passTemp ?? ""))
                                }
                            } else {
                                HapticManager.shared.trigger(.error)
                                withAnimation { viewModel.loginError = true }
                                withAnimation { loading = false }
                            }
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
                .padding()
                .alert(isPresented: $viewModel.showAlert) {
                    Alert(title: Text(viewModel.alertTitle), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
                }
            }
            .simultaneousGesture(
                // Hide the keyboard on scroll
                DragGesture().onChanged { _ in
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
            )
            
            .navigationBarBackButtonHidden(true)
        }.ignoresSafeArea()
    }
}

