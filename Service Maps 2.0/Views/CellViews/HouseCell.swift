//
//  HouseCell.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/5/23.
//

import SwiftUI
import NukeUI

struct HouseCell: View {
    var house: HouseModel
    var lastVisit: VisitModel? = nil
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.gradient)
                                .foregroundStyle(Material.thin)

                            HStack {
                                Image(systemName: "numbersign").imageScale(.large).fontWeight(.heavy)
                                    .foregroundColor(.primary)
                                Text("\(house.number ?? "")")
                                    .font(.title)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.primary)
                                
                                //.padding(1)
                            }
                            .padding(10)
                            
                        }
                        .hSpacing(.center)
                        //.vSpacing(.leading)
                        .frame(maxWidth: UIScreen.screenWidth * 0.4, maxHeight: 200)
                    
                    VStack {
                        HStack {
                            if let lastVisit {
                                Image(systemName: "tablecells.badge.ellipsis").imageScale(.large)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.primary)
                                Text("Symbol: \(lastVisit.symbol ?? "")")
                                    .font(.title3)
                                    .lineLimit(2)
                                    .foregroundColor(.primary)
                                    .fontWeight(.heavy)
                                    .hSpacing(.leading)
                            } else {
                                Image(systemName: "tablecells.badge.ellipsis").imageScale(.large)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.primary)
                                Text("Symbol: N/A")
                                    .font(.title3)
                                    .lineLimit(2)
                                    .foregroundColor(.primary)
                                    .fontWeight(.heavy)
                                    .hSpacing(.leading)
                            }
                        }
                        //.padding()
                        
                        HStack {
                            if let lastVisit {
                                Image(systemName: "calendar.badge.clock.rtl").imageScale(.large)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.primary)
                                Text("Date: \(formattedDate(date: Date(timeIntervalSince1970: TimeInterval(lastVisit.date))))")
                                    .font(.title3)
                                    .lineLimit(2)
                                    .foregroundColor(.primary)
                                    .fontWeight(.heavy)
                                    .hSpacing(.leading)
                            } else {
                                Image(systemName: "calendar.badge.clock.rtl").imageScale(.large)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.primary)
                                Text("Date: N/A")
                                    .font(.title3)
                                    .lineLimit(2)
                                    .foregroundColor(.primary)
                                    .fontWeight(.heavy)
                                    .hSpacing(.leading)
                            }
                        }
                        //.padding()
                       
                    }
                    //.vSpacing(.leading)
                    .hSpacing(.leading)
                    //.frame(maxWidth: UIScreen.screenWidth * 0.6)
                }
                
                VStack {
                    HStack {
                        if let lastVisit {
                            HStack {
                                Image(systemName: "note.text").imageScale(.large)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.primary)
                                Text("Note: \(lastVisit.notes ?? "")")
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
                                Text("Note: N/A")
                                    .font(.title3)
                                    .lineLimit(2)
                                    .foregroundColor(.primary)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.leading)
                                    .hSpacing(.leading)
                            }
                        }
                    }
                    .padding([.bottom, .horizontal], 3)
                    .padding(.top, 5)
                }
                
                
            }
            .frame(maxWidth: .infinity)
            
        }
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
