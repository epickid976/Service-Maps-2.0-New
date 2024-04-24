//
//  AddTerritoryViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/20/23.
//

import Foundation
import SwiftUI
import Nuke

@MainActor
class AddTerritoryViewModel: ObservableObject {
    
    init() {
        error = ""
    }
    
    @Published var number: Int? = nil
    @Published private var dataUploader = DataUploaderManager()
    
    var binding: Binding<String> {
            .init(get: {
                if let number = self.number {
                    "\(number)"
                } else {
                    ""
                }
            }, set: {
                self.number = Int($0) ?? nil
            })
        }
    
    @Published var description = ""
    @Published var previewImage: UIImage? = nil
    @Published var imageToSend: UIImage? = nil
    @Published var error = ""
    
    @Published var loading = false
    
    func addTerritory() async -> Result<Bool, Error>{
            loading = true
            let territoryObject = TerritoryObject()
            territoryObject.number = Int32(number!)
            territoryObject.territoryDescription = description
            territoryObject.congregation = String(AuthorizationProvider.shared.congregationId ?? 0)
            return await dataUploader.addTerritory(territory: territoryObject, image: previewImage)
    }
    
    func editTerritory(territory: TerritoryModel) async -> Result<Bool, Error> {
        loading = true
        let territoryObject = TerritoryObject()
        territoryObject.id = territory.id
        territoryObject.number = Int32(number!)
        territoryObject.territoryDescription = description
        territoryObject.congregation = String(AuthorizationProvider.shared.congregationId ?? 0)
        return await dataUploader.updateTerritory(territory: territoryObject, image: previewImage)
    }
    
    init(territory: TerritoryModel? = nil) {
        Task {
            if let territory = territory {
                if let imageLink = URL(string: territory.getImageURL()) {
                        let image = try await ImagePipeline.shared.image(for: imageLink)
                        self.previewImage = image
                    }
                
            }
        }
    }
    
    func checkInfo() -> Bool {
        if number == nil || description == "" {
            error = "Number and Description are required."
            return false
        } else {
            return true
        }
    }
    
    
}
