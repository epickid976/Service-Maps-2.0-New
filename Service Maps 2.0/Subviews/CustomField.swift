//
//  CustomField.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/8/23.
//

import Foundation
import SwiftUI

struct CustomField: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding // Use FocusState for focus state
    var textfield: Bool
    
    let placeholder: String
    
    var body: some View {
        if textfield {
            TextField(placeholder, text: $text)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)
                .font(.system(size: 16, weight: .regular))
                .accentColor(.blue)
                .focused(isFocused) // Use the isFocused binding property of FocusState
                .gesture(TapGesture().onEnded {
                    // Handle tap action
                    isFocused.wrappedValue = true // Use the isFocused binding property of FocusState
                })
        } else {
            SecureField(placeholder, text: $text)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)
                .font(.system(size: 16, weight: .regular))
                .accentColor(.blue)
                .focused(isFocused) // Use the isFocused binding property of FocusState
                .gesture(TapGesture().onEnded {
                    // Handle tap action
                    isFocused.wrappedValue = true // Use the isFocused binding property of FocusState
                })
        }
            
    }
}
