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
    var territory: Territory
    var houseQuantity: Int
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                    Text("Territory \(territory.number)")
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                Text(territory.territoryDescription ?? "")
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
            .frame(maxWidth: UIScreen.screenWidth * 0.60, alignment: .leading)
            
            
            LazyImage(url: URL(string: territory.image ?? "https://www.google.com/url?sa=i&url=https%3A%2F%2Flottiefiles.com%2Fanimations%2Fno-data-bt8EDsKmcr&psig=AOvVaw2p2xZlutsRFWRoLRsg6LJ2&ust=1712619221457000&source=images&cd=vfe&opi=89978449&ved=0CBEQjRxqFwoTCPjeiPihsYUDFQAAAAAdAAAAABAE")) { state in
                if let image = state.image {
                    image.resizable().aspectRatio(contentMode: .fill).frame(maxWidth: UIScreen.screenWidth * 0.40)
                } else if state.error != nil {
                    Color.clear
                } else {
                    ProgressView().progressViewStyle(.circular)
                        .frame(width: UIScreen.screenWidth * 0.40)
                }
            }
            .cornerRadius(10)
            .frame(alignment: .trailing)
            
            //Image("testTerritoryImage")
            
            
        }
        //.id(territory.id)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .stroke(style: StrokeStyle(lineWidth: 5))
                .fill(
                    .ultraThickMaterial
                )
        )
        .shadow(color: Color(UIColor.systemGray4), radius: 10, x: 0, y: 2)
        .cornerRadius(16)
        .foregroundColor(.white)
    }
    
}

#Preview {
    TerritoryView()
        .environment(\.managedObjectContext, DataController.preview.container.viewContext)
}
