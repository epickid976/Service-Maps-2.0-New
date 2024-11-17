//
//  SignupView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/2/23.
//

import Foundation
import SwiftUI
import Alamofire
import NavigationTransitions
import Combine

struct SignupView: View {
    
    //ENVIRONMENT
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject private var viewModel: SignupViewModel
    
    @State private var restartAnimation = false
    @State private var animationProgress: CGFloat = 0
    @State var alwaysLoading = true
    @State var loading = false
    //Focus
    @FocusState private var firstNameFocus: Bool
    @FocusState private var lastNameFocus: Bool
    @FocusState private var emailFocus: Bool
    @FocusState private var passwordFocus: Bool
    @FocusState private var confirmPasswordFocus: Bool
    
    
    init() {
        let initialViewModel = SignupViewModel()
        _viewModel = ObservedObject(wrappedValue: initialViewModel)
    }
    var body: some View {
        NavigationStack {
                LazyVStack {
                    Text("Sign up")
                        .frame(alignment:.leading)
                        .font( .largeTitle)
                        .fontWeight(.black)
                        .multilineTextAlignment(.leading)
                        .hSpacing(.leading)
                        .padding([.leading, .trailing])
                        //.padding(.bottom, -50)
                    if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" || UIDevice.isSimulatorCompactPhone {
//                        LottieAnimationUIView(animationName: "LoginAnimation", shouldLoop: false, shouldRestartAnimation: $restartAnimation, animationProgress: $animationProgress)
//                            .frame(minWidth: 100, maxWidth: 200, minHeight: 100, maxHeight: 200)
//                           .padding(.vertical, -30)
                    } else {
                        LottieAnimationUIView(animationName: "LoginAnimation", shouldLoop: false, shouldRestartAnimation: $restartAnimation, animationProgress: $animationProgress)
                            .frame(minWidth: 100, maxWidth: 200, minHeight: 100, maxHeight: 200)
                           .padding(.vertical, -30)
                    }
                    
                    Text("First Name")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(alignment: .leading)
                        .hSpacing(.leading)
                        .padding(.leading)
                    
                    CustomField(text: $viewModel.name, isFocused: $firstNameFocus, textfield: true, keyboardContentType: .givenName, placeholder: NSLocalizedString("first name", comment: ""))
                    
                    Text("Last Name")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(alignment: .leading)
                        .hSpacing(.leading)
                        .padding(.leading)
                    
                    CustomField(text: $viewModel.lastName, isFocused: $lastNameFocus, textfield: true, keyboardContentType: .familyName,  placeholder: NSLocalizedString("last name", comment: "") )
                    
                    
                    Text("Email")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .hSpacing(.leading)
                        .padding(.leading)
                    CustomField(text: $viewModel.username, isFocused: $emailFocus, textfield: true, keyboardType: .emailAddress , keyboardContentType: .emailAddress, diableCapitalization: true, placeholder: "example@example.com")
                    
                    
                    Text("Password")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .hSpacing(.leading)
                        .padding(.leading)
                    CustomField(text: $viewModel.password, isFocused: $passwordFocus, textfield: false, keyboardContentType: .newPassword, placeholder: "****")
                    
                    Text("Confirm Password")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .hSpacing(.leading)
                        .padding(.leading)
                    CustomField(text: $viewModel.passwordConfirmation, isFocused: $confirmPasswordFocus, textfield: false, keyboardContentType: .newPassword, placeholder: "****")
                    
                    if viewModel.loginError {
                        Spacer()
                        Text(viewModel.loginErrorText)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            
                    }
                    Spacer()
                    HStack {
                        if !loading {
                            CustomBackButton() {
                                HapticManager.shared.trigger(.lightImpact)
                                dismiss()
                                viewModel.name = ""
                                viewModel.lastName = ""
                                viewModel.username = ""
                                viewModel.password = ""
                                viewModel.passwordConfirmation = ""
                                viewModel.loginError = false
                            }//.keyboardShortcut("\r", modifiers: [.command, .shift])
                        }
                        
                        CustomButton(loading: loading, title: "Sign up") {
                            HapticManager.shared.trigger(.lightImpact)
                            withAnimation { loading = true }
                            let validation = viewModel.validate()
                            
                            if validation {
                                Task {
                                    await viewModel.signUp() { result in
                                        switch result {
                                        case .success(_):
                                            HapticManager.shared.trigger(.success)
                                            withAnimation { loading = false }
                                            SynchronizationManager.shared.back_from_verification = false
                                                SynchronizationManager.shared.startupProcess(synchronizing: true)
                                            DispatchQueue.main.async { dismiss() }
                                        case .failure(_):  withAnimation { loading = false }
                                            HapticManager.shared.trigger(.error)
                                        }
                                    }
                                }
                            } else {
                                HapticManager.shared.trigger(.error)
                                withAnimation { viewModel.loginError = true }
                                withAnimation { loading = false }
                            }
                        }//.keyboardShortcut("\r", modifiers: .command)
                    }
                    .padding([.horizontal, .top])
                }
                .modifier(KeyboardAdaptive(active: passwordFocus || confirmPasswordFocus))
                .alert(isPresented: $viewModel.showAlert) {
                    Alert(title: Text("\(viewModel.alertTitle)"), message: Text("\(viewModel.alertMessage)"), dismissButton: .default(Text("OK")))
                }
                .onChange(of: viewModel.loginError) { newValue in
                    if newValue {
                        hideKeyboard()
                    }
                }
                .padding()
                .navigationBarBackButtonHidden(true)
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

struct KeyboardAdaptive: ViewModifier {
    @ObservedObject private var keyboard = KeyboardResponder()
    var active = false
    func body(content: Content) -> some View {
        content
            .padding(.bottom, active && UIDevice().userInterfaceIdiom == .phone ? keyboard.currentHeight - 140 : 0)
            .animation(.easeOut(duration: 0.16))
    }
}

final class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0

    var keyboardWillShowNotification = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
    var keyboardWillHideNotification = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
    
    init() {
        keyboardWillShowNotification.map { notification in
            CGFloat((notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0)
        }
        .assign(to: \.currentHeight, on: self)
        .store(in: &cancellableSet)

        keyboardWillHideNotification.map { _ in
            CGFloat(0)
        }
        .assign(to: \.currentHeight, on: self)
        .store(in: &cancellableSet)
    }

    private var cancellableSet: Set<AnyCancellable> = []
}
