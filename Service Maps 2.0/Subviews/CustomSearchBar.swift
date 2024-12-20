//
//  CustomSearchBar.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 5/11/24.
//

import Foundation
import SwiftUI

//MARK: - SearchBar
struct SearchBar: View {
    @Binding var searchText: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
            TextField("Search...", text: $searchText)
                .focused(isFocused)
                .overlay(alignment: .trailing) {
                    if !searchText.isEmpty { // Show clear button only when text exists
                        Button(action: {
                            searchText = "" // Clear text when button is tapped
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray) // Optional styling
                        }
                        .padding(.trailing, 8) // Add padding to the button
                    }
                }
        }
        .onAppear {
            isFocused.wrappedValue = true
        }
        .padding(8)
        .background(Color.secondaryLabel.opacity(0.2))
        .cornerRadius(10)
    }
}

