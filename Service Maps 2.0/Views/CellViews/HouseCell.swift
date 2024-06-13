//
//  HouseCell.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/5/23.
//

import SwiftUI
import NukeUI

struct HouseCell: View {
    var house: HouseData
    
    var mainWindowSize: CGSize
      
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.gradient.opacity(0.5))
                            .foregroundStyle(Material.thin)
                        
                        HStack {
                            Text("\(house.house.number)")
                                .font(.title3)
                                .fontWeight(.heavy)
                                .foregroundColor(.primary)
                            
                            //.padding(1)
                        }
                        .padding(10)
                        
                    }
                    .hSpacing(.center)
                    //.vSpacing(.leading)
                    .frame(minWidth: mainWindowSize.width * 0.20, maxHeight: 100)
                    
                    VStack {
                        HStack {
                            if let visit = house.visit {
                                Image(systemName: "tablecells.badge.ellipsis").imageScale(.large)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.primary)
                                Text("Symbol: \(NSLocalizedString(visit.symbol.localizedUppercase, comment: ""))")
                                    .font(.subheadline)
                                    .lineLimit(2)
                                    .foregroundColor(.primary)
                                    .fontWeight(.bold)
                                    .hSpacing(.leading)
                            } else {
                                Image(systemName: "tablecells.badge.ellipsis").imageScale(.large)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.primary)
                                Text("Symbol: -")
                                    .font(.subheadline)
                                    .lineLimit(2)
                                    .foregroundColor(.primary)
                                    .fontWeight(.bold)
                                    .hSpacing(.leading)
                            }
                        }
                        //.padding()
                        
                        HStack {
                            if let visit = house.visit {
                                Image(systemName: "calendar.badge.clock.rtl").imageScale(.large)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.primary)
                                //.hSpacing(.leading)
                                Text("\(formattedDate(date: Date(timeIntervalSince1970: Double(visit.date) / 1000) ))")
                                    .font(.subheadline)
                                    .lineLimit(2)
                                    .foregroundColor(.primary)
                                    .fontWeight(.bold)
                                    .fixedSize(horizontal: false, vertical: true)
                                // .hSpacing(.leading)
                            } else {
                                Image(systemName: "calendar.badge.clock.rtl").imageScale(.large)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.primary)
                                Text("Date: N/A")
                                    .font(.subheadline)
                                    .lineLimit(2)
                                    .foregroundColor(.primary)
                                    .fontWeight(.bold)
                                    .hSpacing(.leading)
                            }
                        }
                        .hSpacing(.leading)
                        //.padding()
                        
                    }
                    //.vSpacing(.leading)
                    .hSpacing(.leading)
                    .frame(maxWidth: mainWindowSize.width * 0.7, maxHeight: 100)
                    //.frame(maxWidth: UIScreen.screenWidth * 0.6)
                }
                Spacer()
                VStack {
                    HStack {
                        if let visit = house.visit  {
                            HStack {
                                Image(systemName: "note.text").imageScale(.large)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.primary)
                                Text("Note: \(visit.notes)")
                                    .font(.headline)
                                    .lineLimit(2)
                                    .foregroundColor(.primary)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .hSpacing(.leading)
                            }
                        } else {
                            HStack {
                                Image(systemName: "note.text").imageScale(.large)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.primary)
                                Text("Note: No notes")
                                    .font(.headline)
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
                .frame(maxWidth: mainWindowSize.width * 0.95, maxHeight: 100)
                
                
            }
            .frame(maxWidth: .infinity)
            
        }
        .padding(10)
        .frame(minWidth: mainWindowSize.width * 0.95)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
