//
//  RegisterKeyView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/26/24.
//

import SwiftUI
import Lottie
import NavigationTransitions


struct RegisterKeyView: View {
    @ObservedObject var viewModel = AccessViewModel()
    
    @State var error = ""
    @State var loading = true
    
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
                
                Text("Registering key...")
                    .bold()
                    .font(.title3)
                
                Spacer()
                Spacer()
                
                Text("\(error)")
                    .bold()
                    .font(.title3)
                    .foregroundStyle(.red)
                
                HStack {
                    
                    CustomBackButton(showImage: true, text: "Cancel") {
                        withAnimation {
                            UniversalLinksManager.shared.resetLink()
                        }
                    }.hSpacing(.trailing)
                    CustomButton(loading: loading, alwaysExpanded: true, title: "Retry", action: {
                        DispatchQueue.main.async {
                            withAnimation { self.loading = true }
                        }
                        Task {
                            if viewModel.universalLinksManager.determineDestination() == .RegisterKeyView {
                                switch await viewModel.registerKey() {
                                case .success(_):
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation { self.loading = false}
                                        UniversalLinksManager.shared.resetLink()
                                        SynchronizationManager.shared.startupProcess(synchronizing: true)
                                    }
                                case .failure(let error):
                                    withAnimation { self.loading = false}
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        if error.asAFError?.responseCode == -1009 || error.asAFError?.responseCode == nil {
                                            DispatchQueue.main.async {
                                                self.error = "No Internet Connection. Please try again later."
                                            }
                                        } else {
                                            DispatchQueue.main.async {
                                                self.error =  "There was an error registering key."
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    })
                    .hSpacing(.trailing)
                    //.frame(width: 100)
                }
            }
        }
        .navigationBarTitle("Registering Key", displayMode: .automatic)
        .navigationBarBackButtonHidden(true)
        .navigationTransition(.zoom.combined(with: .fade(.in)))
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            Task {
                DispatchQueue.main.async {
                    self.loading = true
                    error = ""
                }
                switch await viewModel.registerKey() {
                case .success(_):
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation { self.loading = false}
                        UniversalLinksManager.shared.resetLink()
                        SynchronizationManager.shared.startupProcess(synchronizing: true)
                    }
                case .failure(let error):
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { self.loading = false}
                        if error.asAFError?.responseCode == -1009 || error.asAFError?.responseCode == nil {
                            DispatchQueue.main.async {
                                self.error = "No Internet Connection. Please try again later."
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.error =  "There was an error registering key."
                            }
                        }
                    }
                }
            }
        }
    }
}


