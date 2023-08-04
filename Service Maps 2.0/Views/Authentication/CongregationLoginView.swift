//
//  LoginView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/2/23.
//

import Foundation
import SwiftUI
import NavigationTransitions

struct CongregationLoginView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var username: String = ""
    @State private var password: String = ""
    
    @State private var usernameError = ""
    @State private var passwordError = ""
    
    @FocusState private var emailFocus: Bool
    @FocusState private var passwordFocus: Bool
    
    @State private var restartAnimation = false
    
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
                    LottieAnimationUIView(animationName: "CongregationLogin", shouldLoop: false, shouldRestartAnimation: $restartAnimation)
                        .frame(width: 200, height: 200)
                        .padding(50)
                } else {
                    LottieAnimationUIView(animationName: "CongregationLogin", shouldLoop: false, shouldRestartAnimation: $restartAnimation)
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
                TextField("ID", text: $username, onEditingChanged: { isEditing in
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
                    
                    Button {
                        
                    } label: {
                        Text("Login")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.heavy)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    //.padding([.bottom])
                }
                .padding()
                
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
            usernameError = "ID cannot contain spaces"
        } else {
            usernameError = ""
        }
    }
}

#Preview {
    CongregationLoginView()
}
