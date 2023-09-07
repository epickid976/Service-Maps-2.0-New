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

@MainActor
class HousesViewModel: NSObject, ObservableObject {
    
    @Published var houses = [House]()
    private let fetchedResultsController: NSFetchedResultsController<House>
    
     init(territory: Territory) {
        self.territory = territory
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: House.all, managedObjectContext: DataController.shared.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        super.init()
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch ()
            guard let houses = fetchedResultsController.fetchedObjects else { return }
            self.houses = houses
        } catch {
            print (error)
        }
    }
    
    @Published var backAnimation = false
    @Published var optionsAnimation = false
    @Published var progress: CGFloat = 0.0
    @Published var territory: Territory
    
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    @Published var isAscending = true {
        didSet {
            fetchedResultsController.fetchRequest.sortDescriptors = sortDescriptors
            do {
                try fetchedResultsController.performFetch ()
                guard let houses = fetchedResultsController.fetchedObjects else { return }
                self.houses = houses
            } catch {
                print (error)
            }
        }
    } // Boolean state variable to track the sorting order
    @Published var currentHouse: House?
    @Published var presentSheet = false
    
    var sortDescriptors: [NSSortDescriptor] {
        // Compute the sort descriptors based on the current sorting order
        return [NSSortDescriptor(keyPath: \House.number, ascending: isAscending)]
    }
    
    func largeHeader(progress: CGFloat) -> some View  {
        VStack {
            if progress < 0.70 {
                LazyImage(url: URL(string: "https://assetsnffrgf-a.akamaihd.net/assets/m/502016177/univ/art/502016177_univ_lsr_xl.jpg")) { state in
                    if let image = state.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                        .frame(maxWidth: UIScreen.screenWidth * 0.5, maxHeight: 350)
                        image.opacity(1 - progress)
                        
                    } else if state.error != nil {
                        Color.red
                    } else {
                        ProgressView().progressViewStyle(.circular)
                    }
                }
                .cornerRadius(10)
                .clipped()
            } else {
                smallHeader
                    .vSpacing(.bottom)
                    .padding(.bottom, 9)
            }
        }
        .animation(.spring, value: progress)
    }
    
    var smallHeader: some View {
        HStack(spacing: 12.0) {
            Text("#\(territory.number)")
                .font(.largeTitle)
                .bold()
            
            Divider()
                .frame(maxHeight: 60)
                .padding(.horizontal, -5)
            if !(progress < 0.7) {
                LazyImage(url: URL(string: "https://assetsnffrgf-a.akamaihd.net/assets/m/502016177/univ/art/502016177_univ_lsr_xl.jpg")) { state in
                    if let image = state.image {
                        image.resizable().aspectRatio(contentMode: .fill).frame(maxWidth: 60, maxHeight: 60)
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
                .fontWeight(.bold)
        }
        .frame(maxHeight: 60)
        .animation(.spring, value: progress)
        .padding(.horizontal)
        .hSpacing(.center)
    }
    
    func deleteHouse(house: House) {
        DataController.shared.container.viewContext.delete(house)
    }
}

extension HousesViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let houses = controller.fetchedObjects as? [House] else { return }
        
        self.houses = houses
    }
}

extension House {
    static var all: NSFetchRequest<House> {
        let request = House.fetchRequest ()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \House.number, ascending: true)]
        return request
    }
}
