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


extension Font {
    static func interBold(_ size: CGFloat) -> Font { .custom("Inter-Bold", size: size) }
    static func interSemiBold(_ size: CGFloat) -> Font { .custom("Inter-SemiBold", size: size) }
    static func interRegular(_ size: CGFloat) -> Font { .custom("Inter-Regular", size: size) }

    static func satoshiBlack(_ size: CGFloat) -> Font { .custom("Satoshi-Black", size: size) }
    static func satoshiBold(_ size: CGFloat) -> Font { .custom("Satoshi-Bold", size: size) }
    static func satoshiRegular(_ size: CGFloat) -> Font { .custom("Satoshi-Regular", size: size) }

    static func openSansBold(_ size: CGFloat) -> Font { .custom("OpenSans-Bold", size: size) }
    static func openSansRegular(_ size: CGFloat) -> Font { .custom("OpenSans-Regular", size: size) }

    static func spaceGrotesk(_ size: CGFloat) -> Font { .custom("SpaceGrotesk-Bold", size: size) }
}
