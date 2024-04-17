//
//  TerritoryAddressView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/2/23.
//

import SwiftUI
import NavigationTransitions
import RealmSwift

struct TerritoryAddressView: View {
    var territory: TerritoryObject
    @State var addresses = [TerritoryAddressObject]()
    init(territory: TerritoryObject) {
        self.territory = territory
        
        addresses = RealmManager.shared.addressesFlow.filter({Int32($0.territory) ?? 0 == territory.number})
    }
    
    
    var body: some View {
            ScrollView {
                LazyVStack {
                    ForEach(addresses, id: \.id) { address in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(territory.id )
                                    .font(.title2)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.primary)
                                Text(territory.description )
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
            .navigationTransition(.slide.combined(with: .fade(.in)))
        //viewModel.presentSheet ? .zoom.combined(with: .fade(.in)) : 
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
