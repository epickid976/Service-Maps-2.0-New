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
        VStack {
            WebView(url: URL(string: LinkScreens.PRIVACY_POLICY.rawValue)!)
            Button {
                HapticManager.shared.trigger(.lightImpact)
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Dismiss")
                    .font(.headline)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(40)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 10)
            }
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.automatic)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                HStack {
                    if !sheet {
                        Button("", action: {withAnimation { backAnimation.toggle(); HapticManager.shared.trigger(.lightImpact) };
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                universalLinksManager.resetLink()
                            }
                        })
                        .buttonStyle(CircleButtonStyle(imageName: "arrow.backward", background: .white.opacity(0), width: 39, height: 39, progress: $progress, animation: $backAnimation))//.keyboardShortcut("\r", modifiers: [.command, .shift])
                    }
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
