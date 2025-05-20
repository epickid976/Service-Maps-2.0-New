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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                // Date + Symbol Row
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
                            Capsule()
                                .fill(colorForSymbol(visit.visit.symbol))
                        )
                        .foregroundColor(.white)
                }

                Text(visit.visit.notes)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .lineLimit(8)

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
                .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.05), lineWidth: 0.6)
                )
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.08 : 0.05), radius: 6, x: 0, y: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    func colorForSymbol(_ symbol: String) -> Color {
        switch symbol.lowercased() {
        case "nt": return .red.opacity(0.8)
        case "uk": return .gray.opacity(0.6)
        default: return .blue.opacity(0.8)
        }
    }
}
