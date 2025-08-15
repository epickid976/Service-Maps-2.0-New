//
//  AddVisitView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/25/23.
//

import SwiftUI

//MARK: - AddVisitView

struct AddVisitView: View {
    
    //MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    //MARK: - Properties
    
    var visit: Visit?
    
    //MARK: - Dependencies
    
    @StateObject var viewModel: AddVisitViewModel
    @State var title = ""
    
    //MARK: - Closures
    
    var onDone: () -> Void
    var onDismiss: () -> Void
    
    //MARK: - Focus State
    
    @FocusState var notesFocus: Bool
    @State var showOptions = false
    
    //MARK: - Initializer
    
    init(visit: Visit?, house: House, onDone: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        let initialViewModel = AddVisitViewModel(house: house)
        _viewModel = StateObject(wrappedValue: initialViewModel)
        if let visit = visit {
            self.visit = visit
        }
        
        self.onDone = onDone
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text("\(title) Visit")
                        .font(.title3)
                        .fontWeight(.heavy)
                        .hSpacing(.center)
                    
                    
                }
                
                CustomPickerView(viewModel: viewModel, showOptions: $showOptions, text: $viewModel.notes)
                    .padding(.bottom, !showOptions ? 0 : 16)
                    .padding(.bottom, viewModel.error != "" ? 30 : 0)
                
                if !showOptions {
                    CustomField(text: $viewModel.notes, isFocused: $notesFocus, textfield: true, keyboardContentType: .oneTimeCode, textfieldAxis: .vertical, expanded: true, placeholder: NSLocalizedString("Notes", comment: ""))
                        .padding(.bottom)

                    // Oval button to re-add last visit details
                    Button(action: {
                        HapticManager.shared.trigger(.lightImpact)
                        Task {
                            await viewModel.fillWithLastVisit()
                        }
                    }) {
                        HStack {
                            Image(systemName: "sparkles") // or any AI-themed SF Symbol
                                .font(.system(size: 16, weight: .medium))
                            Text(NSLocalizedString("Same as Last Visit", comment: ""))
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
                            if visit != nil {
                                notesFocus = false
                                Task {
                                    withAnimation {
                                        viewModel.loading = true
                                    }
                                    let result = await viewModel.editVisit(visit: visit!)
                                    await MainActor.run {
                                        switch result {
                                        case .success(_):
                                            HapticManager.shared.trigger(.success)
                                            onDone()
                                        case .failure(let error):
                                            HapticManager.shared.trigger(.error)
                                            viewModel.error = viewModel.getErrorMessage(for: error)
                                            viewModel.loading = false
                                        }
                                    }
                                }
                            } else {
                                Task {
                                    withAnimation {
                                        viewModel.loading = true
                                    }
                                    let result = await viewModel.addVisit()
                                    await MainActor.run {
                                        switch result {
                                        case .success(_):
                                            HapticManager.shared.trigger(.success)
                                            onDone()
                                        case .failure(let error):
                                            HapticManager.shared.trigger(.error)
                                            viewModel.error = viewModel.getErrorMessage(for: error)
                                            viewModel.loading = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding([.horizontal, .bottom])
                
            }
            .ignoresSafeArea(.keyboard)
            .navigationBarTitle("\(title) Visit", displayMode: .large)
            .navigationBarBackButtonHidden()
            
        }.ignoresSafeArea(.keyboard)
            .onAppear {
                if visit != nil {
                    //withAnimation {
                    title = NSLocalizedString("Edit", comment: "")
                    self.viewModel.notes = visit!.notes                    //}
                    self.viewModel.selectedOption = Symbols(rawValue: visit!.symbol.uppercased()) ?? .none
                } else {
                    //withAnimation {
                    title = NSLocalizedString("Add", comment: "")
                    //}
                }
            }
    }
    
}


struct CustomPickerView: View {
    @ObservedObject var viewModel: AddVisitViewModel
    @Binding var showOptions: Bool
    @Binding var text: String
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {
            HStack {
                Text("\(text.count)/255")
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                    .fontWeight(.heavy)
                    .padding(.leading, 10)
                Spacer()
                Text("Symbol: ")
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                    .fontWeight(.heavy)
                Button(action: {
                    withAnimation {
                        showOptions.toggle()
                    }
                }) {
                    HStack {
                        Text(NSLocalizedString(viewModel.selectedOption.rawValue, comment: ""))
                            .foregroundColor(.primary)
                            .padding(10)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.2))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.trailing, 16)
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            if showOptions {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Symbols.allCases, id: \.self) { option in
                        Button(action: {
                            viewModel.selectedOption = option
                            withAnimation {
                                showOptions = false
                            }
                        }) {
                            HStack {
                                Text("**\(option.rawValue == "-" ? "" : NSLocalizedString(option.rawValue, comment: ""))** - \(option.legend)")
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .font(.body)
                                    .frame(alignment: .leading)
                                //.fontWeight(.bold)
                                
                            }.hSpacing(.center).animation(.spring(), value: viewModel.selectedOption == option)
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 50) // Ensure same height
                                .background(
                                    RoundedRectangle(cornerRadius: 40)
                                        .fill(Color.gray.opacity( viewModel.selectedOption == option ? 0.2 : 0.1))
                                    
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 40)
                                        .stroke(viewModel.selectedOption == option ? Color.white : Color.clear, lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.leading, 16)
                
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
