//
//  CellView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/5/23.
//
import SwiftUI
import CoreData
import NukeUI

struct CellView: View {
    var territory: TerritoryModel
    var houseQuantity: Int
    var width: Double = 0.95
    
    var body: some View {
        HStack(spacing: 10) {
            VStack {
                ZStack {
                   Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .teal]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack {
                        Text("\(territory.number)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                    }
                    .frame(minWidth: UIScreen.main.bounds.width * 0.28)
                }
                .hSpacing(.leading)
                .frame(width: 70, height: 70, alignment: .center)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(territory.description )
                    .font(.headline)
                    .lineLimit(5)
                    .foregroundColor(.primary)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                Text("Doors: \(houseQuantity)")
                    .font(.body)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: UIScreen.screenWidth * 0.72, alignment: .leading)
            //Image("testTerritoryImage")
            
            
        }
        //.id(territory.id)
        .padding(5)
        .frame(minWidth: UIScreen.main.bounds.width * width)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
}
