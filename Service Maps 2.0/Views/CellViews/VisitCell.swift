//
//  VisitCell.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/8/24.
//

import SwiftUI

struct VisitCell: View {
    var visit: VisitData
    @Environment(\.mainWindowSize) var mainWindowSize
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Grid(alignment: .leading) {
                    GridRow {
                        Text(formattedDate(date: Date(timeIntervalSince1970: TimeInterval(visit.visit.date / 1000))))
                            .font(.headline)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                            .fontWeight(.heavy)
                            .hSpacing(.leading)
                        Spacer().frame(width: 5)
                        Text(NSLocalizedString(visit.visit.symbol.localizedUppercase, comment: ""))
                            .font(.title3)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                            .fontWeight(.heavy)
                            .hSpacing(.trailing)
                            .gridColumnAlignment(.trailing)
                            .frame(maxWidth: 40)
                    }
                }
                
                Text(visit.visit.notes)
                    .font(.headline)
                    .lineLimit(4)
                    .foregroundColor(.primary)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(visit.visit.user)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                    .fontWeight(.heavy)
                    .hSpacing(.trailing)
            }
            .padding(5)
        }
        .padding(10)
        .frame(minWidth: mainWindowSize.width * 0.90)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

//#Preview {
//    VisitCell()
//}
