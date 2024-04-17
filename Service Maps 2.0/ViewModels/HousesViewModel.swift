//
//  HousesViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/5/23.
//

import Foundation
import SwiftUI
import CoreData
import NukeUI
import Combine

@MainActor
class HousesViewModel: ObservableObject {
    
    //@ObservedObject var databaseManager = RealmManager.shared
    @Published var houses = [HouseModel]() {
        didSet {
            houses.sort(by: { $0.number < $1.number})
        }
    }

     init(territory: TerritoryModel) {
         self.territory = territory
         
         //houses = databaseManager.housesFlow
    }
    
    @Published var backAnimation = false
    @Published var optionsAnimation = false
    @Published var progress: CGFloat = 0.0
    @Published var territory: TerritoryModel
    
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    @Published var currentHouse: HouseModel?
    @Published var presentSheet = false {
        didSet {
            if presentSheet == false {
                currentHouse = nil
            }
        }
    }
    
    @ViewBuilder
    func largeHeader(progress: CGFloat) -> some View  {
        VStack {
            ZStack {
                    VStack {
                        LazyImage(url: URL(string: territory.image ?? "https://www.google.com/url?sa=i&url=https%3A%2F%2Flottiefiles.com%2Fanimations%2Fno-data-bt8EDsKmcr&psig=AOvVaw2p2xZlutsRFWRoLRsg6LJ2&ust=1712619221457000&source=images&cd=vfe&opi=89978449&ved=0CBEQjRxqFwoTCPjeiPihsYUDFQAAAAAdAAAAABAE")) { state in
                            if let image = state.image {
                                image.resizable().aspectRatio(contentMode: .fill).frame(width: UIScreen.screenWidth, height: 350)
                                
                                //image.opacity(1 - progress)
                                
                            } else if state.error != nil {
                                Color.red
                            } else {
                                ProgressView().progressViewStyle(.circular)
                            }
                        }
                        .vSpacing(.bottom)
                        .cornerRadius(10)
                    }
                    .frame(width: UIScreen.screenSize.width, height: 350, alignment: .center)
                    VStack {
                        smallHeader
                           
                            .padding(.vertical)
                        .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
                        
                    }.frame(height: 85)
                        .background(
                            Material.ultraThickMaterial
                        )
                        .vSpacing(.bottom)
            }
            .frame(width: UIScreen.screenWidth, height: 350)
        }
        
        .animation(.default, value: progress)
    }
    
    @ViewBuilder
    var smallHeader: some View {
        HStack(spacing: 12.0) {
            HStack {
                Image(systemName: "numbersign").imageScale(.large).fontWeight(.heavy)
                    .foregroundColor(.primary).font(.title2)
                Text("\(territory.number)")
                    .font(.largeTitle)
                    .bold()
                    .fontWeight(.heavy)
            }
            
            Divider()
                .frame(maxHeight: 75)
                .padding(.horizontal, -5)
            if !(progress < 0.98) {
                LazyImage(url: URL(string: territory.image ?? "https://www.google.com/url?sa=i&url=https%3A%2F%2Flottiefiles.com%2Fanimations%2Fno-data-bt8EDsKmcr&psig=AOvVaw2p2xZlutsRFWRoLRsg6LJ2&ust=1712619221457000&source=images&cd=vfe&opi=89978449&ved=0CBEQjRxqFwoTCPjeiPihsYUDFQAAAAAdAAAAABAE")) { state in
                    if let image = state.image {
                        image.resizable().aspectRatio(contentMode: .fill).frame(maxWidth: 75, maxHeight: 60)
                    } else if state.error != nil {
                       // print(state.error)
                        Color.red
                    } else {
                        ProgressView().progressViewStyle(.circular)
                    }
                }
                .cornerRadius(10)
                .padding(.horizontal, 2)
            }
            Text(territory.description )
                .font(.body)
                .fontWeight(.heavy)
        }
        .frame(maxHeight: 75)
        .animation(.easeInOut(duration: 0.25), value: progress)
        .padding(.horizontal)
        .hSpacing(.center)
    }
    
    func deleteHouse(house: HouseModel) {
        
    }
}
