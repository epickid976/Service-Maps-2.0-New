//
//  Territory View.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/4/23.
//

import SwiftUI
import CoreData

struct TerritoryView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Territory.number, ascending: true)],
        animation: .spring)
    private var territories: FetchedResults<Territory>
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(territories, id: \.id) { territory in
                        CellView(territory: territory)
                            .padding(.bottom, 3)
                            
                    }
                }
                .padding()
                //.animation(.default, value: territories.)
            }
            .navigationBarTitle("Territories", displayMode: .automatic)
            .navigationBarBackButtonHidden(true)
            .font(.title)
            .bold()
        }
    }
}

#Preview {
    TerritoryView()
        .environment(\.managedObjectContext, DataController.preview.container.viewContext)
}
