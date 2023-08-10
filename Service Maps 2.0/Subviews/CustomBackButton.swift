//
//  CustomButtonStyle.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/8/23.
//

import Foundation
import SwiftUI

struct CustomButton: View {
    @Environment(\.colorScheme) var colorScheme
    
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .padding()
                .font(.title)
                .background(colorScheme == .dark ? Color.white : Color.black)
                .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.gray, lineWidth: 2)
                )
        }
    }
}
