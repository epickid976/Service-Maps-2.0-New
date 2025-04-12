//
//  CustomButton.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/8/23.
//

import Foundation
import SwiftUI
import ActivityIndicatorView

//MARK: - Custom Button
struct CustomButton: View {
    var loading: Bool
    var alwaysExpanded: Bool = false
    var title: String
    var color: Color?
    var active: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Text layer
                Text(title)
                    .fontWeight(.heavy)
                    .opacity(loading ? 0 : 1)
                    .frame(maxWidth: .infinity)

                // Spinner layer
                if loading {
                    if alwaysExpanded {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: spinnerColor))
                                .scaleEffect(0.8)
                                .frame(width: 10, height: 10)
                            Spacer()
                        }
                        .transition(.opacity)
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: spinnerColor))
                            .scaleEffect(0.8)
                            .frame(width: 10, height: 10)
                            .transition(.opacity)
                    }
                }
            }
            // 👇 Add animation here — not when setting `loading`
            .animation(.spring(), value: loading)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(color ?? .accentColor)
        .controlSize(.large)
        .disabled(!active)
    }

    private var spinnerColor: Color {
        if let color = color {
            return color == .red || color == .blue || color == .accentColor ? .white : .gray
        }
        return .white
    }
}
