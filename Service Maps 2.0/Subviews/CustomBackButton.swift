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
                    .fill(Material.ultraThin)
                    .background(Capsule().fill(Color.white.opacity(0.05)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
            )
            .foregroundColor(colorScheme == .dark ? .white : .black)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }
}
