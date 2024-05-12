//
//  CustomSearchBar.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 5/11/24.
//

import Foundation
import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
 
    var body: some View {
        HStack(spacing: 8) {
             Image(systemName: "magnifyingglass")
             TextField("Search...", text: $searchText)
           }
           .padding(8)
           .background(Color.secondary.opacity(0.2))
           .cornerRadius(10)
         }
}
