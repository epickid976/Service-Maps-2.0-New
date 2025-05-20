//
//  CustomButtonStyle.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/8/23.
//

import Foundation
import SwiftUI

//MARK: - Custom Button Style

struct CustomBackButton: View {
    var showImage: Bool = true
    var text: String = NSLocalizedString("Back", comment: "")
    @Environment(\.colorScheme) var colorScheme
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if showImage {
                    Image(systemName: "chevron.backward")
                        .fontWeight(.heavy)
                }
                Text(text)
                    .fontWeight(.heavy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .background(
                Capsule()
                    .fill(colorScheme == .dark ? Material.ultraThin : Material.regular) // Conditional material
                    .background(Capsule().fill(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1))) // Adjust inner opacity
                    .overlay(
                        Capsule().stroke(
                            colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1), // Darker stroke for light mode
                            lineWidth: 1
                        )
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
            )
            .foregroundColor(colorScheme == .dark ? .white : .primary) // Use primary for better light mode visibility
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }
}
