//
//  TokenCell.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/9/24.
//

import SwiftUI

struct TokenCell: View {
    var token: MyToken
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("\(token.name ?? "ERROR_NO_NAME")")
                        .font(.title3)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .fontWeight(.heavy)
                        .hSpacing(.leading)
                }
                
                if token.moderator {
                    Text("Level: Servant")
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .fontWeight(.heavy)
                        .hSpacing(.leading)
                } else {
                    Text("Level: Publisher")
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .fontWeight(.heavy)
                        .hSpacing(.leading)
                }
                
                Text("Territories _NO_NOTES_")
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                
                Text(token.owner ?? "ERROR_NO_OWNER")
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                    .fontWeight(.heavy)
                    .hSpacing(.trailing)
                
            }
            .frame(maxWidth: .infinity)
            
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .stroke(style: StrokeStyle(lineWidth: 5))
                .fill(
                    .ultraThinMaterial
                )
        )
        .shadow(color: Color(UIColor.systemGray4), radius: 10, x: 0, y: 2)
        .cornerRadius(16)
        .foregroundColor(.white)
    }
}


