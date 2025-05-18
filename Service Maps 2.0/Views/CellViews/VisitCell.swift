//
//  VisitCell.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/8/24.
//

import SwiftUI

//MARK: - Visit Cell

struct VisitCell: View {
    var visit: VisitData
    var ipad: Bool = false
    var mainWindowSize: CGSize
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                // Top Row: Date + Symbol
                HStack {
                    Text(formattedDate(date: Date(timeIntervalSince1970: TimeInterval(visit.visit.date / 1000))))
                        .font(.headline)
                        .fontWeight(.heavy)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(NSLocalizedString(visit.visit.symbol.uppercased(), comment: ""))
                        .font(.caption)
                        .fontWeight(.heavy)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                                {
                                    switch visit.visit.symbol.lowercased() {
                                    case "nt":
                                        return Color.red.opacity(0.8)
                                    case "uk":
                                        return Color.gray.opacity(0.6)
                                    default:
                                        return Color.blue.opacity(0.8)
                                    }
                                }()
                            )
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }

                // Notes
                Text(visit.visit.notes)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .lineLimit(8)

                // User
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(visit.visit.user)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .fontWeight(.bold)
                    }
                }
            }
            .padding()
        }
        .frame(minWidth: ipad ? (mainWindowSize.width / 2) * 0.90 : mainWindowSize.width * 0.90)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
