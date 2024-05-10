//
//  AddCallView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 5/1/24.
//

import SwiftUI

struct AddCallView: View {
    @Environment(\.dismiss) private var dismiss
    var call: PhoneCallModel?
    
    @StateObject var viewModel: AddCallViewModel
    @State var title = ""
    
    init(call: PhoneCallModel?, phoneNumber: PhoneNumberModel, onDone: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        let initialViewModel = AddCallViewModel(phoneNumber: phoneNumber)
        _viewModel = StateObject(wrappedValue: initialViewModel)
        if let call = call {
            self.call = call
        }
        
        self.onDone = onDone
        self.onDismiss = onDismiss
    }
    
    var onDone: () -> Void
    var onDismiss: () -> Void
    
    @FocusState var notesFocus: Bool
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text("\(title) Call")
                        .font(.title3)
                        .fontWeight(.bold)
                        .hSpacing(.leading)
                        .padding(.leading)
                }
                CustomField(text: $viewModel.notes, isFocused: $notesFocus, textfield: true, textfieldAxis: .vertical, placeholder: "Notes")
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
                            if call != nil {
                                Task {
                                    withAnimation {
                                        viewModel.loading = true
                                    }
                                    let result = await viewModel.editCall(call: call!)
                                    switch result {
                                    case .success(_):
                                        onDone()
                                    case .failure(_):
                                        viewModel.error = "Error updating call."
                                        viewModel.loading = false
                                    }
                                }
                            } else {
                                Task {
                                    withAnimation {
                                        viewModel.loading = true
                                    }
                                    let result = await viewModel.addCall()
                                    switch result {
                                    case .success(_):
                                        onDone()
                                    case .failure(_):
                                        viewModel.error = "Error adding call."
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
            .navigationBarTitle("\(title) Call", displayMode: .large)
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
                if call != nil {
                    //withAnimation {
                    title = "Edit"
                    self.viewModel.notes = call!.notes  
                } else {
                    //withAnimation {
                    title = "Add"
                    //}
                }
            }
    }
}
