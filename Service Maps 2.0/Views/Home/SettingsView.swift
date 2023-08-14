//
//  SettingsView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/7/23.
//

import SwiftUI
import ActivityIndicatorView


struct SettingsView: View {
    @State var loading = false
    @State var alwaysLoading = true
    
    //MARK: API
    let authenticationApi = AuthenticationAPI()
    let authorizationProvider = AuthorizationProvider.shared
    
    @State var errorText = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text(errorText)
                Button {
                    Task {
                        do {
                            let _: () = try await authenticationApi.logout()
                            authorizationProvider.isLoggedOut = true
                            authorizationProvider.authorizationToken = nil
                        } catch {
                            errorText = error.asAFError?.localizedDescription ?? ""
                        }
                    }
                } label: {
                    if loading {
                        ActivityIndicatorView(isVisible: $alwaysLoading, type: .growingArc(.primary, lineWidth: 1.0))
                            .frame(width: 25, height: 25)
                    } else {
                        Text("Logout")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.heavy)
                    }
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
            }
            .padding()
        }
    }
}

#Preview {
    SettingsView()
}
