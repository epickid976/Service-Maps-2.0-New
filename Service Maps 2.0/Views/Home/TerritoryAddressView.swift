//
//  TerritoryAddressView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/2/23.
//

import SwiftUI
import NavigationTransitions

struct TerritoryAddressView: View {
    var territory: Territory
    
    @FetchRequest(sortDescriptors: [
        SortDescriptor(\TerritoryAddress.address, order: .reverse)
    ]) var addresses: FetchedResults<TerritoryAddress>
    
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
                    ForEach(addresses, id: \.id) { address in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(territory.id ?? "")
                                    .font(.title2)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.primary)
                                Text(territory.territoryDescription ?? "")
                                    .font(.headline)
                                    .lineLimit(5)
                                    .foregroundColor(.primary)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.leading)
                                Text("Floors: ")
                                    .font(.body)
                                    .lineLimit(2)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: UIScreen.screenWidth * 0.60)
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
            }
            .onAppear {
                //addresses.nsPredicate = NSPredicate(format: "id == %@", String(territory.number))
            }
        }
        .navigationTransition(.zoom.combined(with: .fade(.in)))
            //.navigationViewStyle(StackNavigationViewStyle())
    }
}

//#Preview {
//    let newTerritory = Territory(context: DataController.shared.container.viewContext)
//    newTerritory.id = UUID().uuidString
//    newTerritory.territoryDescription = "1850 W 56 St Hialeah FL 33012 United States (The Middle Building)"
//    newTerritory.congregation = "1260"
//    newTerritory.number = Int32(1)
//    TerritoryAddressView(territory: newTerritory)
//}
