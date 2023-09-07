//
//  HouseCell.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/5/23.
//

import SwiftUI
import NukeUI

struct HouseCell: View {
    var house: House
    var lastVisit: Visit? = nil
    
    @FetchRequest(
        entity: Visit.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Visit.date, ascending: false)
        ],
        animation: .default
    )
    private var visits: FetchedResults<Visit>
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    VStack {
                        ZStack {
                            Color(UIColor.secondarySystemBackground).edgesIgnoringSafeArea(.all)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10)
                                        //.stroke(style: StrokeStyle(lineWidth: 5))
                                        .fill(
                                            Color.teal.gradient
                                        )
                                        
                                }
                            
                            
                            Text("\(house.number ?? "")")
                                .font(.title)
                                .fontWeight(.heavy)
                                .foregroundColor(.primary)
                                //.padding(1)
                                .padding(10)
                        }
                        
                    }
                    .vSpacing(.leading)
                    .frame(maxWidth: UIScreen.screenWidth * 0.3)
                    .padding(.trailing)
                    
                    
                    VStack {
                        if house.floor != 0 {
                            Text("Floor: \(house.floor)")
                                .font(.body)
                                .lineLimit(2)
                                .foregroundColor(.primary)
                                .fontWeight(.bold)
                                .hSpacing(.leading)
                        }
                        
                        if let lastVisit {
                            Text("Last Visit: \(formattedDate(date: Date(timeIntervalSince1970: TimeInterval(lastVisit.date))))")
                                .font(.body)
                                .lineLimit(2)
                                .foregroundColor(.primary)
                                .fontWeight(.bold)
                                .hSpacing(.leading)
                            Text("Last Symbol: \(lastVisit.symbol ?? "")")
                                .font(.body)
                                .lineLimit(2)
                                .foregroundColor(.primary)
                                .fontWeight(.bold)
                                .hSpacing(.leading)
                            
                        } else {
                            Text("Last Visit: N/A")
                                .font(.body)
                                .lineLimit(2)
                                .foregroundColor(.primary)
                                .fontWeight(.bold)
                                .hSpacing(.leading)
                            Text("Last Symbol: N/A")
                                .font(.body)
                                .lineLimit(2)
                                .foregroundColor(.primary)
                                .fontWeight(.bold)
                                .hSpacing(.leading)
                        }
                        //lastVisit.date
                    }
                    .hSpacing(.leading)
                     .frame(maxWidth: UIScreen.screenWidth * 0.7)
                }
                
                VStack {
                    if let lastVisit {
                        HStack {
                            Text("Last Note: \(lastVisit.notes ?? "")")
                                .font(.body)
                                .lineLimit(2)
                                .foregroundColor(.primary)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.leading)
                                .hSpacing(.leading)
                        }
                        .padding(.top)
                    } else {
                        HStack {
                            Text("Last Note: N/A")
                                .font(.body)
                                .lineLimit(2)
                                .foregroundColor(.primary)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.leading)
                                .hSpacing(.leading)
                        }
                        .padding(.top)
                    }
                }
                
            }
            .frame(maxWidth: .infinity)
            
        }
        .id(house.id)
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
        .onAppear {
            //visits.nsPredicate = NSPredicate(format: "territoryAddress == %@", argumentArray: [house.number ?? 0])
        }
    }
}

#Preview {
    HousesView(territory: DataController.preview.getTerritories().first!)
}
