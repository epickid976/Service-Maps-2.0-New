//
//  LoginView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/2/23.
//

import Foundation
import SwiftUI
import NavigationTransitions
import ActivityIndicatorView
import AlertKit


struct LoginView: View {
    var onDone: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject private var viewModel: LoginViewModel
    @State private var restartAnimation = false
    @State private var animationProgress: CGFloat = 0.0
    @FocusState private var emailFocus: Bool
    @FocusState private var passwordFocus: Bool
    @State var loading = false
    @State var alwaysLoading = true
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    let authenticationManager = AuthenticationManager()
    
    init(onDone: @escaping() -> Void) {
        let initialViewModel = LoginViewModel(username: "", password: "")
        _viewModel = ObservedObject(wrappedValue: initialViewModel)
        
        self.onDone = onDone
    }
    
    let alertViewAdded = AlertAppleMusic17View(title: "Password Reset Email Sent", subtitle: nil, icon: .done)
    
    var body: some View {
        ZStack {
            NavigationStack {
                LazyVStack {
                    Text("Login")
                        .frame(alignment:.leading)
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .multilineTextAlignment(.leading)
                        .hSpacing(.leading)
                        .padding([.leading, .trailing])
                        .padding(.bottom, -50)
                    
                    
                    LottieAnimationUIView(animationName: "LoginAnimation", shouldLoop: false, shouldRestartAnimation: $restartAnimation, animationProgress: $animationProgress)
                        .optionalViewModifier { content in
                            if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" {
                                content
                                    .frame(width: 250, height: 250)
                            } else {
                                content
                                    .frame(width: 400, height: 400)
                            }
                        }
                        .padding(.bottom, -50)
                    
                    Text("Email")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .hSpacing(.leading)
                        .padding(.leading)
                        .keyboardType(.emailAddress)
                    CustomField(text: $viewModel.username, isFocused: $emailFocus, textfield: true, placeholder: "example@example.com")
                    
                    Text("Password")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .hSpacing(.leading)
                        .padding(.leading)
                    CustomField(text: $viewModel.password, isFocused: $passwordFocus, textfield: false, placeholder: "****")
                    
                    Spacer()
                    
                    if viewModel.loginError {
                        Text(viewModel.loginErrorText)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Button {
                            Task {
                                let result = await authenticationManager.requestPasswordReset(email: viewModel.username)
                                
                                switch result {
                                case .success(_):
                                    viewModel.resetFeedbackText = "Request Successfully Sent"
                                    viewModel.resetFeedback = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        dismiss()
                                    }
                                case .failure(_):
                                    viewModel.resetFeedbackText = "Please type email above"
                                    viewModel.resetFeedback = true
                                }
                            }
                        } label: {
                            Text("Forgot Password")
                                .bold()
                        }
                    }
                    
                    
                    Spacer()
                    
                    HStack { //Don't show back button on reset password
                        if synchronizationManager.startupState != .Login {
                            if !loading {
                                CustomBackButton() { 
                                    dismiss()
                                    viewModel.username = ""
                                    viewModel.password = ""
                                }.keyboardShortcut("\r", modifiers: [.command, .shift])
                            }
                        }
                        CustomButton(loading: loading, title: "Login") {
                            withAnimation { loading = true }
                            let validation = viewModel.validate()
                            if validation {
                                Task {
                                    await viewModel.login() { result in
                                        switch result {
                                        case .success(_):
                                            DispatchQueue.main.async {
                                                onDone()
                                            }
                                            
                                            DispatchQueue.main.async{
                                                withAnimation { loading = false }
                                                dismiss()
                                            }
                                           
                                        case .failure(_):
                                            withAnimation { loading = false }
                                        }
                                    }
                                }
                            } else {
                                withAnimation { viewModel.loginError = true }
                                withAnimation { loading = false }
                            }
                            
                            //withAnimation { loading = false }
                        }.keyboardShortcut("\r", modifiers: .command)
                    }
                    .padding()
                    
                    Spacer()
                }
                .padding()
                .alert(isPresented: $viewModel.showAlert) {
                    Alert(title: Text(viewModel.alertTitle), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
                }
                .alert(isPresent: $viewModel.resetFeedback, view: alertViewAdded)
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
            
            .toolbar{
                ToolbarItemGroup(placement: .keyboard){
                    Spacer()
                    
                    Button("Done"){
                        DispatchQueue.main.async {
                            emailFocus = false
                            passwordFocus = false
                            hideKeyboard()
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
        }.ignoresSafeArea()
    }
}

#Preview {
    LoginView() {
        
    }
}

extension View {
    func shadowedStyle() -> some View {
        self
            .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 0)
            .shadow(color: .black.opacity(0.16), radius: 24, x: 0, y: 0)
    }
}
