//
//  ViewExtension.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/2/23.
//

import SwiftUI

extension View {
    //Custom Spacers
    @ViewBuilder
    func hSpacing(_ alignment: Alignment) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: alignment)
    }
    
    @ViewBuilder
    func vSpacing(_ alignment: Alignment) -> some View {
        self
            .frame(maxHeight: .infinity, alignment: alignment)
    }
    
}
