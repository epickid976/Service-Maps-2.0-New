//
//  SplashScreenView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/8/23.
//

import SwiftUI
import NavigationTransitions

struct SplashScreenView: View {
    
    var body: some View {
        NavigationStack {
            VStack {
                Image("mapImage")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 250, height: 250)
                Text("Service Maps")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .multilineTextAlignment(.center)
            }
        }
        .navigationTransition(
            .fade(.in)
        )
    }
}

#Preview {
    SplashScreenView()
}
