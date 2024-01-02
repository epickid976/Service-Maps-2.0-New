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
    var shouldLoop: Bool = true
    @Binding var shouldRestartAnimation: Bool
    @Binding var animationProgress: CGFloat

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let animationView = LottieAnimationView(name: animationName)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        
        if shouldLoop {
            animationView.loopMode = .loop
        } else {
            animationView.loopMode = .playOnce
        }
        
        view.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        animationView.play()
        
        animationView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTapGesture(_:)))
        animationView.addGestureRecognizer(tapGesture)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        let tempFileName = context.coordinator.parent.animationName
        DispatchQueue.main.async {
            context.coordinator.parent.animationName = animationName
            if tempFileName != animationName {
                if shouldLoop {
                    context.coordinator.parent.animationView.loopMode = .loop
                } else {
                    context.coordinator.parent.animationView.loopMode = .playOnce
                }
            }
            
            if shouldRestartAnimation {
                animationView.play(fromProgress: 0, toProgress: 1, loopMode: context.coordinator.parent.animationView.loopMode) { _ in
                    // Update the animationProgress after the animation completes
                    context.coordinator.parent.animationProgress = 1
                }
                shouldRestartAnimation = false
            }
        }
        
    }
    
    func restartAnimation() {
        if shouldRestartAnimation {
            animationView.stop()
            animationProgress = CGFloat(floatLiteral: 0.0)
            animationView.play()
            shouldRestartAnimation = false
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
        
        @objc func handleTapGesture(_ gesture: UITapGestureRecognizer) {
            parent.animationProgress = 0
            parent.shouldRestartAnimation = true
            parent.restartAnimation()
        }
    }
}
