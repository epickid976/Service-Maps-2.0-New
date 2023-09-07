//
//  NavigationAnimation.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/6/23.
//

import Foundation
import NavigationTransitions

extension AnyNavigationTransition {
    static var zoom: Self {
        .init(Zoom())
    }
}

struct Zoom: NavigationTransition {
    var body: some NavigationTransition {
        MirrorPush {
            Scale(0.5)
            OnInsertion {
                ZPosition(1)
                Opacity()
            }
        }
    }
}
