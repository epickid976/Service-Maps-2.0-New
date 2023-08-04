//
//  SignupView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/2/23.
//

import Foundation
import SwiftUI
import NavigationTransitions
import Alamofire
import ActivityIndicatorView

struct SignupView: View {
    //ENVIRONMENT
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAlert = false {
        didSet {
            if !showAlert {
                alertTitle = ""
                alertMessage = ""
            }
        }
    }
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    @State private var restartAnimation = false
    @State private var animationProgress: CGFloat = 0
    
    @State var loading = false
    @State var alwaysLoading = true
    
    @State var goToVerificationView = false
    
    @AppStorage("temporaryEmail") var temporaryEmail = ""
    @AppStorage("temporaryPassword") var temporaryPassword = ""
    
    
    //MARK: API
    let authenticationApi = AuthenticationAPI()
    
    //Textfields
    @State private var name: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var passwordConfirmation: String = ""
    
    //Textfield Errors
    @State private var usernameError = ""
    @State private var passwordError = ""
    
    //Focus
    @FocusState private var nameFocus: Bool
    @FocusState private var emailFocus: Bool
    @FocusState private var passwordFocus: Bool
    @FocusState private var confirmPasswordFocus: Bool
    
    var body: some View {
        NavigationStack {
            LazyVStack {
                HStack {
                    Text("Sign up")
                        .frame(alignment:.leading)
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
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
                
                TextField("Name", text: $name)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .font(.system(size: 16, weight: .regular))
                    .accentColor(.blue)
                    .focused($nameFocus)
                    .gesture(TapGesture().onEnded {
                        // Handle tap action
                        nameFocus = true
                    })
                
                Text("Email")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .hSpacing(.leading)
                    .padding(.leading)
                
                TextField("Email", text: $username, onEditingChanged: { isEditing in
                    if !isEditing {
                        validateUsername()
                    }
                })
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)
                .font(.system(size: 16, weight: .regular))
                .accentColor(.blue)
                .keyboardType(.emailAddress)
                .focused($emailFocus)
                .gesture(TapGesture().onEnded {
                    // Handle tap action
                    emailFocus = true
                })
                
                Text("Password")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .hSpacing(.leading)
                    .padding(.leading)
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .font(.system(size: 16, weight: .regular))
                    .accentColor(.blue)
                    .focused($passwordFocus)
                    .gesture(TapGesture().onEnded {
                        // Handle tap action
                        passwordFocus = true
                    })
                Text("Confirm Password")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .hSpacing(.leading)
                    .padding(.leading)
                SecureField("Password Confirmation", text: $passwordConfirmation)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .font(.system(size: 16, weight: .regular))
                    .accentColor(.blue)
                    .focused($confirmPasswordFocus)
                    .gesture(TapGesture().onEnded {
                        // Handle tap action
                        confirmPasswordFocus = true
                    })
                if !usernameError.isEmpty {
                    Text(usernameError)
                        .foregroundColor(.red)
                        .font(.system(size: 15, weight: .regular))
                        .padding()
                }
                
                if !passwordError.isEmpty {
                    Text(passwordError)
                        .foregroundColor(.red)
                        .font(.system(size: 15, weight: .regular))
                        .padding()
                }
                
                
                HStack {
                    if !loading {
                        Button {
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "chevron.backward")
                                //.frame(maxWidth: .infinity)
                                    .fontWeight(.heavy)
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                                Text("Back")
                                //.frame(maxWidth: .infinity)
                                    .fontWeight(.heavy)
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .controlSize(.large)
                        .tint(colorScheme == .dark ? .black : .white)
                        .overlay(
                            Capsule()
                                .stroke(Color.gray, lineWidth: 2)
                        )
                        //.padding([.top])
                    }
                    
                    Button(action: {
                        if !username.isEmpty && !name.isEmpty && !password.isEmpty && !passwordConfirmation.isEmpty {
                        Task {
                            do {
                                withAnimation {
                                    loading = true
                                }
                                let response = try await authenticationApi.signUp(name: name, email: username, password: password)
                                
                                
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    withAnimation {
                                        loading = false
                                        temporaryEmail = username
                                        temporaryPassword = password
                                        goToVerificationView = true
                                    }
                                }
                           
                                
                            } catch {
                                // Handle any errors here
                                print(error.asAFError?.responseCode)
                                print(error.asAFError?.errorDescription)
                                print(error.asAFError?.failureReason)
                                print(error.asAFError?.url)
                                print(error.localizedDescription)
                                if error.asAFError?.responseCode == -1009 || error.asAFError?.responseCode == nil {
                                    alertTitle = "No Internet Connection"
                                    alertMessage = "There was a problem with the internet connection. \nPlease check your internect connection and try again."
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        withAnimation {
                                            //apiError = "Error Signing up"
                                            loading = false
                                            showAlert = true
                                        }
                                    }
                                } else if error.asAFError?.responseCode == 422 {
                                    alertTitle = "Email Taken"
                                    alertMessage = "It seems like you already signed up with this email.\n Please log in instead."
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        withAnimation {
                                            //apiError = "Error Signing up"
                                            loading = false
                                            showAlert = true
                                        }
                                    }
                                } else {
                                    alertTitle = "Error"
                                    alertMessage = "Error logging in. \nPlease try again."
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        withAnimation {
                                            //apiError = "Error Signing up"
                                            loading = false
                                            showAlert = true
                                        }
                                    }
                                }
                                
                                
                            }
                            
                        }
                        } else {
                            withAnimation {
                                usernameError = "Fields cannot be empty"
                            }
                        }
                    }) {
                        if loading {
                            ActivityIndicatorView(isVisible: $alwaysLoading, type: .growingArc(.primary, lineWidth: 1.0))
                                .frame(width: 25, height: 25)
                        } else {
                            Text("Sign up")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.heavy)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    
                    
                    NavigationLink(destination: VerificationView(), isActive: $goToVerificationView) {
                        EmptyView()
                    }
                    
                    //.padding([.bottom])
                }
                .padding()
            }
            .alert(isPresented: $showAlert) {
                        Alert(title: Text("\(alertTitle)"), message: Text("\(alertMessage)"), dismissButton: .default(Text("OK")))
                    }
            .padding()
            .navigationBarBackButtonHidden(true)
//            .fullScreenCover(isPresented: $loading, content: LoadingView.init)
            
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
    
    func validateUsername() {
        if username.contains(" ") {
            usernameError = "Email cannot contain spaces"
        } else {
            usernameError = ""
        }
    }
    
    func validatePassword(password: String, passwordConfirmation: String) {
        if password == passwordConfirmation {
            passwordError = ""
        } else {
            passwordError = "Passwords do not match"
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
