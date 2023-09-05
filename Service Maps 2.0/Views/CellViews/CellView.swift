//
//  CellView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/5/23.
//
import SwiftUI
import CoreData

struct CellView: View {
    var territory: Territory
    @Binding var isAscending: Bool
    
    @FetchRequest(
        entity: House.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \House.number, ascending: true)
        ],
        animation: .default
    )
    private var fetchedHouses: FetchedResults<House>
    
    @State private var houses: [House] = []
    
    private var territoryPredicate: NSPredicate {
        NSPredicate(format: "territoryAddress == %@", argumentArray: [territory.number])
    }
    
    init(territory: Territory, isAscending: Binding<Bool>) {
        self.territory = territory
        self._isAscending = isAscending
    }
    
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
                Text("Doors: \(houses.count)")
                    .font(.body)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            
            Image("testTerritoryImage")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 180, height: .infinity)
                .cornerRadius(10)
        }
        .animation(.spring(duration: 0.3), value: isAscending)
        .id(territory.id)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .stroke(style: StrokeStyle(lineWidth: 5))
                .foregroundColor(Color(UIColor.systemGray3))
        )
        .shadow(color: Color(UIColor.systemGray4), radius: 10, x: 0, y: 2)
        .cornerRadius(16)
        .foregroundColor(.white)
        .onAppear {
            fetchHouses()
        }
    }
    
    private func fetchHouses() {
        let request: NSFetchRequest<House> = House.fetchRequest()
        request.predicate = territoryPredicate
        request.sortDescriptors = [NSSortDescriptor(keyPath: \House.number, ascending: true)]
        
        do {
            houses = try DataController.shared.container.viewContext.fetch(request)
        } catch {
            // Handle error
            houses = []
        }
    }
}

#Preview {
    TerritoryView()
        .environment(\.managedObjectContext, DataController.preview.container.viewContext)
}
