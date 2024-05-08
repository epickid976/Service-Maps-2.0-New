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
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    HStack {
                        Text(formattedDate(date: Date(timeIntervalSince1970: TimeInterval(visit.visit.date / 1000))))
                            .font(.title3)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                            .fontWeight(.heavy)
                            .hSpacing(.leading)
                    }.frame(maxWidth: mainWindowSize.width * 0.9, maxHeight: 100)
                    
                    HStack {
                        Text(visit.visit.symbol.localizedUppercase)
                            .font(.title3)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                            .fontWeight(.heavy)
                            .hSpacing(.trailing)
                    }
                    .frame(maxWidth: mainWindowSize.width * 0.1, maxHeight: 100)
                }
                
                Text(visit.visit.notes)
                    .font(.headline)
                    .lineLimit(4)
                    .foregroundColor(.primary)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                
                Text(visit.visit.user)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                    .fontWeight(.heavy)
                    .hSpacing(.trailing)
                
            }
            .frame(maxWidth: .infinity)
            
        }
        .padding(10)
        .frame(minWidth: mainWindowSize.width * 0.95)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
}

//#Preview {
//    VisitCell()
//}
