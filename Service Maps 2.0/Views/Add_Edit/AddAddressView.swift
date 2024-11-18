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
    
    init(territory: Territory, address: TerritoryAddress?, onDone: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: AddAddressViewModel(territory: territory))
        if let address = address {
            self.address = address
        }
        
        self.onDone = onDone
        self.onDismiss = onDismiss
    }
    
    var address: TerritoryAddress?
    
    @State var title = ""
    
    var body: some View {
        ZStack {
            VStack {
                Text("\(title) Address")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .hSpacing(.center)
                CustomField(text: $viewModel.addressText, isFocused: $addressTextFocus, textfield: true, keyboardContentType: .oneTimeCode, textfieldAxis: .vertical, placeholder: NSLocalizedString("Address", comment: ""))
                    .padding(.bottom)
                
                Text(viewModel.error)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                //.vSpacing(.bottom)
                
                HStack {
                    if !viewModel.loading {
                        CustomBackButton() { onDismiss(); HapticManager.shared.trigger(.lightImpact) }//.keyboardShortcut("\r", modifiers: [.command, .shift])
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: viewModel.loading, title: NSLocalizedString("Save", comment: "")) {
                        HapticManager.shared.trigger(.lightImpact)
                        if viewModel.checkInfo() {
                            if address != nil {
                                Task {
                                    withAnimation {
                                        viewModel.loading = true
                                    }
                                    let result = await viewModel.editAddress(address: address!)
                                    switch result {
                                    case .success(_):
                                        HapticManager.shared.trigger(.success)
                                        onDone()
                                    case .failure(_):
                                        HapticManager.shared.trigger(.error)
                                        viewModel.error = NSLocalizedString("Error updating address.", comment: "")
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
                                        HapticManager.shared.trigger(.success)
                                        onDone()
                                    case .failure(_):
                                        HapticManager.shared.trigger(.error)
                                        viewModel.error = NSLocalizedString("Error adding address.", comment: "")
                                        viewModel.loading = false
                                    }
                                }
                            }
                        }
                    }//.keyboardShortcut("\r", modifiers: .command)
                }
                .padding([.horizontal, .bottom])
                //.vSpacing(.bottom)
                
            }
            .ignoresSafeArea(.keyboard)
            .navigationBarTitle("\(title) Address", displayMode: .large)
            .navigationBarBackButtonHidden()
            
        }//.ignoresSafeArea(.keyboard)
            .onAppear {
                if address != nil {
                    //withAnimation {
                    title = NSLocalizedString("Edit", comment: "")
                    self.viewModel.addressText = address!.address
                    //}
                } else {
                    //withAnimation {
                    title = NSLocalizedString("Add", comment: "")
                    //}
                } 
            }
    }
}

