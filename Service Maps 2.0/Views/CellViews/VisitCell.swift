//
//  VisitCell.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/8/24.
//

import SwiftUI

struct VisitCell: View {
    var visit: Visit
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    HStack {
                        Text(formattedDate(date: Date(timeIntervalSince1970: TimeInterval(visit.date / 1000))))
                            //.frame(maxWidth: .infinity)
                            .font(.title3)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                            .fontWeight(.heavy)
                            .hSpacing(.leading)
                           
//                        Spacer()
//                        Text(Date(timeIntervalSince1970: TimeInterval(visit.date / 1000)), style: .time)
//                            .font(.title3)
//                            .lineLimit(1)
//                            .foregroundColor(.primary)
//                            .fontWeight(.heavy)
//                            .hSpacing(.leading)
                    }
                    //.frame(minWidth: 200)
                    
                    HStack {
                        Text(visit.symbol ?? "-")
                            .font(.title3)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                            .fontWeight(.heavy)
                            .hSpacing(.trailing)
                    }
                }
                
                Text(visit.notes ?? "_NO_NOTES_")
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                    .fontWeight(.heavy)
                    .hSpacing(.leading)
                
                Text(visit.user ?? "ERROR_NO_USER")
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

//#Preview {
//    VisitCell()
//}
