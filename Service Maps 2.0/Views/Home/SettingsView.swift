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
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Button {
                    Task {
                        do {
                            let response: () = try await authenticationApi.logout()
                        } catch {
                            print(error.asAFError)
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
