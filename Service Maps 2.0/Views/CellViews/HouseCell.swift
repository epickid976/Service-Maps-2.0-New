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
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.gradient)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    //.stroke(style: StrokeStyle(lineWidth: 5))
                                    .fill(
                                        Material.thin
                                    )
                                    .frame(maxWidth: house.floor != 0 ? UIScreen.screenWidth * 0.30 : UIScreen.screenWidth * 0.5)
                                )
                            
                            HStack {
                                Image(systemName: "numbersign").imageScale(.large).fontWeight(.heavy)
                                    .foregroundColor(.primary)
                                Text("\(house.number ?? "")")
                                    .font(.title)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.primary)
                                
                                //.padding(1)
                            }
                            .padding()
                        }
                        .hSpacing(.center)
                        .vSpacing(.leading)
                        .frame(maxWidth: house.floor != 0 ? UIScreen.screenWidth * 0.30 : UIScreen.screenWidth * 0.5)
                    
                    if house.floor != 0 {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.gradient)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    //.stroke(style: StrokeStyle(lineWidth: 5))
                                    .fill(
                                        Material.thin
                                    )
                                    .frame(maxWidth: house.floor != 0 ? UIScreen.screenWidth * 0.30 : UIScreen.screenWidth * 0.5)
                                )
                                
                            HStack {
                                Image(systemName: "building").imageScale(.large)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.primary)
                                Text("\(house.floor)")
                                    .font(.title)
                                    .lineLimit(2)
                                    .foregroundColor(.primary)
                                    .fontWeight(.heavy)
                            }
                            .padding()
                            
                        }
                        .vSpacing(.leading)
                        .hSpacing(.center)
                        .frame(maxWidth: UIScreen.screenWidth * 0.3)
                    }
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.gradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                //.stroke(style: StrokeStyle(lineWidth: 5))
                                .fill(
                                    Material.thin
                                )
                                .frame(maxWidth: house.floor != 0 ? UIScreen.screenWidth * 0.30 : UIScreen.screenWidth * 0.5)
                            )
                        
                        HStack {
                            if let lastVisit {
                                Image(systemName: "tablecells.badge.ellipsis").imageScale(.large)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.primary)
                                Text("\(lastVisit.symbol ?? "")")
                                    .font(.title)
                                    .lineLimit(2)
                                    .foregroundColor(.primary)
                                    .fontWeight(.heavy)
                            } else {
                                Image(systemName: "tablecells.badge.ellipsis").imageScale(.large)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.primary)
                                Text("N/A")
                                    .font(.title)
                                    .lineLimit(2)
                                    .foregroundColor(.primary)
                                    .fontWeight(.heavy)
                            }
                        }
                        .padding()
                        
                    }
                    .hSpacing(.center)
                    .vSpacing(.leading)
                    .frame(maxWidth: house.floor != 0 ? UIScreen.screenWidth * 0.30 : UIScreen.screenWidth * 0.5)
                }
                
                VStack {
                    HStack {
                        if let lastVisit {
                            Image(systemName: "calendar.badge.clock.rtl").imageScale(.large)
                                .fontWeight(.heavy)
                                .foregroundColor(.primary)
                            Text("\(formattedDate(date: Date(timeIntervalSince1970: TimeInterval(lastVisit.date))))")
                                .font(.title3)
                                .lineLimit(2)
                                .foregroundColor(.primary)
                                .fontWeight(.bold)
                                .hSpacing(.leading)
                        } else {
                            Image(systemName: "calendar.badge.clock.rtl").imageScale(.large)
                                .fontWeight(.heavy)
                                .foregroundColor(.primary)
                            Text("N/A")
                                .font(.title3)
                                .lineLimit(2)
                                .foregroundColor(.primary)
                                .fontWeight(.bold)
                                .hSpacing(.leading)
                        }
                    }
                    .padding([.top, .horizontal])
                    
                    HStack {
                        if let lastVisit {
                            HStack {
                                Image(systemName: "note.text").imageScale(.large)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.primary)
                                Text("\(lastVisit.notes ?? "")")
                                    .font(.title3)
                                    .lineLimit(2)
                                    .foregroundColor(.primary)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.leading)
                                    .hSpacing(.leading)
                            }
                        } else {
                            HStack {
                                Image(systemName: "note.text").imageScale(.large)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.primary)
                                Text("N/A")
                                    .font(.title3)
                                    .lineLimit(2)
                                    .foregroundColor(.primary)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.leading)
                                    .hSpacing(.leading)
                            }
                            
                        }
                    }
                    .padding([.bottom, .horizontal])
                    .padding(.top, 5)
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
    }
}

#Preview {
    HousesView(territory: DataController.preview.getTerritories().first!)
}
