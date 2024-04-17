//
//  AccessViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/9/24.
//

import Foundation
import SwiftUI
import CoreData
import Combine
import NavigationTransitions
import SwipeActions
import RealmSwift

@MainActor
class AccessViewModel: ObservableObject {
    
    //@Published var tokens: Results<TokenObject>
    
    //@ObservedObject var databaseManager = RealmManager.shared
    
//    init() {
//        //tokens = databaseManager.tokensFlow
//    }
    
    @Published var currentToken: TokenObject?
    @Published var presentSheet = false {
        didSet {
            if presentSheet == false {
                currentToken = nil
            }
        }
    }
    
    @Published var optionsAnimation = false
    @Published var progress: CGFloat = 0.0
    
}
