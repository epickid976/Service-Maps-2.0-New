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
    
    //MARK: - Body
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Grid(alignment: .leading) {
                    GridRow {
                        Text(formattedDate(date: Date(timeIntervalSince1970: TimeInterval(visit.visit.date / 1000))))
                            .font(.headline)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.secondaryLabel)
                            .fontWeight(.heavy)
                            .hSpacing(.leading)
                        Text(NSLocalizedString(visit.visit.symbol.localizedUppercase, comment: ""))
                            .font(.title3)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                            .fontWeight(.heavy)
                            .hSpacing(.trailing)
                            .gridColumnAlignment(.trailing)
                            .frame(maxWidth: 40)
                    }
                }.vSpacing(.top)
                Text(visit.visit.notes)
                    .font(.headline)
                    .lineLimit(4)
                    .foregroundColor(.primary)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true).vSpacing(.top)
                Spacer().frame(height: 5)
                Text(visit.visit.user)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundColor(.secondaryLabel)
                    .fontWeight(.heavy)
                    .hSpacing(.trailing).vSpacing(.bottom)
            }
        }
        .padding(10)
        .frame(minWidth: ipad ? (mainWindowSize.width / 2) * 0.90 : mainWindowSize.width * 0.90)
        .background(.thinMaterial)
        .optionalViewModifier { content in
            if ipad {
                content
                    .frame(maxHeight: .infinity)
            } else {
                content
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
