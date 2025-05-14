//
//  AddCallView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 5/1/24.
//

import SwiftUI

//MARK: - Add Call View

struct AddCallView: View {
    
    //MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    //MARK: - Dependencies
    
    @StateObject var viewModel: AddCallViewModel
    
    //MARK: - Properties
    
    @State var title = ""
    var call: PhoneCall?
    @FocusState var notesFocus: Bool
    
    //MARK: - Init
    
    init(call: PhoneCall?, phoneNumber: PhoneNumber, onDone: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        let initialViewModel = AddCallViewModel(phoneNumber: phoneNumber)
        _viewModel = StateObject(wrappedValue: initialViewModel)
        if let call = call {
            self.call = call
        }
        
        self.onDone = onDone
        self.onDismiss = onDismiss
    }
    
    //MARK: - Closures
    
    var onDone: () -> Void
    var onDismiss: () -> Void
    
    //MARK: - Body
    
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

                // Oval button to re-add last visit details
                Button(action: {
                    HapticManager.shared.trigger(.lightImpact)
                    Task {
                        await viewModel.fillWithLastCall()
                    }
                }) {
                    HStack {
                        Image(systemName: "sparkles") // or any AI-themed SF Symbol
                            .font(.system(size: 16, weight: .medium))
                        Text(NSLocalizedString("Same as Last Call", comment: ""))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Capsule().fill(Color.blue.opacity(0.2)))
                    .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, 16)

                if viewModel.error != "" {
                    Text(viewModel.error)
                        .padding(.top, 5)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                
                HStack {
                    if !viewModel.loading {
                        CustomBackButton() {
                            onDismiss()
                            HapticManager.shared.trigger(.lightImpact)
                        }
                    }
                    
                    CustomButton(loading: viewModel.loading, title: NSLocalizedString("Save", comment: "")) {
                        HapticManager.shared.trigger(.lightImpact)
                        if viewModel.checkInfo() {
                            if call != nil {
                                Task {
                                    await MainActor.run {
                                        withAnimation {
                                            viewModel.loading = true
                                        }
                                    }
                                    let result = await viewModel.editCall(call: call!)
                                    switch result {
                                    case .success(_):
                                        HapticManager.shared.trigger(.success)
                                        DispatchQueue.main.async {
                                            onDone()
                                        }
                                    case .failure(_):
                                        HapticManager.shared.trigger(.error)
                                        viewModel.error = NSLocalizedString("Error updating call.", comment: "")
                                        viewModel.loading = false
                                    }
                                }
                            } else {
                                Task {
                                    await MainActor.run {
                                        withAnimation {
                                            viewModel.loading = true
                                        }
                                    }
                                    let result = await viewModel.addCall()
                                    switch result {
                                    case .success(_):
                                        HapticManager.shared.trigger(.success)
                                        DispatchQueue.main.async {
                                            onDone()
                                        }
                                    case .failure(_):
                                        HapticManager.shared.trigger(.error)
                                        viewModel.error = NSLocalizedString("Error adding call.", comment: "")
                                        viewModel.loading = false
                                    }
                                }
                            }
                        }
                    }
                }
                .padding([.horizontal, .bottom])
                
            }
            .ignoresSafeArea(.keyboard)
            .navigationBarTitle("\(title) Call", displayMode: .large)
            .navigationBarBackButtonHidden()
            
        }.ignoresSafeArea(.keyboard)
            .onAppear {
                if call != nil {
                    title = NSLocalizedString("Edit", comment: "")
                    self.viewModel.notes = call!.notes
                } else {
                    title = NSLocalizedString("Add", comment: "")
                }
            }
    }
}
