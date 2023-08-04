//
//  VerificationView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/3/23.
//

import SwiftUI
import ActivityIndicatorView

struct VerificationView: View {
    
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
    
    @State private var apiError = ""
    @State var goToTerritoryLogin = false
    
    @State private var restartAnimation = false
    @State private var animationProgress: CGFloat = 0
    
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
                VStack {
                    LottieAnimationUIView(animationName: "VerificationAnimation", shouldLoop: false, shouldRestartAnimation: $restartAnimation, animationProgress: $animationProgress)
                        .frame(width: 200, height: 200)
                        .padding(.bottom, -50)
                }
                .onTapGesture {
                    restartAnimation = true
                }
            } else {
                VStack {
                    LottieAnimationUIView(animationName: "VerificationAnimation", shouldLoop: true, shouldRestartAnimation: $restartAnimation, animationProgress: $animationProgress)
                        .frame(width: 400, height: 400)
                }
                .onTapGesture {
                    DispatchQueue.main.async {
                        print(restartAnimation)
                        restartAnimation = true
                        //animationProgress = 0.0
                        print(restartAnimation)
                    }
                }
            }
            
            
            Spacer()
            
            Button(action: {
                Task {
                    do {
                        withAnimation {
                            loading = true
                        }
                        let response = try await authenticationApi.login(email: temporaryEmail, password: temporaryPassword)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                loading = false
                                goToTerritoryLogin = true
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
                            alertTitle = "Not verified"
                            alertMessage = "It seems like you have not verified your account. Please check your email and verify your account to continue."
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
            }) {
                if loading {
                    ActivityIndicatorView(isVisible: $alwaysLoading, type: .growingArc(.primary, lineWidth: 1.0))
                        .frame(width: 25, height: 25)
                } else {
                    HStack {
                        Text("Already verified")
                            .fontWeight(.heavy)
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity)
                }
                
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            
            
            NavigationLink(destination: HomeTabView(), isActive: $goToTerritoryLogin) {
                EmptyView()
                
                Spacer()
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    VerificationView()
}
