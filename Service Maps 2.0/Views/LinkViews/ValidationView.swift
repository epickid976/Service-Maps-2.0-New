//
//  ValidationView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/25/24.
//

import SwiftUI
import Lottie
import NavigationTransitions
import Papyrus

struct ValidationView: View {
    
    @StateObject var viewModel: ValidationViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: ValidationViewModel())
        
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" {
                    LottieView(animation: .named("LoadingAnimation"))
                        .playing()
                        .resizable()
                        .looping()
                        .frame(width: 250, height: 250)
                } else {
                    LottieView(animation: .named("LoadingAnimation"))
                        .playing()
                        .resizable()
                        .looping()
                        .frame(width: 350, height: 350)
                }
                
                Text("Activating Account...")
                    .bold()
                    .font(.title3)
                
                Spacer()
                Spacer()
                
                Text("\(viewModel.error)")
                    .bold()
                    .font(.title3)
                    .foregroundStyle(.red)
                
                HStack {
                    
                    CustomBackButton(showImage: true, text: "Cancel") {
                        HapticManager.shared.trigger(.lightImpact)
                        withAnimation {
                            UniversalLinksManager.shared.resetLink()
                        }
                    }.hSpacing(.trailing)
                    CustomButton(loading: viewModel.loading, alwaysExpanded: true, title: "Retry", action: {
                        HapticManager.shared.trigger(.lightImpact)
                        withAnimation { self.viewModel.loading = true }
                        Task {
                            await self.viewModel.activateEmail()
                        }
                    })
                    .hSpacing(.trailing)
                    //.frame(width: 100)
                }
            }
        }
        .navigationBarTitle("Activating Account", displayMode: .automatic)
        .navigationBarBackButtonHidden(true)
        .navigationTransition(.zoom.combined(with: .fade(.in)))
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            HapticManager.shared.trigger(.impact)
            Task {
                viewModel.loading = true
                await viewModel.activateEmail()
            }
        }
    }
    
}


class ValidationViewModel: ObservableObject {
    
    @ObservedObject var universalLinksManager = UniversalLinksManager.shared
    
    @ObservedObject var authenticationManager = AuthenticationManager()
    
    @ObservedObject var dataStore = StorageManager.shared
    
    @Published var loading = true
    @Published var error = ""
    
    func activateEmail() async {
        if universalLinksManager.determineDestination() == .ActivateEmail {
            switch await authenticationManager.activateEmail(token: universalLinksManager.dataFromUrl ?? "") {
            case .success(_):
                HapticManager.shared.trigger(.success)
                _ = await authenticationManager.login(logInForm: LoginForm(email: dataStore.userEmail ?? "", password: dataStore.passTemp ?? ""))
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { self.loading = false}
                    UniversalLinksManager.shared.resetLink()
                }
            case .failure(let error):
                HapticManager.shared.trigger(.error)
                withAnimation { self.loading = false}
                if error.asAFError?.responseCode == -1009 || error.asAFError?.responseCode == nil {
                    DispatchQueue.main.async {
                        self.error = "No Internet Connection. Please try again later."
                    }
                } else {
                    self.error = "There was an error activating account"
                }
            }
        }
    }
    
}
