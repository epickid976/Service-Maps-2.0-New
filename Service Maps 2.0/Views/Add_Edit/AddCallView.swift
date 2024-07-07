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
                        .fontWeight(.heavy)
                        .hSpacing(.center)
                }
                CustomField(text: $viewModel.notes, isFocused: $notesFocus, textfield: true, keyboardContentType: .oneTimeCode, textfieldAxis: .vertical, placeholder: NSLocalizedString("Notes", comment: ""))
                    .padding(.bottom)
                
                Text(viewModel.error)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                //.vSpacing(.bottom)
                
                HStack {
                    if !viewModel.loading {
                        CustomBackButton() { onDismiss();HapticManager.shared.trigger(.lightImpact) }//.keyboardShortcut("\r", modifiers: [.command, .shift])
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: viewModel.loading, title: NSLocalizedString("Save", comment: "")) {
                        HapticManager.shared.trigger(.lightImpact)
                        if viewModel.checkInfo() {
                            if call != nil {
                                Task {
                                    withAnimation {
                                        viewModel.loading = true
                                    }
                                    let result = await viewModel.editCall(call: call!)
                                    switch result {
                                    case .success(_):
                                        HapticManager.shared.trigger(.success)
                                        onDone()
                                    case .failure(_):
                                        HapticManager.shared.trigger(.error)
                                        viewModel.error = NSLocalizedString("Error updating call.", comment: "")
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
                                        HapticManager.shared.trigger(.success)
                                        onDone()
                                    case .failure(_):
                                        HapticManager.shared.trigger(.error)
                                        viewModel.error = NSLocalizedString("Error adding call.", comment: "")
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
            .navigationBarTitle("\(title) Call", displayMode: .large)
            .navigationBarBackButtonHidden()
            .toolbar{
                ToolbarItemGroup(placement: .keyboard){
                    Spacer()
                    Button {
                        HapticManager.shared.trigger(.lightImpact)
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
                    title = NSLocalizedString("Edit", comment: "")
                    self.viewModel.notes = call!.notes
                } else {
                    //withAnimation {
                    title = NSLocalizedString("Add", comment: "")
                    //}
                }
            }
    }
}
