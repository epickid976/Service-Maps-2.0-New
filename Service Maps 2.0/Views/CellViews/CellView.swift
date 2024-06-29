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
    var territory: TerritoryModel
    var houseQuantity: Int
    var width: Double = 0.95
    let isIpad = UIDevice.current.userInterfaceIdiom == .pad
    var mainWindowSize: CGSize
    //@Binding var territoryModel: TerritoryModel
    
    @State private var cellHeight: CGFloat = 0
    
    var ipad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad && mainWindowSize.width > 400
    }
    
    var body: some View {
            HStack(spacing: 10) {
                VStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .teal]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ).opacity(0.6)
                            )
                        
                        VStack {
                            Text("\(territory.number)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                        }
                        .frame(minWidth: mainWindowSize.width * 0.20)
                    }
                    .hSpacing(.leading)
                    .frame(width: mainWindowSize.width * 0.20, height: cellHeight, alignment: .center)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(territory.description )
                        .font(.headline)
                        .lineLimit(5)
                        .foregroundColor(.primary)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                    Text("Doors: \(houseQuantity)")
                        .font(.body)
                        .lineLimit(2)
                        .foregroundColor(.secondaryLabel)
                        .fontWeight(.bold)
                }.padding(10)
                .frame(maxWidth: mainWindowSize.width * 0.8, alignment: .leading)
            }
            .id(territory.id)
            
            .frame(minWidth: isIpad ? (mainWindowSize.width * width ) / 2 : mainWindowSize.width * width)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .optionalViewModifier { content in
                if ipad {
                    content
                        .frame(maxHeight: .infinity)
                } else {
                    content
                }
            }
            .background(GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    self.cellHeight = geometry.size.height
                                    print("Cell height: \(self.cellHeight)")
                                }
                        })
    }
    
}

struct PhoneTerritoryCellView: View {
    var territory: PhoneTerritoryModel
    var numbers: Int
    var width: Double = 0.95
    
    var mainWindowSize: CGSize
    
    @State private var cellHeight: CGFloat = 0
    
    var isIpad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad && mainWindowSize.width > 400
    }
    
    var body: some View {
        HStack(spacing: 10) {
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .teal]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ).opacity(0.6)
                        )
                    
                    VStack {
                        Text("\(territory.number)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                    }
                    .frame(minWidth: mainWindowSize.width * 0.20)
                }
                .hSpacing(.leading)
                .frame(width: mainWindowSize.width * 0.20, height: cellHeight, alignment: .center)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(territory.description )
                    .font(.headline)
                    .lineLimit(5)
                    .foregroundColor(.primary)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                Text("Phone Numbers: \(numbers)")
                    .font(.body)
                    .lineLimit(2)
                    .foregroundColor(.secondaryLabel)
                    .fontWeight(.bold)
            }.padding(10)
            .frame(maxWidth: mainWindowSize.width * 0.8, alignment: .leading)
            //Image("testTerritoryImage")
            
            
        }
        //.id(territory.id)
        //.padding(5)
        .frame(minWidth: mainWindowSize.width * width)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .background(GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                self.cellHeight = geometry.size.height
                                print("Cell height: \(self.cellHeight)")
                            }
                    })
        .optionalViewModifier { content in
            if isIpad {
                content
                    .frame(maxHeight: .infinity)
            } else {
                content
            }
        }
    }
    
}

struct recentCell: View {
    var territoryData: RecentTerritoryData
    
    var mainWindowSize: CGSize
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .teal]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ).opacity(0.6)
                    )
                VStack {
                    Text("\(territoryData.territory.number)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(minWidth: mainWindowSize.width * 0.20)
                
                
            }
            .hSpacing(.leading)
            .frame(width: mainWindowSize.width * 0.20, height: 50, alignment: .center)
            
            Text("\(formattedDate(date: Date(timeIntervalSince1970: TimeInterval(territoryData.lastVisit.date) / 1000), withTime: false))")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondaryLabel)
                .frame(width: mainWindowSize.width * 0.20, alignment: .center)
                .lineLimit(2)
        }
    }
}

struct recentPhoneCell: View {
    var territoryData: RecentPhoneData
    
    var mainWindowSize: CGSize
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .teal]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ).opacity(0.6)
                    )
                VStack {
                    Text("\(territoryData.territory.number)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(minWidth: mainWindowSize.width * 0.20)
                
                
            }
            .hSpacing(.leading)
            .frame(width: mainWindowSize.width * 0.20, height: 50, alignment: .center)
            
            Text("\(formattedDate(date: Date(timeIntervalSince1970: TimeInterval(territoryData.lastCall.date) / 1000), withTime: false))")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondaryLabel)
                .frame(width: mainWindowSize.width * 0.20, alignment: .center)
                .lineLimit(2)
        }
    }
}


