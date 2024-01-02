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
    
    
    private var houses: FetchedResultList<House>
    
    
     init(territory: Territory, context: NSManagedObjectContext = DataController.shared.container.viewContext) {
        self.territory = territory
        
         houses = FetchedResultList(context: context, sortDescriptors: [
            NSSortDescriptor(keyPath: \House.id, ascending: true)
           ])
         
         houses.willChange = { [weak self] in self?.objectWillChange.send() }
         
    }
    
    @Published var backAnimation = false
    @Published var optionsAnimation = false
    @Published var progress: CGFloat = 0.0
    @Published var territory: Territory
    
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    @Published var isAscending = true {
        didSet {
            houses.sortDescriptors = [
                NSSortDescriptor(keyPath: \House.id, ascending: isAscending)
              ]
        }
    } // Boolean state variable to track the sorting order
    @Published var currentHouse: House?
    @Published var presentSheet = false
    
    var sortDescriptors: [NSSortDescriptor] {
        // Compute the sort descriptors based on the current sorting order
        return [NSSortDescriptor(keyPath: \House.number, ascending: isAscending)]
    }
    
    @ViewBuilder
    func largeHeader(progress: CGFloat) -> some View  {
        VStack {
            ZStack {
                    VStack {
                        LazyImage(url: URL(string: "https://assetsnffrgf-a.akamaihd.net/assets/m/502016177/univ/art/502016177_univ_lsr_xl.jpg")) { state in
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
                LazyImage(url: URL(string: "https://assetsnffrgf-a.akamaihd.net/assets/m/502016177/univ/art/502016177_univ_lsr_xl.jpg")) { state in
                    if let image = state.image {
                        image.resizable().aspectRatio(contentMode: .fill).frame(maxWidth: 75, maxHeight: 60)
                    } else if state.error != nil {
                        Color.red
                    } else {
                        ProgressView().progressViewStyle(.circular)
                    }
                }
                .cornerRadius(10)
                .padding(.horizontal, 2)
            }
            Text(territory.territoryDescription ?? "")
                .font(.body)
                .fontWeight(.heavy)
        }
        .frame(maxHeight: 75)
        .animation(.easeInOut(duration: 0.25), value: progress)
        .padding(.horizontal)
        .hSpacing(.center)
    }
    
    @ViewBuilder
    func createFab() -> some View {
            Button(action: {
                self.presentSheet.toggle()
                let newHouse = House(context: DataController.shared.container.viewContext)
                newHouse.id = UUID().uuidString
                newHouse.number = "10\(1)"
                newHouse.territoryAddress = "1850 W 56 St Hialeah FL 33012 United States"
                DataController.shared.save()
            }, label: {
                Image(systemName: "plus")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40, alignment: .center)
            })
            .padding(8)
            .background(Color.blue)
            .cornerRadius(100)
            .padding(8)
            .shadow(radius: 3,
                    x: 3,
                    y: 3)
            .transition(.scale)
        }
    
    func deleteHouse(house: House) {
        DataController.shared.container.viewContext.delete(house)
    }
}

extension HousesViewModel {
    var housesList: [House] {
        houses.items
    }
}


extension House {
    static var all: NSFetchRequest<House> {
        let request = House.fetchRequest ()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \House.number, ascending: true)]
        return request
    }
}
