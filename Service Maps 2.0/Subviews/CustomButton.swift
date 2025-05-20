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
    var color: Color? = nil
    var active: Bool = true
    var action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Text layer
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .opacity(loading ? 0 : 1)
                
                // Spinner layer
                if loading {
                    if alwaysExpanded {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: spinnerColor))
                                .scaleEffect(0.8)
                            Spacer()
                        }
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: spinnerColor))
                            .scaleEffect(0.8)
                    }
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill((color ?? .blue).opacity(colorScheme == .dark ? 0.4 : 0.7)) // Increased opacity for light mode
                    .background(
                        Capsule().fill(colorScheme == .dark ? Material.ultraThin : Material.regular)
                    )
                    .overlay(
                        Capsule().stroke(Color.white.opacity(colorScheme == .dark ? 0.2 : 0.1), lineWidth: 1)
                    )
                    .shadow(color: (color ?? .blue).opacity(0.4), radius: 6, x: 0, y: 3)
            )
            .foregroundColor(textColor)
            .clipShape(Capsule())
            .opacity(active ? 1 : 0.6)
            .buttonStyle(PlainButtonStyle())
            .disabled(!active)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!active)
    }
    
    private var spinnerColor: Color {
        if let color = color {
            return [.red, .blue, .accentColor].contains(color) ? .white : .gray
        }
        return .white
    }
    
    private var textColor: Color {
        if let color = color {
            return [.red, .blue, .accentColor].contains(color) ? .white : color
        }
        return .primary
    }
}
