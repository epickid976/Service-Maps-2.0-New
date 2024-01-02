//
//  AddTerritoryView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/20/23.
//

import SwiftUI
import PhotosUI
import NavigationTransitions

struct AddTerritoryView: View {
    var territory: Territory?
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel = AddTerritoryViewModel()
    
    @State var title = ""
    
    init(territory: Territory?) {
        if let territory = territory {
            self.territory = territory
        }
    }
    
    @FocusState private var numberFocus: Bool
    @FocusState private var descriptionFocus: Bool
    

    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack {
                            VStack {
                                Text("Number")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .hSpacing(.leading)
                                //.frame(alignment: .leading)
                                    //.hSpacing(.center)
                                .padding(.leading)
                                HStack {
                                    CustomField(text: viewModel.binding, isFocused: $numberFocus, textfield: true, keyboardType: .numberPad, textAlignment: .center, placeholder: "#")
                                        .frame(maxWidth: UIScreen.screenWidth * 0.3)
                                    Stepper("", onIncrement: {
                                        if viewModel.number != nil {
                                            viewModel.number! += 1
                                        } else {
                                            viewModel.number = 0
                                        }
                                        
                                    }, onDecrement: {
                                        if viewModel.number != nil {
                                            if viewModel.number != 0 {
                                                viewModel.number! -= 1
                                            }
                                        }
                                    })
                                    .scaleEffect(CGSize(width: 1.5, height: 1.5))
                                    .labelsHidden()
                                    .frame(maxWidth: UIScreen.screenWidth * 0.3)
                                }
                                .hSpacing(.leading)
                            }
                            .padding(.vertical)
                        
                        Text("Description")
                            .font(.headline)
                            .fontWeight(.semibold)
                        // .frame(alignment: .center)
                            .hSpacing(.leading)
                        .padding(.leading)
                    CustomField(text: $viewModel.description, isFocused: $descriptionFocus, textfield: true, textfieldAxis: .vertical, placeholder: "Description")
                            .animation(.spring, value: viewModel.description)
                            .padding(.bottom)
                    
                        Text("Image")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .hSpacing(.center)
                        VStack {
                            ImagePickerView(title: "Drag & Drop", subTitle: "Tap to add an image", systemImage: "square.and.arrow.up", tint: .blue, previewImage: $viewModel.previewImage) { image in
                                viewModel.imageToSend = image
                            }
                            .optionalViewModifier { content in
                                    content
                                        .overlay(
                                            Button {
                                                DispatchQueue.main.async {
                                                    viewModel.imageToSend = nil
                                                    viewModel.previewImage = nil
                                                    content.previewImage = nil
                                                }
                                            } label: {
                                                if viewModel.imageToSend != nil {
                                                    Image(systemName: "xmark")
                                                        .foregroundColor(.red)
                                                        .padding(8)
                                                        .background(Color.white)
                                                        .clipShape(Circle())
                                                }
                                            }
                                            .offset(x: 10, y: -10),
                                            alignment: .topTrailing
                                            )
                            }
                            
                        }
                        .frame(minWidth: 250, maxWidth: 300, minHeight: 10, maxHeight: 300)
                        
                    
                    HStack {
                        CustomBackButton() { dismiss() }
                        //.padding([.top])
                        
                        CustomButton(loading: false, title: "Save") {
                            viewModel.addTerritory()
                        }
                    }
                    .padding([.horizontal, .bottom])
                    .vSpacing(.bottom)
                    
                }
                .ignoresSafeArea(.keyboard)
                .navigationBarTitle("\(title) Territory", displayMode: .large)
                .navigationBarBackButtonHidden()
                .toolbar{
                    ToolbarItemGroup(placement: .keyboard){
                        Spacer()
                        Button {
                            DispatchQueue.main.async {
                                hideKeyboard()
                            }
                        } label: {
                            Text("Done")
                                .tint(.primary)
                                .fontWeight(.bold)
                                .font(.body)
                        }
                    }
                }
            }
            .navigationTransition(
                .zoom.combined(with: .fade(.out))
            )
            
        }.ignoresSafeArea(.keyboard)
            .onAppear {
                if territory != nil {
                    withAnimation {
                        title = "Edit"
                        
                    }
                    self.viewModel.description = territory!.territoryDescription ?? ""
                    self.viewModel.number = Int(territory!.number)
                    self.viewModel.previewImage = UIImage(named: "testTerritoryImage")
                } else {
                    withAnimation {
                        title = "Add"
                    }
                }
                
                
            }
        
    }
}

#Preview {
    AddTerritoryView(territory: DataController.preview.getTerritories().first!)
}
