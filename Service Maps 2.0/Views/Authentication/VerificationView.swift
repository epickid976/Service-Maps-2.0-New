//
//  VerificationView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/3/23.
//

import SwiftUI

struct VerificationView: View {
    
    @State var loading = false
    @State private var apiError = ""
    @State var goToCongregationLogin = false
    
    @State private var restartAnimation = false
    
    //MARK: API
    let authenticationApi = AuthenticationAPI()
    
    @AppStorage("temporaryEmail") var temporaryEmail = ""
    @AppStorage("temporaryPassword") var temporaryPassword = ""
    
    var body: some View {
        LazyVStack {
            Spacer()
            Text("Verification")
                .frame(alignment:.leading)
                .font(.largeTitle)
                .fontWeight(.black)
                .multilineTextAlignment(.leading)
                .hSpacing(.leading)
                //.padding([.leading, .trailing])
                .padding(.bottom)
                //.padding(.bottom, -50)
            
            Text("An email was sent to verify your account. When you have verified, click the button below to continue to your account.")
                .font(.title3)
                .fontWeight(.bold)
            
            
            Spacer()
            
            if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" {
                LottieAnimationUIView(animationName: "VerificationAnimation", shouldLoop: false, shouldRestartAnimation: $restartAnimation)
                    .frame(width: 200, height: 200)
                    .padding(.bottom, -50)
                    .onTapGesture {
                        restartAnimation = true
                    }
            } else {
                LottieAnimationUIView(animationName: "VerificationAnimation", shouldLoop: false, shouldRestartAnimation: $restartAnimation)
                    .frame(width: 500, height: 500)
                    .onTapGesture {
                        restartAnimation = true
                    }
//                    .padding([.bottom], -100)
//                    .padding([.top], -50)
            }
            
            
            Spacer()
            
            Button(action: {
                Task {
                    do {
                        loading = true
                        let response = try await authenticationApi.login(email: temporaryEmail, password: temporaryPassword)
                        
                        loading = false
                        goToCongregationLogin = true
                    } catch {
                        // Handle any errors here
                        print(error.asAFError?.responseCode)
                        print(error.asAFError?.errorDescription)
                        print(error.asAFError?.failureReason)
                        print(error.asAFError?.url)
                        print(error.localizedDescription)
                        apiError = "Error Checking Verification"
                        loading = false
                    }
                }
            }) {
                Text("Verified")
                    .frame(maxWidth: .infinity)
                    .fontWeight(.heavy)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            
            
            NavigationLink(destination: CongregationLoginView(), isActive: $goToCongregationLogin) {
                EmptyView()
                
                Spacer()
            }
        }
        .padding()
    }
}

#Preview {
    VerificationView()
}
