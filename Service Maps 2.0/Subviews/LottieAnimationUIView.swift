//
//  LottieAnimationView.swift
//  PayCheckCalc
//
//  Created by Jose Blanco on 5/28/23.
//

import Foundation
import SwiftUI
import Lottie


struct LottieAnimationUIView: UIViewRepresentable {
    typealias UIViewType = UIView
    var animationName: String
    var animationView = LottieAnimationView()
    var shouldLoop: Bool = true // Add shouldLoop property
    @Binding var shouldRestartAnimation: Bool // Add shouldRestartAnimation property

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let animationView = LottieAnimationView(name: animationName)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        
        if shouldLoop {
            animationView.loopMode = .loop // Set loopMode to .loop if shouldLoop is true
        } else {
            animationView.loopMode = .playOnce // Set loopMode to .playOnce if shouldLoop is false
        }
        
        view.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        animationView.play()
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        let tempFileName = context.coordinator.parent.animationName
        DispatchQueue.main.async {
            context.coordinator.parent.animationName = animationName
            if tempFileName != animationName {
                if shouldLoop {
                    context.coordinator.parent.animationView.loopMode = .loop // Set loopMode to .loop if shouldLoop is true
                } else {
                    context.coordinator.parent.animationView.loopMode = .playOnce // Set loopMode to .playOnce if shouldLoop is false
                }
            }
            if shouldRestartAnimation {
                context.coordinator.parent.animationView.play(fromProgress: 0, toProgress: 1, loopMode: context.coordinator.parent.animationView.loopMode) { _ in
                    context.coordinator.parent.animationView.play()
                }
                shouldRestartAnimation = false
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: LottieAnimationUIView

        init(_ parent: LottieAnimationUIView) {
            self.parent = parent
        }
    }
}
