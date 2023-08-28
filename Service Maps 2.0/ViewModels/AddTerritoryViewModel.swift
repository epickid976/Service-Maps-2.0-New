//
//  AddTerritoryViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/20/23.
//

import Foundation
import SwiftUI

class AddTerritoryViewModel: ObservableObject {
    
    @Published var number = ""
    @Published var description = ""
    @Published var previewImage: String? = nil
    @Published var imageToSend: UIImage? = nil
}
