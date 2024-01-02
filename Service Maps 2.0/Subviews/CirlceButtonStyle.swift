//
//  CirlceButtonStyle.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/5/23.
//

import Foundation
import SwiftUI

struct CircleButtonStyle: ButtonStyle {
    
    var imageName: String
    var foreground = Color.primary
    var background = Color.white
    var width: CGFloat = 40
    var height: CGFloat = 40
    @Binding var progress: CGFloat
    @Binding var animation: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        Circle()
            .optionalViewModifier { content in
                if progress > 0.01 {
                    content
                        .fill(Color.clear)
                } else {
                    content
                    .fill(Material.ultraThin)
                }
            }
            
            .overlay(Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .foregroundColor(foreground)
                .padding(12)
                .optionalViewModifier { content in
                    if #available(iOS 17, *) {
                        content
                            .symbolEffect(.bounce, options: .speed(3.0), value: animation)
                    }
                }
            )
            .frame(width: width, height: height)
            
    }
}
