//
//  SignupView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/2/23.
//

import Foundation
import SwiftUI
import Alamofire
import ActivityIndicatorView
import NavigationTransitions

struct SignupView: View {
    
    //ENVIRONMENT
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: SignupViewModel
    
    @State private var restartAnimation = false
    @State private var animationProgress: CGFloat = 0
    @State var alwaysLoading = true
    @State var loading = false
    //Focus
    @FocusState private var nameFocus: Bool
    @FocusState private var emailFocus: Bool
    @FocusState private var passwordFocus: Bool
    @FocusState private var confirmPasswordFocus: Bool
    
    
    init() {
        let initialViewModel = SignupViewModel()
        _viewModel = StateObject(wrappedValue: initialViewModel)
    }
    var body: some View {
        NavigationStack {
            LazyVStack {
                
                Text("Sign up")
                    .frame(alignment:.leading)
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .multilineTextAlignment(.leading)
                    .hSpacing(.leading)
                    .padding([.leading, .trailing])
                    .padding(.bottom, -50)
                
                
                if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" {
                    LottieAnimationUIView(animationName: "LoginAnimation", shouldLoop: false, shouldRestartAnimation: $restartAnimation, animationProgress: $animationProgress)
                        .frame(width: 200, height: 200)
                        .padding(.bottom, -50)
                } else {
                    LottieAnimationUIView(animationName: "LoginAnimation", shouldLoop: false, shouldRestartAnimation: $restartAnimation, animationProgress: $animationProgress)
                        .frame(width: 300, height: 300)
                        .padding(.bottom, -50)
                }
                
                Text("Name")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(alignment: .leading)
                    .hSpacing(.leading)
                    .padding(.leading)
                
                CustomField(text: $viewModel.name, isFocused: $nameFocus, textfield: true, placeholder: "name")
                
                
                Text("Email")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .hSpacing(.leading)
                    .padding(.leading)
                CustomField(text: $viewModel.username, isFocused: $emailFocus, textfield: true, placeholder: "example@example.com")
                
                
                Text("Password")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .hSpacing(.leading)
                    .padding(.leading)
                CustomField(text: $viewModel.password, isFocused: $passwordFocus, textfield: false, placeholder: "****")
                
                Text("Confirm Password")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .hSpacing(.leading)
                    .padding(.leading)
                CustomField(text: $viewModel.passwordConfirmation, isFocused: $confirmPasswordFocus, textfield: false, placeholder: "****")
                Spacer()
                if viewModel.loginError {
                    Text(viewModel.loginErrorText)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                Spacer()
                HStack {
                    if !loading {
                        CustomBackButton() {
                            dismiss()
                            viewModel.name = ""
                            viewModel.username = ""
                            viewModel.password = ""
                            viewModel.passwordConfirmation = ""
                        }
                    }
                    
                    CustomButton(loading: loading, title: "Sign up") {
                        withAnimation { loading = true }
                        let validation = viewModel.validate()
                        
                        if validation {
                            Task {
                                await viewModel.signUp() { result in
                                    switch result {
                                    case .success(_):
                                        withAnimation { loading = false }
                                        SynchronizationManager.shared.startupProcess(synchronizing: false)
                                        DispatchQueue.main.async { dismiss() }
                                    case .failure(_):  withAnimation { loading = false }
                                    }
                                }
                            }
                        } else {
                            withAnimation { viewModel.loginError = true }
                            withAnimation { loading = false }
                        }
                    }
                }
                .padding()
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("\(viewModel.alertTitle)"), message: Text("\(viewModel.alertMessage)"), dismissButton: .default(Text("OK")))
            }
            .padding()
            .navigationBarBackButtonHidden(true)
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
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationTransition(
            .slide.combined(with: .fade(.in))
        )
        .toolbar{
            ToolbarItemGroup(placement: .keyboard){
                Spacer()
                Button("Done"){
                    DispatchQueue.main.async {
                        nameFocus = false
                        emailFocus = false
                        confirmPasswordFocus = false
                        passwordFocus = false
                        hideKeyboard()
                    }
                }
            }
        }
    }
}


#Preview {
    SignupView()
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
