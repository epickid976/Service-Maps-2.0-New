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

struct AdminLoginView: View {
    var onDone: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var synchronizationManager = SynchronizationManager.shared
    
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
    
    
    //MARK: API
    let congregationApi = CongregationAPI()
    
    
    @State private var username: String = ""
    @State private var password: String = ""
    
    @State private var usernameError = ""
    @State private var passwordError = ""
    
    @FocusState private var emailFocus: Bool
    @FocusState private var passwordFocus: Bool
    
    @State private var restartAnimation = false
    @State private var animationProgress: CGFloat = 0
    
    @State var loginErrorText = ""
    @State var loginError = false
    
    var body: some View {
        
        NavigationStack {
            LazyVStack {
                
                Text("Congregation \nLogin")
                    .frame(alignment:.leading)
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .multilineTextAlignment(.leading)
                    .hSpacing(.leading)
                    .padding([.leading, .trailing])
                    .padding(.bottom, -50)
                
                if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" {
                    LottieAnimationUIView(animationName: "CongregationLogin", shouldLoop: true, shouldRestartAnimation: $restartAnimation, animationProgress: $animationProgress)
                        .frame(width: 200, height: 200)
                        .padding(50)
                } else {
                    LottieAnimationUIView(animationName: "CongregationLogin", shouldLoop: true, shouldRestartAnimation: $restartAnimation, animationProgress: $animationProgress)
                        .frame(width: 250, height: 250)
                        .padding(50)
                }
                
                
                //Spacer()
                
                Text("Congregation ID")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .hSpacing(.leading)
                    .padding(.leading)
                    .keyboardType(.emailAddress)
                TextField("ID", text: $username)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)
                .font(.system(size: 16, weight: .regular))
                .accentColor(.blue)
                .focused($emailFocus)
                .keyboardType(.numberPad)
                .gesture(TapGesture().onEnded {
                    // Handle tap action
                    emailFocus = true
                })
                Text("Congregation Password")
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
                
                HStack {
                    if synchronizationManager.startupState != .AdminLogin {
                        if !loading {
                            CustomBackButton() { dismiss() }
                        }
                    }
                    
                    Button {
                        let validation = validate()
                        if validation {
                            Task {
                                do {
                                    withAnimation {
                                        loading = true
                                    }
                                    
                                    _ = try await congregationApi.signIn(congregationId: Int64(username) ?? 0, congregationPass: password)
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        withAnimation {
                                            loading = false
                                            AuthorizationProvider.shared.congregationId = Int64(username)
                                            AuthorizationProvider.shared.congregationPass = password
                                            
                                        }
                                    }
                                } catch {
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
                                        alertMessage = "The credentials you typed don't seem to be correct.\n Please try again."
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                            withAnimation {
                                                //apiError = "Error Signing up"
                                                loading = false
                                                showAlert = true
                                            }
                                        }
                                    } else if error.asAFError?.responseCode == 404 {
                                        alertTitle = "Wrong Congregation"
                                        alertMessage = "The congregation you're trying to access does not exist. \n Please try again."
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
                                loginError = true
                            }
                            withAnimation { loading = false }
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
                
            }
            .padding()
           
        }
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
        //.animation(.spring(duration: 1.0), value: synchronizationManager.startupState)
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationTransition(.slide.combined(with: .fade(.in)))
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
    
    func validate() -> Bool {
        
        if self.username.isEmpty || self.password.isEmpty  {
            DispatchQueue.main.async {
                withAnimation {
                    self.loginErrorText = "Fields cannot be empty"
                    self.loginError = true
                }
            }
            return false
        }
        
        if self.username.contains(" ") {
            DispatchQueue.main.async {
                withAnimation {
                    self.loginErrorText = "ID cannot contain spaces."
                    self.loginError = true
                }
            }
            return false
        }
        return true
    }
}

#Preview {
    AdminLoginView() {
        
    }
}
