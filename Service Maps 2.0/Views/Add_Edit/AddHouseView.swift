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
    var house: HouseModel?
    
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: AddHouseViewModel
    
    @FocusState private var numberFocus: Bool
    @State var title = ""
    
    init(house: HouseModel?, address: TerritoryAddressModel, onDone: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: AddHouseViewModel(address: address))
        if let house = house {
            self.house = house
        }
        
        self.onDone = onDone
        self.onDismiss = onDismiss
    }
    
    var onDone: () -> Void
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            VStack {
                Text("\(title) House")
                    .font(.title3)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                    .padding(.leading)
                CustomField(text: $viewModel.number, isFocused: $numberFocus, textfield: true, textfieldAxis: .vertical, placeholder: "Number")
                    .padding(.bottom)
                
                Text(viewModel.error)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                //.vSpacing(.bottom)
                
                HStack {
                    if !viewModel.loading {
                        CustomBackButton() { onDismiss() }
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: viewModel.loading, title: "Save") {
                        if viewModel.checkInfo() {
                            if house != nil {
                                Task {
                                    withAnimation {
                                        viewModel.loading = true
                                    }
                                    let result = await viewModel.editHouse(house: house!)
                                    switch result {
                                    case .success(_):
                                        onDone()
                                    case .failure(_):
                                        viewModel.error = "Error updating house."
                                        viewModel.loading = false
                                    }
                                }
                            } else {
                                Task {
                                    withAnimation {
                                        viewModel.loading = true
                                    }
                                    let result = await viewModel.addHouse()
                                    switch result {
                                    case .success(_):
                                        onDone()
                                    case .failure(_):
                                        viewModel.error = "Error adding house."
                                        viewModel.loading = false
                                    }
                                }
                            }
                        }
                    }
                }
                .padding([.horizontal, .bottom])
                //.vSpacing(.bottom)
                
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
            
        }.ignoresSafeArea(.keyboard)
            .onAppear {
                if house != nil {
                    //withAnimation {
                    title = "Edit"
                    self.viewModel.number = house!.number
                    //}
                } else {
                    //withAnimation {
                    title = "Add"
                    //}
                }
            }
        
    }
}

//#Preview {
//    AddHouseView(house: nil)
//}
