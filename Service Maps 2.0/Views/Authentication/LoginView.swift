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
import PopupView


struct LoginView: View {
    var onDone: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: LoginViewModel
    @State private var restartAnimation = false
    @State private var animationProgress: CGFloat = 0.0
    @FocusState private var emailFocus: Bool
    @FocusState private var passwordFocus: Bool
    @State var loading = false
    @State var alwaysLoading = true
    @StateObject var synchronizationManager = SynchronizationManager.shared
    let authenticationManager = AuthenticationManager()
    
    init(onDone: @escaping() -> Void) {
        let initialViewModel = LoginViewModel(username: "", password: "")
        _viewModel = StateObject(wrappedValue: initialViewModel)
        
        self.onDone = onDone
    }
    
    
    
    var body: some View {
        ZStack {
            NavigationView {
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
                        .frame(width: 400, height: 400)
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
                                case .failure(_):
                                    viewModel.resetFeedbackText = "Error. Check your internet connection."
                                    viewModel.resetFeedback = true
                                }
                            }
                        } label: {
                            Text("Forgot Password")
                                .bold()
                        }
                    }
                    
                   
                    Spacer()
                    
                    HStack {
                        if synchronizationManager.startupState != .Login {
                            if !loading {
                                CustomBackButton() { dismiss() }
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
                                                    dismiss()
                                                }
                                                withAnimation { loading = false }
                                            case .failure(_):
                                                withAnimation { loading = false }
                                                dismiss()
                                            }
                                        }
                                    }
                                } else {
                                    withAnimation { viewModel.loginError = true }
                                    withAnimation { loading = false }
                                }
                            
                            //withAnimation { loading = false }
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
                .padding()
                .alert(isPresented: $viewModel.showAlert) {
                    Alert(title: Text(viewModel.alertTitle), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
                }
                .popup(isPresented: $viewModel.resetFeedback) {
                    
                    HStack {
                        VStack {
                            HStack {
                                Text(viewModel.resetFeedbackText)
                                    .lineLimit(2)
                                    .bold()
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                    .imageScale(.large)
                                
                            }
                            .frame(width: 300, height: 32)
                        }
                        .padding()
                    }
                    .background(Color(UIColor.systemGray4).cornerRadius(15))
                    .padding(16)
                    .shadowedStyle()
                    
                    .padding(.horizontal, 16)
                } customize: {
                    $0
                        .type(.floater())
                        .animation(.spring())
                        .closeOnTapOutside(true)
                        .position(.bottom)
                        .dragToDismiss(true)
                    //.backgroundColor(.black.opacity(0.5))
                    
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
