//
//  CustomButton.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/8/23.
//

import Foundation
import SwiftUI
import ActivityIndicatorView

struct CustomButton: View {
    var loading: Bool
    var title: String
    var color: Color?
    var action: () -> Void
    

    @State var alwaysLoading = true
    var body: some View {
        Button(action: action) {
            if loading {
                ActivityIndicatorView(isVisible: $alwaysLoading, type: .growingArc(.primary, lineWidth: 1.0))
                    .frame(width: 25, height: 25)
            } else {
                Text(title)
                    .frame(maxWidth: .infinity)
                    .fontWeight(.heavy)
            }
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(color ?? .accentColor)
        .controlSize(.large)
    }
}
