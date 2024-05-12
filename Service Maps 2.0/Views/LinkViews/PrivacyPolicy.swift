//
//  PrivacyPolicy.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/25/24.
//

import SwiftUI
import WebKit

struct PrivacyPolicy: View {
    var sheet: Bool
    
    @State var backAnimation = false
    @State var progress: CGFloat = 0.0
    @State var optionsAnimation = false
    
    init(sheet: Bool = false) {
        self.sheet = sheet
    }
    
    @ObservedObject var universalLinksManager = UniversalLinksManager.shared
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            WebView(url: URL(string: LinkScreens.PRIVACY_POLICY.rawValue)!)
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                HStack {
                    Button("", action: {withAnimation { backAnimation.toggle() };
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if sheet {
                                presentationMode.wrappedValue.dismiss()
                            } else {
                                universalLinksManager.resetLink()
                            }
                        }
                    })
                    .buttonStyle(CircleButtonStyle(imageName: "arrow.backward", background: .white.opacity(0), width: 39, height: 39, progress: $progress, animation: $backAnimation)).keyboardShortcut("\r", modifiers: [.command, .shift])
                }
            }
        }
    }
}



struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}
