//
//  ModelExtensions.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/6/23.
//

import Foundation
import CoreData

extension Territory {
    static var allTerritories: NSFetchRequest<Territory> {
        let request = Territory.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Territory.number, ascending: true)]
        return request
    }
}

extension TerritoryAddress {
    static var allAddresses: NSFetchRequest<TerritoryAddress> {
        let request = TerritoryAddress.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TerritoryAddress.territory, ascending: true)]
        return request
    }
}

extension House {
    static var allHouses: NSFetchRequest<House> {
        let request = House.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \House.number, ascending: true)]
        return request
    }
}

extension Visit {
    static var allVisits: NSFetchRequest<Visit> {
        let request = Visit.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Visit.date, ascending: true)]
        return request
    }
}

