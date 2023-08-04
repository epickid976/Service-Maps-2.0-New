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

struct LoginView: View {
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
    
    @State var loading = false
    @State var alwaysLoading = true
    
    @State private var restartAnimation = false
    @State private var animationProgress: CGFloat = 0
    
    @State var goToHomeView = false
    
    //MARK: API
    let authenticationApi = AuthenticationAPI()
    
    @State private var username: String = "joseblanco0430906@icloud.com"
    @State private var password: String = "Jjjj"
    
    @State private var usernameError = ""
    @State private var passwordError = ""
    
    @FocusState private var emailFocus: Bool
    @FocusState private var passwordFocus: Bool
    var body: some View {
        
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
                    .frame(width: 400, height: 400)
                    .padding(.bottom, -50)
                
                //Spacer()
                
                Text("Email")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .hSpacing(.leading)
                    .padding(.leading)
                    .keyboardType(.emailAddress)
                TextField("example@example.com", text: $username, onEditingChanged: { isEditing in
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
                SecureField("****", text: $password)
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
                    
                    Button {
                        if !username.isEmpty && !password.isEmpty {
                            Task {
                                do {
                                    withAnimation {
                                        loading = true
                                    }
                                    let response = try await authenticationApi.login(email: username, password: password)
                                    print(response.access_token)
                                    print(response.expires_at)
                                    print(response.token_type)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        withAnimation {
                                            
                                            loading = false
                                            goToHomeView = true
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
                                    } else if error.asAFError?.responseCode == 401 {
                                        alertTitle = "Wrong Credentials"
                                        alertMessage = "The credentials you typed don't seem to be correct.\nPlease try again."
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
                    } label: {
                        if loading {
                            ActivityIndicatorView(isVisible: $alwaysLoading, type: .growingArc(.primary, lineWidth: 1.0))
                                .frame(width: 25, height: 25)
                        } else {
                            Text("Login")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.heavy)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    //.padding([.bottom])
                    
                    
                }
                .padding()
                NavigationLink(destination: HomeTabView(), isActive: $goToHomeView) {
                    EmptyView()
                }
                
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
                        emailFocus = false
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
}

#Preview {
    LoginView()
}
