//
//  CustomButtonStyle.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/8/23.
//

import Foundation
import SwiftUI


struct CustomBackButton: View {
    var showImage: Bool = true
    var text: String = "Back"
    @Environment(\.colorScheme) var colorScheme
    var action: () -> Void
    
    
    var body: some View {
        Button(action: action) {
            HStack {
                if showImage {
                    Image(systemName: "chevron.backward")
                        .fontWeight(.heavy)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                }
                Text("\(text)")
                    .fontWeight(.heavy)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.clear)
            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            .overlay(
                Capsule()
                    .stroke(Color.gray, lineWidth: 2)
            )
        }
    }
}
