//
//  OvalTextFieldStyle.swift
//  SubscriptionAnalyzer
//
//  Created by Jose Blanco on 4/26/23.
//

import Foundation
import SwiftUI


struct OvalTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(10)
            .cornerRadius(40)
            //.shadow(color: .gray, radius: 5)
            .frame(height:50)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
            )
        
//            .frame(width: 100, height: 25 )
//            .padding(10)
//
//             .frame(height: 25)
//             .overlay(RoundedRectangle(cornerRadius: 16)
//             .stroke(Color.gray.opacity(0.3), lineWidth: 2))
    }
}


