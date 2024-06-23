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
    
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    
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
    
    @Environment(\.sizeCategory) var sizeCategory
    
    var body: some View {
        
        NavigationStack {
            LazyVStack {
                
                Text("Congregation \nLogin")
                    .frame(alignment:.leading)
                    .font(sizeCategory == .large || sizeCategory == .extraLarge ? .largeTitle : .title2)
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
                    .textContentType(.username)
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
                
                Spacer()
                
                VStack {
                    Button {
                        HapticManager.shared.trigger(.lightImpact)
                        openMail(emailTo: "epickid976@gmail.com",
                                     subject: "Congregation Login Creation Request",
                                     body: "")
                    } label: {
                        Text("Need account? Contact me")
                            .bold()
                    }
                }
                
                
                Spacer()
                
                HStack {
                    if synchronizationManager.startupState != .AdminLogin {
                        if !loading {
                            CustomBackButton() { dismiss(); HapticManager.shared.trigger(.lightImpact) }.keyboardShortcut("\r", modifiers: [.command, .shift])
                        }
                    }
                    
                    Button {
                        HapticManager.shared.trigger(.lightImpact)
                        let validation = validate()
                        if validation {
                            Task {
                                withAnimation {
                                    loading = true
                                }
                                
                                switch await AuthenticationManager().signInAdmin(congregationSignInForm: CongregationSignInForm(id: Int64(username) ?? 0, password: password)) {
                                case .success(_):
                                    HapticManager.shared.trigger(.success)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        withAnimation {
                                            loading = false
                                        }
                                        onDone()
                                    }
                                case .failure(let error):
                                    HapticManager.shared.trigger(.error)
                                    if error.localizedDescription == "No Internet" {
                                        alertTitle = "No Internet Connection"
                                        alertMessage = "There was a problem with the internet connection. \nPlease check your internect connection and try again."
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                            withAnimation {
                                                //apiError = "Error Signing up"
                                                loading = false
                                                showAlert = true
                                            }
                                        }
                                    } else if error.localizedDescription == "Wrong Credentials" {
                                        alertTitle = "Wrong Credentials"
                                        alertMessage = "The credentials you typed don't seem to be correct.\n Please try again."
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                            withAnimation {
                                                //apiError = "Error Signing up"
                                                loading = false
                                                showAlert = true
                                            }
                                        }
                                    } else if error.localizedDescription == "No Congregation" {
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
                            HapticManager.shared.trigger(.error)
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
                    .keyboardShortcut("\r", modifiers: .command)
                    //.padding([.bottom])
                }
                .padding()
                
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("\(alertTitle)"), message: Text("\(alertMessage)"), dismissButton: .default(Text("OK")))
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
        .navigationTransition(.zoom.combined(with: .fade(.in)))
        .toolbar{
            ToolbarItemGroup(placement: .keyboard){
                Spacer()
                
                Button("Done"){
                    HapticManager.shared.trigger(.lightImpact)
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
