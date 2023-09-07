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
            .frame(maxWidth: UIScreen.screenWidth * 0.60)
            
            
            LazyImage(url: URL(string: "https://assetsnffrgf-a.akamaihd.net/assets/m/502016177/univ/art/502016177_univ_lsr_xl.jpg")) { state in
                if let image = state.image {
                    image.resizable().aspectRatio(contentMode: .fill).frame(maxWidth: UIScreen.screenWidth * 0.40)
                } else if state.error != nil {
                    Color.red
                } else {
                    ProgressView().progressViewStyle(.circular)
                }
            }
            .cornerRadius(10)
            
            //Image("testTerritoryImage")
            
            
        }
        .id(territory.id)
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
