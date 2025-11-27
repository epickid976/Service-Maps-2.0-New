//
//  TabBarSearchManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 11/27/24.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Tab Bar Search Manager
/// A global observable object that controls tab bar visibility during search.
/// When `isSearchActive` is true, the tab bar should be hidden.

@MainActor
final class TabBarSearchManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = TabBarSearchManager()
    
    private init() {}
    
    // MARK: - Search State
    
    /// Whether search is currently active (tab bar should be hidden)
    @Published var isSearchActive: Bool = false
    
    /// The current search mode (Territories or Phone)
    @Published var searchMode: SearchMode = .Territories
    
    /// The current search query text
    @Published var searchQuery: String = ""
    
    // MARK: - Methods
    
    /// Activates search mode with the specified mode
    func activateSearch(mode: SearchMode) {
        withAnimation(.easeInOut(duration: 0.2)) {
            self.searchMode = mode
            self.searchQuery = ""
            self.isSearchActive = true
        }
        HapticManager.shared.trigger(.lightImpact)
    }
    
    /// Deactivates search mode
    func deactivateSearch() {
        withAnimation(.easeInOut(duration: 0.2)) {
            self.isSearchActive = false
            self.searchQuery = ""
        }
    }
    
    /// Resets search state completely
    func reset() {
        self.isSearchActive = false
        self.searchQuery = ""
        self.searchMode = .Territories
    }
}

