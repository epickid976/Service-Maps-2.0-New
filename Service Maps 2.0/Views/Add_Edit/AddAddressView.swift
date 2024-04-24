//
//  AddAddressView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/19/24.
//

import SwiftUI

struct AddAddressView: View {
    var onDone: () -> Void
    var onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: AddAddressViewModel
    
    @FocusState private var addressTextFocus: Bool
    
    init(territory: TerritoryModel, address: TerritoryAddressModel?, onDone: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: AddAddressViewModel(territory: territory))
        if let address = address {
            self.address = address
        }
        
        self.onDone = onDone
        self.onDismiss = onDismiss
    }
    
    var address: TerritoryAddressModel?
    
    @State var title = ""
    
    var body: some View {
        ZStack {
                VStack {
                        Text("\(title) Address")
                        .font(.title)
                            .fontWeight(.bold)
                            .hSpacing(.leading)
                        .padding(.leading)
                    CustomField(text: $viewModel.addressText, isFocused: $addressTextFocus, textfield: true, textfieldAxis: .vertical, placeholder: "Address")
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
                                if address != nil {
                                    Task {
                                        withAnimation {
                                            viewModel.loading = true
                                        }
                                        let result = await viewModel.editAddress(address: address!)
                                        switch result {
                                        case .success(_):
                                            onDone()
                                        case .failure(_):
                                            viewModel.error = "Error updating address."
                                            viewModel.loading = false
                                        }
                                    }
                                } else {
                                    Task {
                                        withAnimation {
                                            viewModel.loading = true
                                        }
                                        let result = await viewModel.addAddress()
                                        switch result {
                                        case .success(_):
                                            onDone()
                                        case .failure(_):
                                            viewModel.error = "Error adding address."
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
                .navigationBarTitle("\(title) Address", displayMode: .large)
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
                if address != nil {
                    //withAnimation {
                        title = "Edit"
                        self.viewModel.addressText = address!.address
                    //}
                } else {
                    //withAnimation {
                        title = "Add"
                    //}
                } 
            }
    }
}

