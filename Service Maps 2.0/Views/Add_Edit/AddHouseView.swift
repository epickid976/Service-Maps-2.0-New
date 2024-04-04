//
//  AddHouseView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/28/23.
//


import SwiftUI
import PhotosUI
import NavigationTransitions

struct AddHouseView: View {
    var house: House?
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel = AddHouseViewModel()
    
    @State var title = ""
    
    init(house: House?) {
        if let house = house {
            self.house = house
        }
    }
    
    @FocusState private var numberFocus: Bool
    

    
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
                    
                    HStack {
                        CustomBackButton() { dismiss() }
                        //.padding([.top])
                        
                        CustomButton(loading: false, title: "Save") {
                            if viewModel.number == nil {
                                
                            } else {
                                viewModel.addHouse(number: viewModel.number!)
                            }
                        }
                    }
                    .padding([.horizontal, .bottom])
                    .vSpacing(.bottom)
                    
                }
                .ignoresSafeArea(.keyboard)
                .navigationBarTitle("\(title) House", displayMode: .large)
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
                if house != nil {
                    withAnimation {
                        title = "Edit"
                        
                    }
                    self.viewModel.number = Int(house!.number ?? "0")
                } else {
                    withAnimation {
                        title = "Add"
                    }
                }
                
                
            }
        
    }
}

#Preview {
    AddHouseView(house: nil)
}
