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
    
    @State var mainWindowSize: CGSize
    
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
                .frame(width: mainWindowSize.width * 0.20, height: 70, alignment: .center)
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
                    .foregroundColor(.secondary)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: mainWindowSize.width * 0.8, alignment: .leading)
            //Image("testTerritoryImage")
            
            
        }
        //.id(territory.id)
        .padding(5)
        .frame(minWidth: mainWindowSize.width * width)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
}

struct PhoneTerritoryCellView: View {
    var territory: PhoneTerritoryModel
    var numbers: Int
    var width: Double = 0.95
    
    @State var mainWindowSize: CGSize
    
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
                .frame(width: mainWindowSize.width * 0.20, height: 70, alignment: .center)
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
                    .foregroundColor(.secondary)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: mainWindowSize.width * 0.8, alignment: .leading)
            //Image("testTerritoryImage")
            
            
        }
        //.id(territory.id)
        .padding(5)
        .frame(minWidth: mainWindowSize.width * width)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
}

enum screenRatio {
    case halfnhalf, thirdOrFourth
}

struct recentCell: View {
    var territory: TerritoryModel
    
    @State var mainWindowSize: CGSize
    
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
                    Text("\(territory.number)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                }
                .frame(minWidth: mainWindowSize.width * 0.20)
            }
            .hSpacing(.leading)
            .frame(width: mainWindowSize.width * 0.20, height: 70, alignment: .center)
            
        }
    }
}
