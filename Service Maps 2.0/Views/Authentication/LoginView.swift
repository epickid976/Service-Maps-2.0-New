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
import UIKit

// MARK: - LoginDefaultScreen

struct LoginDefaultScreen: View {
    
    // MARK: - OnDone
    
    var onDone: () -> Void
    
    // MARK: - Environment
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) private var presentationMode
    
    // MARK: - Dependencies
    
    @StateObject var universalLinksManager = UniversalLinksManager.shared
    @ObservedObject private var viewModel: LoginViewModel
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    let authenticationManager = AuthenticationManager()
    
    // MARK: - Properties
    
    @State private var restartAnimation = false
    @State private var animationProgress: CGFloat = 0.0
    @FocusState private var emailFocus: Bool
    @FocusState private var passwordFocus: Bool
    @State var loading = false
    @State var alwaysLoading = true
    
    // MARK: - Initializer
    
    init(onDone: @escaping() -> Void) {
        let initialViewModel = LoginViewModel(username: "", password: "")
        _viewModel = ObservedObject(wrappedValue: initialViewModel)
        
        self.onDone = onDone
    }
    
    // MARK: - Alert Views
    let alertViewAdded = AlertAppleMusic17View(title: "Password Reset Email Sent", subtitle: nil, icon: .done)
    let alertViewError = AlertAppleMusic17View(title: "Please type email above", subtitle: nil, icon: .error)
    let alertEmailSent = AlertAppleMusic17View(title: "Login Email Sent", subtitle: nil, icon: .done)
    let errorEmailSent = AlertAppleMusic17View(title: "Error sending email", subtitle: nil, icon: .error)
    
    // MARK: - Body
    
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
                    
                    
                    LottieAnimationUIView(animationName: "lock", shouldLoop: false, shouldRestartAnimation: $restartAnimation, animationProgress: $animationProgress)
                        .optionalViewModifier { content in
                            if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" || UIDevice.isSimulatorCompactPhone {
                                content
                                    .frame(width: 300, height: 300)
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
                    CustomField(text: $viewModel.username, isFocused: $emailFocus, textfield: true, keyboardType: .emailAddress , keyboardContentType: .oneTimeCode, diableCapitalization: true, placeholder: "example@example.com")
                    
                    Spacer()
                    
                    if viewModel.loginError {
                        Text(viewModel.loginErrorText)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Button {
                            viewModel.goToLoginView = true
                        } label: {
                            Text("Use Password")
                                .bold()
                        }
                    }
                    
                    
                    Spacer()
                    
                    HStack { //Don't show back button on reset password
                        if synchronizationManager.startupState != .Login {
                            if !viewModel.loading {
                                CustomBackButton() {
                                    HapticManager.shared.trigger(.lightImpact)
                                    presentationMode.wrappedValue.dismiss()
                                    viewModel.username = ""
                                    viewModel.password = ""
                                }//.keyboardShortcut("\r", modifiers: [.command, .shift])
                            }
                        }
                        CustomButton(loading: viewModel.loading, title: "Login") {
                            HapticManager.shared.trigger(.lightImpact)
                                Task {
                                    hideKeyboard()
                                    await viewModel.sendLoginEmail()
                                }
                        }//.keyboardShortcut("\r", modifiers: .command)
                    }
                    .padding()
                    
                    Spacer()
                }
                .padding()
                .alert(isPresented: $viewModel.showAlert) {
                    Alert(title: Text(viewModel.alertTitle), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
                }
                .alert(isPresent: $viewModel.resetFeedback, view: alertViewAdded)
                .alert(isPresent: $viewModel.resetError, view: alertViewError)
                .alert(isPresent: $viewModel.emailSent, view: alertEmailSent)
                .alert(isPresent: $viewModel.errorEmailSent, view: errorEmailSent)
            }.navigationDestination(isPresented: $viewModel.goToLoginView, destination: {
                LoginView(onDone: {
                    viewModel.goToLoginView = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    
                    self.onDone()
                    
                })
            })
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
        }.ignoresSafeArea().onChange(of: universalLinksManager.determineDestination()) { value in
            if value == .ResetPasswordView || value == .loginWithEmailView {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// MARK: - LoginView

struct LoginView: View {
    
    // MARK: - OnDone
    
    var onDone: () -> Void
    
    // MARK: - Environment
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Dependencies
    
    @ObservedObject private var viewModel: LoginViewModel
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    let authenticationManager = AuthenticationManager()
    
    // MARK: - Properties
    
    @State private var restartAnimation = false
    @State private var animationProgress: CGFloat = 0.0
    @FocusState private var emailFocus: Bool
    @FocusState private var passwordFocus: Bool
    @State var loading = false
    @State var alwaysLoading = true
   
    // MARK: - Initializer
    
    init(onDone: @escaping() -> Void) {
        let initialViewModel = LoginViewModel(username: "", password: "")
        _viewModel = ObservedObject(wrappedValue: initialViewModel)
        
        self.onDone = onDone
    }
    
    // MARK: - Alert Views
    
    let alertViewAdded = AlertAppleMusic17View(title: "Password Reset Email Sent", subtitle: nil, icon: .done)
    let alertViewError = AlertAppleMusic17View(title: "Please type email above", subtitle: nil, icon: .error)
    
    // MARK: - Body
    
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
                            if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" || UIDevice.isSimulatorCompactPhone {
                                content
                                    .frame(width: 300, height: 300)
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
                    CustomField(text: $viewModel.username, isFocused: $emailFocus, textfield: true, keyboardType: .emailAddress , keyboardContentType: .oneTimeCode, diableCapitalization: true, placeholder: "example@example.com")
                    
                    Text("Password")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .hSpacing(.leading)
                        .padding(.leading)
                    CustomField(text: $viewModel.password, isFocused: $passwordFocus, textfield: false, keyboardContentType: .newPassword, placeholder: "****")
                    
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
                                case .success:
                                    viewModel.resetFeedbackText = "Request Successfully Sent"
                                    viewModel.resetFeedback = true
                                    HapticManager.shared.trigger(.success)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                case .failure(_):
                                    viewModel.resetFeedbackText = "Please type email above"
                                    HapticManager.shared.trigger(.error)
                                    viewModel.resetError = true
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
                                    HapticManager.shared.trigger(.lightImpact)
                                    presentationMode.wrappedValue.dismiss()
                                    viewModel.username = ""
                                    viewModel.password = ""
                                }//.keyboardShortcut("\r", modifiers: [.command, .shift])
                            }
                        }
                        CustomButton(loading: loading, title: "Login") {
                            withAnimation { loading = true }
                            HapticManager.shared.trigger(.lightImpact)

                            let validation = viewModel.validate()
                            if validation {
                                Task {
                                    let result = await viewModel.login()

                                    DispatchQueue.main.async {
                                        switch result {
                                        case .success:
                                            HapticManager.shared.trigger(.success)
                                            onDone()
                                            
                                        case .failure(_):
                                            HapticManager.shared.trigger(.error)
                                            viewModel.loginError = true
                                        }
                                        
                                        withAnimation { loading = false }
                                    }
                                }
                            } else {
                                HapticManager.shared.trigger(.error)
                                withAnimation {
                                    viewModel.loginError = true
                                    loading = false
                                }
                            }
                        }//.keyboardShortcut("\r", modifiers: .command)
                    }
                    .padding()
                    
                    Spacer()
                }
                .padding()
                .alert(isPresented: $viewModel.showAlert) {
                    Alert(title: Text(viewModel.alertTitle), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
                }
                .alert(isPresent: $viewModel.resetFeedback, view: alertViewAdded)
                .alert(isPresent: $viewModel.resetError, view: alertViewError)
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

// MARK: - Preview

#Preview {
    LoginView() {
        
    }
}
