//
//  HouseCell.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/5/23.
//

import SwiftUI
import NukeUI

struct HouseCell: View {
    var house: HouseData
    var mainWindowSize: CGSize
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                // House Number
                HStack {
                    Text("\(house.house.number)")
                        .font(.title2)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .fontWeight(.heavy)
                        .hSpacing(.leading)
                        .padding(.leading, 5)
                    
                    // Symbol
                    Text("Symbol: \(house.visit?.symbol.localizedUppercase ?? "-")")
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .fontWeight(.bold)
                        .hSpacing(.trailing)
                        .padding(.trailing, 5)
                }
                // Date
                Text("Date: \(house.visit != nil ? formattedDate(date: Date(timeIntervalSince1970: Double(house.visit!.date) / 1000)) : "N/A")")
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                    .fontWeight(.bold)
                    .hSpacing(.leading
                    ).padding(.leading, 5)
                
                // Notes
                Text("Note: \(house.visit?.notes ?? "No notes")")
                    .font(.subheadline)
                    .lineLimit(4)
                    .foregroundColor(.primary)
                    .fontWeight(.bold)
                    .padding(.leading, 5)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(10)
        .frame(minWidth: mainWindowSize.width * 0.95)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
