//
//  AddTerritoryView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/20/23.
//

import SwiftUI
import PhotosUI

struct AddTerritoryView: View {
    var territory: Territory?
    
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: AddTerritoryViewModel
    
    @State var title = "Add"
    init(territory: Territory?) {
        let initialViewModel = AddTerritoryViewModel()
        _viewModel = StateObject(wrappedValue: initialViewModel)
        if let territory {
            self.viewModel.description = territory.territoryDescription ?? ""
            self.viewModel.number = String(territory.number)
            self.viewModel.previewImage = "testTerritoryImage"
        }
    }
    
    @FocusState private var numberFocus: Bool
    @FocusState private var descriptionFocus: Bool
    

    
    var body: some View {
        NavigationStack {
            VStack {
//                Text("This territory will be added to the current congregation.")
//                    .font(.headline)
//                    .fontWeight(.bold)
//                    .hSpacing(.leading)
//                    .multilineTextAlignment(.leading)
//                    .padding(.horizontal)
//                
//                Divider().padding([.horizontal, .bottom])
                
                HStack {
                    VStack {
                        Text("Number")
                            .font(.headline)
                            .fontWeight(.semibold)
                        //.frame(alignment: .leading)
                            .hSpacing(.center)
                            //.padding(.leading)
                        CustomField(text: $viewModel.number, isFocused: $numberFocus, textfield: true, keyboardType: .numberPad, textAlignment: .center, placeholder: "#")
                        
                    }
                    .padding(.trailing, -10)
                    
                    .frame(maxWidth: UIScreen.screenWidth * 0.25)
                    
                    VStack {
                        Text("Description")
                            .font(.headline)
                            .fontWeight(.semibold)
                        // .frame(alignment: .center)
                            .hSpacing(.center)
                            //.padding(.leading)
                        CustomField(text: $viewModel.description, isFocused: $descriptionFocus, textfield: true, textfieldAxis: .vertical, placeholder: "Description")
                            .animation(.spring, value: viewModel.description)
                    }
                    .padding(.leading, -10)
                    .frame(maxWidth: UIScreen.screenWidth * 0.75)
                    
                }
                .padding(.bottom)
                .padding(.top, 10)
                
                Text("Image")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .hSpacing(.center)
                VStack {
                    ImagePickerView(title: "Drag & Drop", subTitle: "Tap to add an image", systemImage: "square.and.arrow.up", tint: .blue, previewImage: UIImage(named: viewModel.previewImage!)) { image in
                        
                    }
                }
                .frame(minWidth: 150, maxWidth: 300, minHeight: 150, maxHeight: 300)
                
                VStack {
                    HStack {
                            CustomBackButton() { dismiss() }
                            //.padding([.top])
                        
                        CustomButton(loading: false, title: "Save") {
                            
                        }
                    }
                    .padding()
                }.vSpacing(.bottom)
                
            }
            .navigationBarTitle("\(title) Territory", displayMode: .large)
            .ignoresSafeArea(.keyboard)
            
        }
        
        
        
    }
}

//#Preview {
//    AddTerritoryView()
//}
