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

@MainActor
class AccessViewModel: ObservableObject {
    
    private var tokens: FetchedResultList<MyToken>
    
    
     init(context: NSManagedObjectContext = DataController.shared.container.viewContext) {
         tokens = FetchedResultList(context: context, sortDescriptors: [
            NSSortDescriptor(keyPath: \MyToken.owner, ascending: true)
           ])
         
         tokens.willChange = { [weak self] in self?.objectWillChange.send() }
         
    }
    
    @Published var currentToken: MyToken?
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

extension AccessViewModel {
    var tokensList: [MyToken] {
        tokens.items
    }
}
