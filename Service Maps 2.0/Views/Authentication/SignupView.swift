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

struct SignupView: View {
    //ENVIRONMENT
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var restartAnimation = false
    
    @State var loading = false
    @State private var apiError = ""
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
                    LottieAnimationUIView(animationName: "LoginAnimation", shouldLoop: false, shouldRestartAnimation: $restartAnimation)
                        .frame(width: 200, height: 200)
                        .padding(.bottom, -50)
                } else {
                    LottieAnimationUIView(animationName: "LoginAnimation", shouldLoop: false, shouldRestartAnimation: $restartAnimation)
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
                    
                    
                    Button(action: {
                        Task {
                            do {
                                loading = true
                                let response = try await authenticationApi.signUp(name: name, email: username, password: password)
                                
                                loading = false
                                temporaryEmail = username
                                temporaryPassword = password
                                goToVerificationView = true
                                
                            } catch {
                                // Handle any errors here
                                print(error.asAFError?.responseCode)
                                print(error.asAFError?.errorDescription)
                                print(error.asAFError?.failureReason)
                                print(error.asAFError?.url)
                                print(error.localizedDescription)
                                apiError = "Error Signing up"
                                loading = false
                            }
                        }
                    }) {
                        Text("Sign up")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.heavy)
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
            
            .padding()
            .navigationBarBackButtonHidden(true)
            .fullScreenCover(isPresented: $loading, content: LoadingView.init)
            
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
