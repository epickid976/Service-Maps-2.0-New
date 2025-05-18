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
                .foregroundColor(.primary)

            TextField("Search...", text: $searchText)
                .focused(isFocused)
                .textInputAutocapitalization(.none)
                .disableAutocorrection(true)
                .foregroundColor(.primary)
                .overlay(alignment: .trailing) {
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 4)
                    }
                }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.ultraThin)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .blur(radius: 0.5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.6)
                )
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            isFocused.wrappedValue = true
        }
    }
}

