//
//  UIScreen Extension.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/2/23.
//

import Foundation
import SwiftUI

extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}

private struct MainWindowSizeKey: EnvironmentKey {
    static let defaultValue: CGSize = .zero
}

extension EnvironmentValues {
    var mainWindowSize: CGSize {
        get { self[MainWindowSizeKey.self] }
        set { self[MainWindowSizeKey.self] = newValue }
    }
}

extension Color {
    static let onBackgroundPrimary: Color = .init(hex: 0x252525)
    static let onBackgroundSecondary: Color = .init(hex: 0x6F7278)
    static let onBackgroundTertiary: Color = .init(hex: 0xEEF1F7)
}

private extension Color {
    init(hex: UInt) { self.init(.sRGB, red: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 08) & 0xff) / 255, blue: Double((hex >> 00) & 0xff) / 255, opacity: 1) }
}
